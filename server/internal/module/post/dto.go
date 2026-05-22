package post

import "time"

// CreatePostRequest represents a post creation request.
type CreatePostRequest struct {
	Content       string   `json:"content" binding:"required,max=2000"`
	MediaAssetIDs []string `json:"media_asset_ids"`
}

// CreateReplyRequest represents a reply creation request.
type CreateReplyRequest struct {
	Content string `json:"content" binding:"required,max=2000"`
}

// CreateRepostRequest represents a repost creation request.
type CreateRepostRequest struct {
	Content       string   `json:"content" binding:"max=2000"`
	MediaAssetIDs []string `json:"media_asset_ids"`
}

// PostAuthor represents the author summary embedded in PostResponse.
type PostAuthor struct {
	ID          string `json:"id"`
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	AvatarURL   string `json:"avatar_url"`
}

// PostResponse represents a post in API responses.
type PostResponse struct {
	ID                string         `json:"id"`
	UserID            string         `json:"user_id"`
	Author            *PostAuthor    `json:"author,omitempty"`
	Content           string         `json:"content"`
	ReplyToID         string         `json:"reply_to_id,omitempty"`
	ReplyToAuthorName string         `json:"reply_to_author_name,omitempty"`
	RepostOfID        string         `json:"repost_of_id,omitempty"`
	RepostOf          *PostResponse  `json:"repost_of,omitempty"`
	Status            string         `json:"status"`
	Visibility        string         `json:"visibility"`
	LikeCount         int            `json:"like_count"`
	ReplyCount        int            `json:"reply_count"`
	RepostCount       int            `json:"repost_count"`
	BookmarkCount     int            `json:"bookmark_count"`
	ViewCount         int            `json:"view_count"`
	MediaURLs         []MediaItem    `json:"media_urls,omitempty"`
	Replies           []PostResponse `json:"replies,omitempty"`
	IsLiked           bool           `json:"is_liked"`
	CreatedAt         time.Time      `json:"created_at"`
	UpdatedAt         time.Time      `json:"updated_at"`
}

// MediaItem represents a media attachment in a post.
type MediaItem struct {
	ID           string `json:"id"`
	URL          string `json:"url"`
	ThumbnailURL string `json:"thumbnail_url,omitempty"`
	MimeType     string `json:"mime_type"`
}

// PostListResponse represents a paginated list of posts.
type PostListResponse struct {
	Posts      []PostResponse `json:"posts"`
	NextCursor string         `json:"next_cursor,omitempty"`
	HasMore    bool           `json:"has_more"`
}
