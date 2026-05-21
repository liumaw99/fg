package middleware

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

const HeaderRequestID = "X-Request-ID"

func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		rid := c.GetHeader(HeaderRequestID)
		if rid == "" {
			rid = uuid.Must(uuid.NewRandom()).String()
		}
		c.Set("request_id", rid)
		c.Writer.Header().Set(HeaderRequestID, rid)
		c.Next()
	}
}

func GetRequestID(c *gin.Context) string {
	if rid, ok := c.Get("request_id"); ok {
		if s, ok := rid.(string); ok {
			return s
		}
	}
	return ""
}
