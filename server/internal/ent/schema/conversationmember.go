package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// ConversationMember holds the schema definition for the ConversationMember entity.
type ConversationMember struct {
	ent.Schema
}

// Fields of the ConversationMember.
func (ConversationMember) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("conversation_id", uuid.UUID{}),
		field.UUID("user_id", uuid.UUID{}),
		field.Time("joined_at").
			Default(time.Now).
			Immutable(),
		field.Time("last_read_at").
			Default(time.Now),
	}
}

// Indexes of the ConversationMember.
func (ConversationMember) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("conversation_id", "user_id").
			Unique(),
		index.Fields("user_id", "joined_at"),
	}
}
