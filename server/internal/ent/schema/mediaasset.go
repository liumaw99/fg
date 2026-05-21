package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"github.com/google/uuid"
)

// MediaAsset holds the schema definition for the MediaAsset entity.
type MediaAsset struct {
	ent.Schema
}

// Fields of the MediaAsset.
func (MediaAsset) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("owner_id", uuid.UUID{}),
		field.String("filename").
			MaxLen(255).
			NotEmpty(),
		field.String("mime_type").
			MaxLen(64).
			NotEmpty(),
		field.Int64("size").
			Default(0),
		field.String("url").
			MaxLen(512).
			Default(""),
		field.String("thumbnail_url").
			MaxLen(512).
			Default(""),
		field.String("status").
			Default("pending"),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
		field.Time("updated_at").
			Default(time.Now).
			Immutable(),
	}
}
