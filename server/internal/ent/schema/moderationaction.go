package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"github.com/google/uuid"
)

// ModerationAction holds the schema definition for the ModerationAction entity.
type ModerationAction struct {
	ent.Schema
}

// Fields of the ModerationAction.
func (ModerationAction) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("moderator_id", uuid.UUID{}),
		field.UUID("target_user_id", uuid.UUID{}).
			Optional(),
		field.UUID("target_post_id", uuid.UUID{}).
			Optional(),
		field.UUID("report_id", uuid.UUID{}).
			Optional(),
		field.String("action_type").
			NotEmpty(),
		field.Text("reason").
			Default(""),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}
