package middleware

import (
	"context"
	"strconv"

	"github.com/gin-gonic/gin"
	"social-server/internal/platform/response"
)

// RateLimiter allows or denies requests based on key.
type RateLimiter interface {
	Allow(ctx context.Context, key string, rps, burst int) (bool, int64, error)
}

// RateLimit middleware enforces rate limits per IP or per user.
func RateLimit(limiter RateLimiter, rps, burst int) gin.HandlerFunc {
	return func(c *gin.Context) {
		key := c.ClientIP()
		if uid := GetUserID(c); uid != "" {
			key = uid
		}

		allowed, retryAfter, err := limiter.Allow(c.Request.Context(), key, rps, burst)
		if err != nil {
			response.InternalError(c)
			c.Abort()
			return
		}
		if !allowed {
			c.Writer.Header().Set("Retry-After", strconv.FormatInt(retryAfter, 10))
			response.TooManyRequests(c, "rate_limited", "too many requests")
			c.Abort()
			return
		}

		c.Next()
	}
}
