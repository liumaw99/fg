package media

// UploadURLRequest represents a presigned upload URL request.
type UploadURLRequest struct {
	Filename string `json:"filename" binding:"required,max=255"`
	MimeType string `json:"mime_type" binding:"required,max=64"`
	Size     int64  `json:"size" binding:"omitempty,min=0"`
	Purpose  string `json:"purpose" binding:"omitempty,max=32"`
}

// UploadURLResponse represents a presigned upload target.
type UploadURLResponse struct {
	MediaAssetID string `json:"media_asset_id"`
	UploadURL    string `json:"upload_url"`
	PublicURL    string `json:"public_url"`
}
