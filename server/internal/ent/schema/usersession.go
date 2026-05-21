package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
	"github.com/google/uuid"
)

// UserSession holds the schema definition for the UserSession entity.
type UserSession struct {
	ent.Schema
}

// Fields of the UserSession.
func (UserSession) Fields() []ent.Field {
	return []ent.Field{
		field.UUID("id", uuid.UUID{}).
			Default(uuid.New).
			Unique(),
		field.UUID("user_id", uuid.UUID{}),
		field.String("token_id").
			MaxLen(128).
			NotEmpty(),
		field.String("device_info").
			MaxLen(255).
			Default(""),
		field.String("ip_address").
			MaxLen(45).
			Default(""),
		field.Time("expires_at").
			Default(func() time.Time { return time.Now().AddDate(0, 0, 7) }),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}
