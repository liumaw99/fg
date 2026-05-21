package user

// ProfileResponse represents a user's public profile.
type ProfileResponse struct {
	ID           string `json:"id"`
	Username     string `json:"username"`
	DisplayName  string `json:"display_name"`
	Bio          string `json:"bio"`
	AvatarURL    string `json:"avatar_url"`
	CoverURL     string `json:"cover_url"`
	Location     string `json:"location"`
	Website      string `json:"website"`
	FollowerCount int   `json:"follower_count"`
	FollowingCount int  `json:"following_count"`
	PostCount    int    `json:"post_count"`
}

// UpdateProfileRequest represents a profile update request.
type UpdateProfileRequest struct {
	DisplayName string `json:"display_name" binding:"max=50"`
	Bio         string `json:"bio" binding:"max=160"`
	Location    string `json:"location" binding:"max=100"`
	Website     string `json:"website" binding:"max=255"`
}

// UploadURLRequest represents a presigned URL request.
type UploadURLRequest struct {
	Filename string `json:"filename" binding:"required"`
	MimeType string `json:"mime_type" binding:"required"`
}

// UploadURLResponse represents a presigned URL response.
type UploadURLResponse struct {
	UploadURL string `json:"upload_url"`
	PublicURL string `json:"public_url"`
}
