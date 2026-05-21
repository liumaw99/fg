package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// ProcessedEvent holds the schema definition for the ProcessedEvent entity.
type ProcessedEvent struct {
	ent.Schema
}

// Fields of the ProcessedEvent.
func (ProcessedEvent) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("event_id", uuid.UUID{}),
		field.String("event_type").
			MaxLen(128).
			NotEmpty(),
		field.String("consumer_group").
			MaxLen(128).
			NotEmpty(),
		field.Time("processed_at").
			Default(time.Now).
			Immutable(),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

// Indexes of the ProcessedEvent.
func (ProcessedEvent) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("event_id", "consumer_group").
			Unique(),
	}
}
