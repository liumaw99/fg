package bootstrap

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"social-server/internal/module/auth"
	"social-server/internal/module/interaction"
	"social-server/internal/module/messaging"
	"social-server/internal/module/moderation"
	"social-server/internal/module/post"
	"social-server/internal/module/social"
	"social-server/internal/module/user"
	"social-server/internal/platform/middleware"
	"social-server/internal/platform/response"
	"social-server/internal/platform/security"
)

// tokenValidator adapts security.JWTManager to middleware.TokenValidator.
type tokenValidator struct {
	jwt *security.JWTManager
}

func (v *tokenValidator) Validate(token string) (middleware.JWTClaims, error) {
	return v.jwt.Validate(token)
}

func (a *App) setupRouter() {
	r := gin.New()

	// Global middleware
	r.Use(middleware.RequestID())
	r.Use(middleware.Recovery(a.log))
	r.Use(middleware.Logger(a.log))
	r.Use(middleware.CORS(a.cfg.CORSOrigins))
	r.Use(middleware.SecurityHeaders())
	r.Use(middleware.Timeout(30 * time.Second))

	// Health checks
	r.GET("/health", func(c *gin.Context) {
		response.OK(c, gin.H{"status": "ok"})
	})
	r.GET("/ready", func(c *gin.Context) {
		response.OK(c, gin.H{"status": "ready"})
	})

	// Init modules
	authHandler := auth.NewAuthModule(a.ent, a.jwt, a.log)
	userHandler := user.NewUserModule(a.ent, a.storage, a.log)
	postHandler := post.NewPostModule(a.ent, a.log)
	socialHandler := social.NewSocialModule(a.ent, a.log)
	interactionHandler := interaction.NewInteractionModule(a.ent, a.log)
	moderationHandler := moderation.NewModerationModule(a.ent, a.log)
	messagingHandler := messaging.NewMessagingModule(a.ent, a.log)

	// API v1
	v1 := r.Group("/api/v1")
	{
		// Auth routes (public)
		authGroup := v1.Group("/auth")
		{
			authGroup.POST("/register", authHandler.Register)
			authGroup.POST("/login", authHandler.Login)
			authGroup.POST("/refresh", authHandler.Refresh)
			authGroup.POST("/logout", authHandler.Logout)
		}

		// Protected routes
		protected := v1.Group("")
		protected.Use(middleware.Auth(&tokenValidator{jwt: a.jwt}))
		{
			protected.GET("/me", authHandler.Me)

			// Users
			users := protected.Group("/users")
			{
				users.GET("/profile", userHandler.GetProfile)
				users.PATCH("/profile", userHandler.UpdateProfile)
				users.POST("/avatar/upload-url", userHandler.GetAvatarUploadURL)
				users.GET("/:username", userHandler.GetUserByUsername)
			}

			// Posts
			posts := protected.Group("/posts")
			{
				posts.POST("", postHandler.CreatePost)
				posts.GET("/feed", postHandler.ListPosts)
				posts.GET("/:id/replies", postHandler.ListReplies)
				posts.POST("/:id/replies", postHandler.CreateReply)
				posts.GET("/:id", postHandler.GetPost)
				posts.DELETE("/:id", postHandler.DeletePost)
				posts.GET("/user/:user_id", postHandler.ListUserPosts)
			}

			// Social
			social := protected.Group("/social")
			{
				social.POST("/follow", socialHandler.Follow)
				social.POST("/unfollow", socialHandler.Unfollow)
				social.GET("/follow-status/:user_id", socialHandler.GetFollowStatus)
				social.GET("/followers/:user_id", socialHandler.ListFollowers)
				social.GET("/following/:user_id", socialHandler.ListFollowing)
			}

			// Interactions
			interactions := protected.Group("/interactions")
			{
				interactions.POST("/like", interactionHandler.Like)
				interactions.POST("/unlike", interactionHandler.Unlike)
				interactions.GET("/like-status/:post_id", interactionHandler.GetLikeStatus)
				interactions.GET("/notifications", interactionHandler.ListNotifications)
				interactions.POST("/notifications/:id/read", interactionHandler.MarkNotificationAsRead)
				interactions.POST("/notifications/read-all", interactionHandler.MarkAllNotificationsAsRead)
			}

			// Moderation & Search
			protected.POST("/reports", moderationHandler.CreateReport)
			protected.GET("/reports", moderationHandler.ListReports)
			protected.POST("/moderation/actions", moderationHandler.TakeAction)
			protected.GET("/search", moderationHandler.Search)

			// Messaging
			protected.POST("/conversations", messagingHandler.CreateConversation)
			protected.GET("/conversations", messagingHandler.ListConversations)
			protected.POST("/messages", messagingHandler.SendMessage)
			protected.GET("/conversations/:conversation_id/messages", messagingHandler.ListMessages)
			protected.POST("/conversations/read", messagingHandler.MarkAsRead)

			// Timeline - posts from followed users
			protected.GET("/timeline", postHandler.ListPosts)
		}
	}

	// WebSocket
	r.GET("/ws/v1/realtime", func(c *gin.Context) {
		response.OK(c, gin.H{"message": "websocket placeholder"})
	})

	// 404 handler
	r.NoRoute(func(c *gin.Context) {
		response.NotFound(c, "not_found", "resource not found")
	})

	// Method not allowed
	r.NoMethod(func(c *gin.Context) {
		response.Error(c, http.StatusMethodNotAllowed, "method_not_allowed", "method not allowed")
	})

	a.router = r
}
