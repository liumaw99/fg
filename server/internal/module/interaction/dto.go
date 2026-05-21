package interaction

import "time"

// LikeRequest represents a like action.
type LikeRequest struct {
	PostID string `json:"post_id" binding:"required,uuid"`
}

// UnlikeRequest represents an unlike action.
type UnlikeRequest struct {
	PostID string `json:"post_id" binding:"required,uuid"`
}

// LikeStatusResponse represents whether the current user liked a post.
type LikeStatusResponse struct {
	IsLiked bool `json:"is_liked"`
	Count   int  `json:"count"`
}

// ReplyRequest represents a reply to a post.
type ReplyRequest struct {
	PostID  string `json:"post_id" binding:"required,uuid"`
	Content string `json:"content" binding:"required,max=2000"`
}

// RepostRequest represents a repost action.
type RepostRequest struct {
	PostID string `json:"post_id" binding:"required,uuid"`
}

// NotificationResponse represents a notification.
type NotificationResponse struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	ActorID   string    `json:"actor_id,omitempty"`
	Type      string    `json:"type"`
	PostID    string    `json:"post_id,omitempty"`
	Content   string    `json:"content"`
	IsRead    bool      `json:"is_read"`
	CreatedAt time.Time `json:"created_at"`
}

// NotificationListResponse represents a paginated list of notifications.
type NotificationListResponse struct {
	Notifications []NotificationResponse `json:"notifications"`
	UnreadCount   int                    `json:"unread_count"`
	NextCursor    string                 `json:"next_cursor,omitempty"`
	HasMore       bool                   `json:"has_more"`
}
