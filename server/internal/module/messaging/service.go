package messaging

import (
	"context"
	"time"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/pagination"
)

// Service handles messaging business logic.
type Service struct {
	repo *Repository
	log  *logger.Logger
}

// NewService creates a new messaging service.
func NewService(repo *Repository, log *logger.Logger) *Service {
	return &Service{repo: repo, log: log}
}

// CreateOrGetConversation creates a new direct conversation or returns an existing one.
func (s *Service) CreateOrGetConversation(ctx context.Context, userID uuid.UUID, req CreateConversationRequest) (*ConversationResponse, error) {
	participantID, err := uuid.Parse(req.ParticipantID)
	if err != nil {
		return nil, errors.New("invalid_user_id", 400, "invalid participant_id")
	}

	if userID == participantID {
		return nil, errors.New("self_conversation", 400, "cannot create conversation with yourself")
	}

	// Check if participant exists
	if _, err := s.repo.client.User.Get(ctx, participantID); err != nil {
		return nil, errors.ErrNotFound
	}

	// Check for existing conversation
	existingConvID, err := s.repo.GetConversationBetweenUsers(ctx, userID, participantID)
	if err == nil {
		// Return existing conversation
		return s.buildConversationResponse(ctx, existingConvID, userID)
	}

	// Create new conversation in transaction
	tx, err := s.repo.client.Tx(ctx)
	if err != nil {
		s.log.Error("failed to start transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}

	repo := NewRepository(tx.Client())

	conv, err := repo.CreateConversation(ctx, "direct", "")
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to create conversation", logger.Error(err))
		return nil, errors.ErrInternal
	}

	_, err = repo.AddConversationMember(ctx, conv.ID, userID)
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to add member", logger.Error(err))
		return nil, errors.ErrInternal
	}

	_, err = repo.AddConversationMember(ctx, conv.ID, participantID)
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to add participant", logger.Error(err))
		return nil, errors.ErrInternal
	}

	if err := tx.Commit(); err != nil {
		s.log.Error("failed to commit transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}

	s.log.Info("conversation created",
		logger.String("conversation_id", conv.ID.String()),
		logger.String("user1", userID.String()),
		logger.String("user2", participantID.String()),
	)

	return s.buildConversationResponse(ctx, conv.ID, userID)
}

// SendMessage sends a message in a conversation.
func (s *Service) SendMessage(ctx context.Context, senderID uuid.UUID, req SendMessageRequest) (*MessageResponse, error) {
	conversationID, err := uuid.Parse(req.ConversationID)
	if err != nil {
		return nil, errors.New("invalid_conversation_id", 400, "invalid conversation_id")
	}

	// Verify user is a member
	if _, err := s.repo.GetConversationMember(ctx, conversationID, senderID); err != nil {
		return nil, errors.New("forbidden", 403, "not a member of this conversation")
	}

	// Check for duplicate client_message_id
	if req.ClientMessageID != "" {
		existing, err := s.repo.GetMessageByClientID(ctx, req.ClientMessageID)
		if err == nil {
			return s.buildMessageResponse(existing), nil
		}
	}

	// Create message in transaction
	tx, err := s.repo.client.Tx(ctx)
	if err != nil {
		s.log.Error("failed to start transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}

	repo := NewRepository(tx.Client())

	msg, err := repo.CreateMessage(ctx, conversationID, senderID, req.Content, "text", req.ClientMessageID)
	if err != nil {
		_ = tx.Rollback()
		if isDuplicate(err) {
			return nil, errors.New("duplicate_message", 409, "message already exists")
		}
		s.log.Error("failed to create message", logger.Error(err))
		return nil, errors.ErrInternal
	}

	// Update conversation last message
	if err := repo.UpdateConversationLastMessage(ctx, conversationID, msg.ID, msg.CreatedAt); err != nil {
		s.log.Error("failed to update conversation", logger.Error(err))
	}

	// Create outbox event
	_ = repo.CreateOutboxEvent(ctx, "message.events.v1", msg.ID.String(), map[string]any{
		"event_type":       "MessageSent",
		"message_id":       msg.ID.String(),
		"conversation_id":  conversationID.String(),
		"sender_id":        senderID.String(),
		"content":          req.Content,
		"client_message_id": req.ClientMessageID,
		"created_at":       time.Now().UTC(),
	})

	if err := tx.Commit(); err != nil {
		s.log.Error("failed to commit transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return s.buildMessageResponse(msg), nil
}

// ListMessages retrieves messages for a conversation.
func (s *Service) ListMessages(ctx context.Context, userID uuid.UUID, conversationID uuid.UUID, params pagination.Params) (*MessageListResponse, error) {
	params.ValidateAndNormalize(50)

	// Verify membership
	if _, err := s.repo.GetConversationMember(ctx, conversationID, userID); err != nil {
		return nil, errors.New("forbidden", 403, "not a member of this conversation")
	}

	messages, err := s.repo.ListMessages(ctx, conversationID, params.Cursor, params.Limit)
	if err != nil {
		s.log.Error("failed to list messages", logger.Error(err))
		return nil, errors.ErrInternal
	}

	hasMore := len(messages) > params.Limit
	if hasMore {
		messages = messages[:params.Limit]
	}

	var items []MessageResponse
	for _, m := range messages {
		items = append(items, *s.buildMessageResponse(m))
	}

	result := &MessageListResponse{
		Messages: items,
		HasMore:  hasMore,
	}

	if hasMore && len(messages) > 0 {
		result.NextCursor = messages[len(messages)-1].ID.String()
	}

	return result, nil
}

// ListConversations retrieves conversations for a user.
func (s *Service) ListConversations(ctx context.Context, userID uuid.UUID, params pagination.Params) (*ConversationListResponse, error) {
	params.ValidateAndNormalize(50)

	members, err := s.repo.ListUserConversations(ctx, userID, params.Cursor, params.Limit)
	if err != nil {
		s.log.Error("failed to list conversations", logger.Error(err))
		return nil, errors.ErrInternal
	}

	hasMore := len(members) > params.Limit
	if hasMore {
		members = members[:params.Limit]
	}

	var items []ConversationResponse
	for _, m := range members {
		conv, err := s.buildConversationResponse(ctx, m.ConversationID, userID)
		if err != nil {
			continue
		}
		items = append(items, *conv)
	}

	result := &ConversationListResponse{
		Conversations: items,
		HasMore:       hasMore,
	}

	if hasMore && len(members) > 0 {
		result.NextCursor = members[len(members)-1].ID.String()
	}

	return result, nil
}

// MarkAsRead marks messages in a conversation as read.
func (s *Service) MarkAsRead(ctx context.Context, userID uuid.UUID, req MarkReadRequest) error {
	conversationID, err := uuid.Parse(req.ConversationID)
	if err != nil {
		return errors.New("invalid_conversation_id", 400, "invalid conversation_id")
	}

	// Verify membership
	if _, err := s.repo.GetConversationMember(ctx, conversationID, userID); err != nil {
		return errors.New("forbidden", 403, "not a member of this conversation")
	}

	if err := s.repo.MarkAsRead(ctx, conversationID, userID); err != nil {
		s.log.Error("failed to mark as read", logger.Error(err))
		return errors.ErrInternal
	}

	return nil
}

func (s *Service) buildConversationResponse(ctx context.Context, conversationID, userID uuid.UUID) (*ConversationResponse, error) {
	conv, err := s.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return nil, err
	}

	resp := &ConversationResponse{
		ID:        conv.ID.String(),
		Type:      conv.Type,
		Title:     conv.Title,
		CreatedAt: conv.CreatedAt,
	}

	// Get unread count
	unreadCount, _ := s.repo.GetUnreadCount(ctx, conversationID, userID)
	resp.UnreadCount = unreadCount

	// Get last message
	if conv.LastMessageID != uuid.Nil {
		msg, err := s.repo.client.Message.Get(ctx, conv.LastMessageID)
		if err == nil {
			resp.LastMessage = s.buildMessageResponse(msg)
		}
	}

	// For direct conversations, get participant info
	if conv.Type == "direct" {
		members, _ := s.repo.GetConversationMembers(ctx, conversationID)
		for _, m := range members {
			if m.UserID != userID {
				resp.ParticipantID = m.UserID.String()
				break
			}
		}
	}

	return resp, nil
}

func (s *Service) buildMessageResponse(msg *ent.Message) *MessageResponse {
	return &MessageResponse{
		ID:              msg.ID.String(),
		ConversationID:  msg.ConversationID.String(),
		SenderID:        msg.SenderID.String(),
		Content:         msg.Content,
		Type:            msg.Type,
		ClientMessageID: msg.ClientMessageID,
		Status:          msg.Status,
		CreatedAt:       msg.CreatedAt,
	}
}

func isDuplicate(err error) bool {
	if err == nil {
		return false
	}
	return err.Error() == "duplicate message"
}
