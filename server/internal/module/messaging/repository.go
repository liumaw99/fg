package messaging

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/ent/conversationmember"
	"social-server/internal/ent/message"
)

// Repository handles database operations for messaging.
type Repository struct {
	client *ent.Client
}

// NewRepository creates a new messaging repository.
func NewRepository(client *ent.Client) *Repository {
	return &Repository{client: client}
}

// CreateConversation creates a new conversation.
func (r *Repository) CreateConversation(ctx context.Context, convType, title string) (*ent.Conversation, error) {
	c, err := r.client.Conversation.Create().
		SetType(convType).
		SetTitle(title).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create conversation: %w", err)
	}
	return c, nil
}

// GetConversationByID retrieves a conversation by ID.
func (r *Repository) GetConversationByID(ctx context.Context, id uuid.UUID) (*ent.Conversation, error) {
	c, err := r.client.Conversation.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("conversation not found")
		}
		return nil, fmt.Errorf("get conversation: %w", err)
	}
	return c, nil
}

// AddConversationMember adds a member to a conversation.
func (r *Repository) AddConversationMember(ctx context.Context, conversationID, userID uuid.UUID) (*ent.ConversationMember, error) {
	m, err := r.client.ConversationMember.Create().
		SetConversationID(conversationID).
		SetUserID(userID).
		Save(ctx)
	if err != nil {
		if ent.IsConstraintError(err) {
			return nil, fmt.Errorf("already a member")
		}
		return nil, fmt.Errorf("add member: %w", err)
	}
	return m, nil
}

// GetConversationMember retrieves a conversation membership.
func (r *Repository) GetConversationMember(ctx context.Context, conversationID, userID uuid.UUID) (*ent.ConversationMember, error) {
	m, err := r.client.ConversationMember.Query().
		Where(
			conversationmember.ConversationID(conversationID),
			conversationmember.UserID(userID),
		).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("not a member")
		}
		return nil, fmt.Errorf("get member: %w", err)
	}
	return m, nil
}

// GetConversationBetweenUsers finds an existing direct conversation between two users.
func (r *Repository) GetConversationBetweenUsers(ctx context.Context, userID1, userID2 uuid.UUID) (uuid.UUID, error) {
	// Find conversations where both users are members
	members1, err := r.client.ConversationMember.Query().
		Where(conversationmember.UserID(userID1)).
		All(ctx)
	if err != nil {
		return uuid.Nil, fmt.Errorf("get memberships: %w", err)
	}

	for _, m := range members1 {
		exists, err := r.client.ConversationMember.Query().
			Where(
				conversationmember.ConversationID(m.ConversationID),
				conversationmember.UserID(userID2),
			).
			Exist(ctx)
		if err != nil {
			continue
		}
		if exists {
			// Check it's a direct conversation
			conv, err := r.client.Conversation.Get(ctx, m.ConversationID)
			if err == nil && conv.Type == "direct" {
				return m.ConversationID, nil
			}
		}
	}

	return uuid.Nil, fmt.Errorf("no conversation found")
}

// CreateMessage creates a new message.
func (r *Repository) CreateMessage(ctx context.Context, conversationID, senderID uuid.UUID, content, msgType, clientMessageID string) (*ent.Message, error) {
	builder := r.client.Message.Create().
		SetConversationID(conversationID).
		SetSenderID(senderID).
		SetContent(content).
		SetType(msgType)

	if clientMessageID != "" {
		builder = builder.SetClientMessageID(clientMessageID)
	}

	m, err := builder.Save(ctx)
	if err != nil {
		if ent.IsConstraintError(err) {
			return nil, fmt.Errorf("duplicate message")
		}
		return nil, fmt.Errorf("create message: %w", err)
	}
	return m, nil
}

// GetMessageByClientID retrieves a message by client_message_id.
func (r *Repository) GetMessageByClientID(ctx context.Context, clientMessageID string) (*ent.Message, error) {
	m, err := r.client.Message.Query().
		Where(message.ClientMessageID(clientMessageID)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("message not found")
		}
		return nil, fmt.Errorf("get message: %w", err)
	}
	return m, nil
}

// ListMessages retrieves messages for a conversation with pagination.
func (r *Repository) ListMessages(ctx context.Context, conversationID uuid.UUID, cursor string, limit int) ([]*ent.Message, error) {
	q := r.client.Message.Query().
		Where(message.ConversationID(conversationID)).
		Order(ent.Desc(message.FieldCreatedAt))

	if cursor != "" {
		cursorID, err := uuid.Parse(cursor)
		if err == nil {
			m, err := r.client.Message.Get(ctx, cursorID)
			if err == nil {
				q = q.Where(
					message.Or(
						message.CreatedAtLT(m.CreatedAt),
						message.And(
							message.CreatedAtEQ(m.CreatedAt),
							message.IDLT(cursorID),
						),
					),
				)
			}
		}
	}

	messages, err := q.Limit(limit + 1).All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list messages: %w", err)
	}
	return messages, nil
}

// UpdateConversationLastMessage updates the last message info for a conversation.
func (r *Repository) UpdateConversationLastMessage(ctx context.Context, conversationID, messageID uuid.UUID, messageAt time.Time) error {
	_, err := r.client.Conversation.UpdateOneID(conversationID).
		SetLastMessageID(messageID).
		SetLastMessageAt(messageAt).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("update conversation: %w", err)
	}
	return nil
}

// ListUserConversations retrieves conversations for a user.
func (r *Repository) ListUserConversations(ctx context.Context, userID uuid.UUID, cursor string, limit int) ([]*ent.ConversationMember, error) {
	q := r.client.ConversationMember.Query().
		Where(conversationmember.UserID(userID)).
		Order(ent.Desc(conversationmember.FieldJoinedAt))

	if cursor != "" {
		cursorID, err := uuid.Parse(cursor)
		if err == nil {
			m, err := r.client.ConversationMember.Get(ctx, cursorID)
			if err == nil {
				q = q.Where(
					conversationmember.Or(
						conversationmember.JoinedAtLT(m.JoinedAt),
						conversationmember.And(
							conversationmember.JoinedAtEQ(m.JoinedAt),
							conversationmember.IDLT(cursorID),
						),
					),
				)
			}
		}
	}

	members, err := q.Limit(limit + 1).All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list conversations: %w", err)
	}
	return members, nil
}

// GetConversationMembers retrieves all members of a conversation.
func (r *Repository) GetConversationMembers(ctx context.Context, conversationID uuid.UUID) ([]*ent.ConversationMember, error) {
	members, err := r.client.ConversationMember.Query().
		Where(conversationmember.ConversationID(conversationID)).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("get members: %w", err)
	}
	return members, nil
}

// GetUnreadCount returns unread message count for a user in a conversation.
func (r *Repository) GetUnreadCount(ctx context.Context, conversationID, userID uuid.UUID) (int, error) {
	member, err := r.GetConversationMember(ctx, conversationID, userID)
	if err != nil {
		return 0, err
	}

	count, err := r.client.Message.Query().
		Where(
			message.ConversationID(conversationID),
			message.CreatedAtGT(member.LastReadAt),
			message.SenderIDNEQ(userID),
		).
		Count(ctx)
	if err != nil {
		return 0, fmt.Errorf("count unread: %w", err)
	}
	return count, nil
}

// MarkAsRead updates the last_read_at for a member.
func (r *Repository) MarkAsRead(ctx context.Context, conversationID, userID uuid.UUID) error {
	member, err := r.GetConversationMember(ctx, conversationID, userID)
	if err != nil {
		return err
	}

	_, err = r.client.ConversationMember.UpdateOneID(member.ID).
		SetLastReadAt(time.Now()).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("mark as read: %w", err)
	}
	return nil
}

// CreateOutboxEvent creates an outbox event.
func (r *Repository) CreateOutboxEvent(ctx context.Context, topic, key string, payload map[string]any) error {
	err := r.client.OutboxEvent.Create().
		SetTopic(topic).
		SetKey(key).
		SetPayload(payload).
		SetStatus("pending").
		Exec(ctx)
	if err != nil {
		return fmt.Errorf("create outbox event: %w", err)
	}
	return nil
}
