package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// Notification holds the schema definition for the Notification entity.
type Notification struct {
	ent.Schema
}

// Fields of the Notification.
func (Notification) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("user_id", uuid.UUID{}),
		field.UUID("actor_id", uuid.UUID{}).
			Optional(),
		field.String("type").
			NotEmpty(),
		field.UUID("post_id", uuid.UUID{}).
			Optional(),
		field.Text("content").
			Default(""),
		field.Bool("is_read").
			Default(false),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

// Indexes of the Notification.
func (Notification) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("user_id", "is_read", "created_at"),
		index.Fields("user_id", "created_at"),
	}
}
