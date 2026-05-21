package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// Post holds the schema definition for the Post entity.
type Post struct {
	ent.Schema
}

// Fields of the Post.
func (Post) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("user_id", uuid.UUID{}),
		field.Text("content").
			MaxLen(2000).
			Default(""),
		field.UUID("reply_to_id", uuid.UUID{}).
			Optional(),
		field.UUID("repost_of_id", uuid.UUID{}).
			Optional(),
		field.String("status").
			Default("active"),
		field.String("visibility").
			Default("public"),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
		field.Time("updated_at").
			Default(time.Now).
			Immutable(),
		field.Time("deleted_at").
			Optional(),
	}
}

// Indexes of the Post.
func (Post) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("user_id", "created_at"),
		index.Fields("reply_to_id", "created_at"),
		index.Fields("repost_of_id", "created_at"),
		index.Fields("status", "created_at"),
	}
}
