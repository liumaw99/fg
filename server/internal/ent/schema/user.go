package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
	"github.com/google/uuid"
)

// User holds the schema definition for the User entity.
type User struct {
	ent.Schema
}

// Fields of the User.
func (User) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.String("username").
			MaxLen(30).
			NotEmpty().
			Unique(),
		field.String("email").
			MaxLen(255).
			NotEmpty().
			Unique(),
		field.String("password_hash").
			NotEmpty().
			Sensitive(),
		field.String("status").
			Default("active"),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
		field.Time("updated_at").
			Default(time.Now).
			Immutable(),
	}
}

// Indexes of the User.
func (User) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("username").
			Unique(),
		index.Fields("email").
			Unique(),
	}
}
