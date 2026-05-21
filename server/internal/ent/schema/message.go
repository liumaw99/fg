package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// Message holds the schema definition for the Message entity.
type Message struct {
	ent.Schema
}

// Fields of the Message.
func (Message) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("conversation_id", uuid.UUID{}),
		field.UUID("sender_id", uuid.UUID{}),
		field.Text("content").
			Default(""),
		field.String("type").
			Default("text"), // text, image, system
		field.String("client_message_id").
			MaxLen(64).
			Default(""),
		field.String("status").
			Default("sent"), // sending, sent, delivered, read, failed
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

// Indexes of the Message.
func (Message) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("conversation_id", "created_at"),
		index.Fields("client_message_id").
			Unique(),
	}
}
