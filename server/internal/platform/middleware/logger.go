package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"social-server/internal/platform/logger"
)

func Logger(log *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		clientIP := c.ClientIP()
		method := c.Request.Method
		statusCode := c.Writer.Status()
		errorMessage := c.Errors.ByType(gin.ErrorTypePrivate).String()
		requestID := GetRequestID(c)

		fields := []logger.Field{
			logger.String("request_id", requestID),
			logger.Int("status", statusCode),
			logger.String("method", method),
			logger.String("path", path),
			logger.String("ip", clientIP),
			logger.Duration("latency", latency),
			logger.String("user_agent", c.Request.UserAgent()),
		}
		if raw != "" {
			fields = append(fields, logger.String("query", raw))
		}
		if errorMessage != "" {
			fields = append(fields, logger.String("error", errorMessage))
		}
		if uid, exists := c.Get("user_id"); exists {
			fields = append(fields, logger.Any("user_id", uid))
		}

		if statusCode >= 500 {
			log.Error("server error", fields...)
		} else if statusCode >= 400 {
			log.Warn("client error", fields...)
		} else {
			log.Info("request handled", fields...)
		}
	}
}
