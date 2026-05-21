package pagination

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strconv"
	"time"
)

// Cursor is the standard pagination cursor.
type Cursor struct {
	ID        string    `json:"id,omitempty"`
	Timestamp time.Time `json:"ts,omitempty"`
	Score     float64   `json:"score,omitempty"`
}

// Encode serializes a cursor to a base64 string.
func (c Cursor) Encode() string {
	if c.IsEmpty() {
		return ""
	}
	data, _ := json.Marshal(c)
	return base64.RawURLEncoding.EncodeToString(data)
}

// IsEmpty returns true if the cursor has no meaningful values.
func (c Cursor) IsEmpty() bool {
	return c.ID == "" && c.Timestamp.IsZero() && c.Score == 0
}

// DecodeCursor parses a base64 cursor string.
func DecodeCursor(s string) (Cursor, error) {
	if s == "" {
		return Cursor{}, nil
	}
	data, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return Cursor{}, fmt.Errorf("invalid cursor: %w", err)
	}
	var c Cursor
	if err := json.Unmarshal(data, &c); err != nil {
		return Cursor{}, fmt.Errorf("invalid cursor data: %w", err)
	}
	return c, nil
}

// Params holds pagination request parameters.
type Params struct {
	Cursor    string
	Limit     int
	Direction string // "desc" | "asc"
}

// DefaultParams returns default pagination parameters.
func DefaultParams() Params {
	return Params{Limit: 20, Direction: "desc"}
}

// ValidateAndNormalize ensures limit is within bounds.
func (p *Params) ValidateAndNormalize(maxLimit int) {
	if p.Limit <= 0 {
		p.Limit = 20
	}
	if maxLimit > 0 && p.Limit > maxLimit {
		p.Limit = maxLimit
	}
	if p.Direction == "" {
		p.Direction = "desc"
	}
}

// Result wraps paginated response metadata.
type Result struct {
	NextCursor string `json:"next_cursor,omitempty"`
	HasMore    bool   `json:"has_more"`
}

// MakeResult creates a pagination result from items.
func MakeResult[T any](items []T, limit int, getCursor func(T) Cursor) Result {
	r := Result{HasMore: false, NextCursor: ""}
	if len(items) > limit {
		r.HasMore = true
		last := items[limit-1]
		r.NextCursor = getCursor(last).Encode()
	}
	return r
}

// ParseIntCursor parses a simple integer cursor.
func ParseIntCursor(s string) (int64, error) {
	if s == "" {
		return 0, nil
	}
	return strconv.ParseInt(s, 10, 64)
}

// IntCursor formats an integer as cursor string.
func IntCursor(v int64) string {
	return strconv.FormatInt(v, 10)
}
