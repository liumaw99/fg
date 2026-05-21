package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// PostMedia holds the schema definition for the PostMedia join entity.
type PostMedia struct {
	ent.Schema
}

// Fields of the PostMedia.
func (PostMedia) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("post_id", uuid.UUID{}),
		field.UUID("media_asset_id", uuid.UUID{}),
		field.Int("sort_order").
			Default(0),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

// Indexes of the PostMedia.
func (PostMedia) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("post_id", "sort_order"),
		index.Fields("media_asset_id"),
	}
}
