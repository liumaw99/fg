package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// Follow holds the schema definition for the Follow entity.
type Follow struct {
	ent.Schema
}

// Fields of the Follow.
func (Follow) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("follower_id", uuid.UUID{}),
		field.UUID("following_id", uuid.UUID{}),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

// Indexes of the Follow.
func (Follow) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("follower_id", "following_id").
			Unique(),
		index.Fields("follower_id", "created_at"),
		index.Fields("following_id", "created_at"),
	}
}
