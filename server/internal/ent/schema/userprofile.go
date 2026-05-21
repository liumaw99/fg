package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"github.com/google/uuid"
)

// UserProfile holds the schema definition for the UserProfile entity.
type UserProfile struct {
	ent.Schema
}

// Fields of the UserProfile.
func (UserProfile) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("user_id", uuid.UUID{}),
		field.String("display_name").
			MaxLen(50).
			Default(""),
		field.String("bio").
			MaxLen(160).
			Default(""),
		field.String("avatar_url").
			MaxLen(512).
			Default(""),
		field.String("cover_url").
			MaxLen(512).
			Default(""),
		field.String("location").
			MaxLen(100).
			Default(""),
		field.String("website").
			MaxLen(255).
			Default(""),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
		field.Time("updated_at").
			Default(time.Now).
			Immutable(),
	}
}
