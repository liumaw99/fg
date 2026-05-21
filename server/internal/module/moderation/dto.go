package moderation

import "time"

// ReportRequest represents a report submission.
type ReportRequest struct {
	TargetUserID string `json:"target_user_id"`
	TargetPostID string `json:"target_post_id"`
	Type         string `json:"type" binding:"required"`
	Reason       string `json:"reason" binding:"required,max=1000"`
}

// ReportResponse represents a report in API responses.
type ReportResponse struct {
	ID           string    `json:"id"`
	ReporterID   string    `json:"reporter_id"`
	TargetUserID string    `json:"target_user_id,omitempty"`
	TargetPostID string    `json:"target_post_id,omitempty"`
	Type         string    `json:"type"`
	Reason       string    `json:"reason"`
	Status       string    `json:"status"`
	ReviewNotes  string    `json:"review_notes"`
	ReviewedBy   string    `json:"reviewed_by,omitempty"`
	ReviewedAt   time.Time `json:"reviewed_at,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

// ReportListResponse represents a paginated list of reports.
type ReportListResponse struct {
	Reports    []ReportResponse `json:"reports"`
	NextCursor string           `json:"next_cursor,omitempty"`
	HasMore    bool             `json:"has_more"`
}

// ModerationActionRequest represents a moderation action.
type ModerationActionRequest struct {
	TargetUserID string `json:"target_user_id"`
	TargetPostID string `json:"target_post_id"`
	ReportID     string `json:"report_id"`
	ActionType   string `json:"action_type" binding:"required"`
	Reason       string `json:"reason" binding:"required,max=1000"`
}

// SearchRequest represents a search query.
type SearchRequest struct {
	Query  string `json:"q" binding:"required,min=1,max=100"`
	Type   string `json:"type"` // "users" | "posts" | "all"
	Cursor string `json:"cursor"`
}

// SearchResult represents a search result item.
type SearchResult struct {
	ID       string `json:"id"`
	Type     string `json:"type"` // "user" | "post"
	Title    string `json:"title"`
	Subtitle string `json:"subtitle,omitempty"`
	Content  string `json:"content,omitempty"`
}

// SearchResponse represents search results.
type SearchResponse struct {
	Results    []SearchResult `json:"results"`
	NextCursor string         `json:"next_cursor,omitempty"`
	HasMore    bool           `json:"has_more"`
}
