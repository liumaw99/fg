package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"github.com/google/uuid"
)

// UserStats holds the schema definition for the UserStats entity.
type UserStats struct {
	ent.Schema
}

// Fields of the UserStats.
func (UserStats) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("user_id", uuid.UUID{}).
			Unique(),
		field.Int("post_count").
			Default(0),
		field.Int("follower_count").
			Default(0),
		field.Int("following_count").
			Default(0),
		field.Int("like_received_count").
			Default(0),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
		field.Time("updated_at").
			Default(time.Now).
			Immutable(),
	}
}
