package middleware

import (
	"github.com/gin-gonic/gin"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/response"
)

func Recovery(log *logger.Logger) gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, err any) {
		requestID := GetRequestID(c)
		log.Error("panic recovered",
			logger.String("request_id", requestID),
			logger.String("path", c.Request.URL.Path),
			logger.String("method", c.Request.Method),
			logger.Any("panic", err),
		)
		response.InternalError(c)
	})
}
