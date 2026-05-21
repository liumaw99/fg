package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// Report holds the schema definition for the Report entity.
type Report struct {
	ent.Schema
}

// Fields of the Report.
func (Report) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("reporter_id", uuid.UUID{}),
		field.UUID("target_user_id", uuid.UUID{}).
			Optional(),
		field.UUID("target_post_id", uuid.UUID{}).
			Optional(),
		field.String("type").
			NotEmpty(),
		field.Text("reason").
			NotEmpty(),
		field.String("status").
			Default("pending"),
		field.Text("review_notes").
			Default(""),
		field.UUID("reviewed_by", uuid.UUID{}).
			Optional(),
		field.Time("reviewed_at").
			Optional(),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

// Indexes of the Report.
func (Report) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("reporter_id", "created_at"),
		index.Fields("target_user_id", "created_at"),
		index.Fields("target_post_id", "created_at"),
		index.Fields("status", "created_at"),
	}
}
