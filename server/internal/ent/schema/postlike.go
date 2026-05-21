package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// PostLike holds the schema definition for the PostLike entity.
type PostLike struct {
	ent.Schema
}

// Fields of the PostLike.
func (PostLike) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("post_id", uuid.UUID{}),
		field.UUID("user_id", uuid.UUID{}),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

// Indexes of the PostLike.
func (PostLike) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("post_id", "user_id").
			Unique(),
		index.Fields("post_id", "created_at"),
		index.Fields("user_id", "created_at"),
	}
}
