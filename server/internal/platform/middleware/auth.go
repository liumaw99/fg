package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
	"social-server/internal/platform/response"
)

// JWTClaims is the expected interface for parsed claims.
type JWTClaims interface {
	GetUserID() string
	GetTokenID() string
	Valid() error
}

// TokenValidator parses and validates access tokens.
type TokenValidator interface {
	Validate(token string) (JWTClaims, error)
}

func Auth(tv TokenValidator) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" {
			response.Unauthorized(c, "missing_token", "authorization header required")
			c.Abort()
			return
		}

		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			response.Unauthorized(c, "invalid_token_format", "authorization header must be Bearer {token}")
			c.Abort()
			return
		}

		claims, err := tv.Validate(parts[1])
		if err != nil {
			response.Unauthorized(c, "invalid_token", err.Error())
			c.Abort()
			return
		}

		c.Set("user_id", claims.GetUserID())
		c.Set("token_id", claims.GetTokenID())
		c.Next()
	}
}

func GetUserID(c *gin.Context) string {
	if uid, ok := c.Get("user_id"); ok {
		if s, ok := uid.(string); ok {
			return s
		}
	}
	return ""
}
