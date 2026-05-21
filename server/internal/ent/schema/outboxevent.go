package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"github.com/google/uuid"
)

// OutboxEvent holds the schema definition for the OutboxEvent entity.
type OutboxEvent struct {
	ent.Schema
}

// Fields of the OutboxEvent.
func (OutboxEvent) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.String("topic").
			MaxLen(128).
			NotEmpty(),
		field.String("key").
			MaxLen(128).
			Default(""),
		field.JSON("payload", map[string]any{}),
		field.String("status").
			Default("pending"),
		field.Int("retry_count").
			Default(0),
		field.String("last_error").
			MaxLen(512).
			Default(""),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
		field.Time("published_at").
			Optional(),
	}
}
