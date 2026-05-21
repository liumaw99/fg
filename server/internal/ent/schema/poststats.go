package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"github.com/google/uuid"
)

// PostStats holds the schema definition for the PostStats entity.
type PostStats struct {
	ent.Schema
}

// Fields of the PostStats.
func (PostStats) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("post_id", uuid.UUID{}).
			Unique(),
		field.Int("like_count").
			Default(0),
		field.Int("reply_count").
			Default(0),
		field.Int("repost_count").
			Default(0),
		field.Int("bookmark_count").
			Default(0),
		field.Int("view_count").
			Default(0),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
		field.Time("updated_at").
			Default(time.Now).
			Immutable(),
	}
}
