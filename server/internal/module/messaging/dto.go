package messaging

import "time"

// CreateConversationRequest represents a conversation creation request.
type CreateConversationRequest struct {
	ParticipantID string `json:"participant_id" binding:"required,uuid"`
}

// ConversationResponse represents a conversation in API responses.
type ConversationResponse struct {
	ID            string    `json:"id"`
	Type          string    `json:"type"`
	Title         string    `json:"title"`
	ParticipantID string    `json:"participant_id,omitempty"`
	LastMessage   *MessageResponse `json:"last_message,omitempty"`
	UnreadCount   int       `json:"unread_count"`
	CreatedAt     time.Time `json:"created_at"`
}

// SendMessageRequest represents a message send request.
type SendMessageRequest struct {
	ConversationID  string `json:"conversation_id" binding:"required,uuid"`
	Content         string `json:"content" binding:"required,max=2000"`
	ClientMessageID string `json:"client_message_id" binding:"required,max=64"`
}

// MessageResponse represents a message in API responses.
type MessageResponse struct {
	ID              string    `json:"id"`
	ConversationID  string    `json:"conversation_id"`
	SenderID        string    `json:"sender_id"`
	Content         string    `json:"content"`
	Type            string    `json:"type"`
	ClientMessageID string    `json:"client_message_id"`
	Status          string    `json:"status"`
	CreatedAt       time.Time `json:"created_at"`
}

// MessageListResponse represents a paginated list of messages.
type MessageListResponse struct {
	Messages   []MessageResponse `json:"messages"`
	NextCursor string            `json:"next_cursor,omitempty"`
	HasMore    bool              `json:"has_more"`
}

// ConversationListResponse represents a paginated list of conversations.
type ConversationListResponse struct {
	Conversations []ConversationResponse `json:"conversations"`
	NextCursor    string                 `json:"next_cursor,omitempty"`
	HasMore       bool                   `json:"has_more"`
}

// MarkReadRequest represents a mark-as-read request.
type MarkReadRequest struct {
	ConversationID string `json:"conversation_id" binding:"required,uuid"`
	MessageID      string `json:"message_id" binding:"required,uuid"`
}
