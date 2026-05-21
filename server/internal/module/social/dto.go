package social

import "time"

// FollowRequest represents a follow action.
type FollowRequest struct {
	FollowingID string `json:"following_id" binding:"required,uuid"`
}

// UnfollowRequest represents an unfollow action.
type UnfollowRequest struct {
	FollowingID string `json:"following_id" binding:"required,uuid"`
}

// FollowResponse represents a follow relationship.
type FollowResponse struct {
	ID           string    `json:"id"`
	FollowerID   string    `json:"follower_id"`
	FollowingID  string    `json:"following_id"`
	CreatedAt    time.Time `json:"created_at"`
}

// FollowListResponse represents a paginated list of follows.
type FollowListResponse struct {
	Users      []FollowUser `json:"users"`
	NextCursor string       `json:"next_cursor,omitempty"`
	HasMore    bool         `json:"has_more"`
}

// FollowUser represents a user in follow lists.
type FollowUser struct {
	ID          string `json:"id"`
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	AvatarURL   string `json:"avatar_url"`
	Bio         string `json:"bio"`
}

// FollowStatusResponse represents whether the current user follows someone.
type FollowStatusResponse struct {
	IsFollowing bool `json:"is_following"`
}
