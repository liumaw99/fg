package bootstrap

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"social-server/internal/config"
	"social-server/internal/platform/database"
	"social-server/internal/platform/kafka"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/redis"
	"social-server/internal/platform/security"
	"social-server/internal/platform/storage"
)

// App holds the API application dependencies.
type App struct {
	router   *gin.Engine
	cfg      *config.Config
	log      *logger.Logger
	db       *database.DB
	rdb      *redis.Client
	kafka    *kafka.Producer
	storage  *storage.Client
	jwt      *security.JWTManager
	closers  []func() error
}

func NewAPI(cfg *config.Config, log *logger.Logger) (*App, error) {
	if cfg.IsProduction() {
		gin.SetMode(gin.ReleaseMode)
	}

	// Database
	db, err := database.New(cfg.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("database: %w", err)
	}

	// Redis
	rdb, err := redis.New(cfg.RedisAddr, cfg.RedisDB, cfg.RedisPassword)
	if err != nil {
		return nil, fmt.Errorf("redis: %w", err)
	}

	// Kafka Producer
	var kp *kafka.Producer
	if len(cfg.KafkaBrokers) > 0 && cfg.KafkaBrokers[0] != "" {
		kp = kafka.NewProducer(cfg.KafkaBrokers)
	}

	// Object Storage
	var st *storage.Client
	if cfg.StorageEndpoint != "" {
		st, err = storage.New(cfg.StorageEndpoint, cfg.StorageAccessKey, cfg.StorageSecretKey, cfg.StorageBucket, cfg.StorageUseSSL)
		if err != nil {
			return nil, fmt.Errorf("storage: %w", err)
		}
	}

	// JWT
	jwt := security.NewJWTManager(cfg.JWTSecret, cfg.JWTAccessTTL, cfg.JWTRefreshTTL)

	app := &App{
		cfg:     cfg,
		log:     log,
		db:      db,
		rdb:     rdb,
		kafka:   kp,
		storage: st,
		jwt:     jwt,
	}

	app.setupRouter()

	app.closers = append(app.closers, func() error {
		if kp != nil {
			return kp.Close()
		}
		return nil
	})
	app.closers = append(app.closers, rdb.Close)
	app.closers = append(app.closers, db.Close)

	return app, nil
}

func (a *App) Router() *gin.Engine {
	return a.router
}

func (a *App) Close() error {
	for _, fn := range a.closers {
		if err := fn(); err != nil {
			a.log.Error("close failed", logger.Error(err))
		}
	}
	return nil
}

func (a *App) Config() *config.Config        { return a.cfg }
func (a *App) Log() *logger.Logger            { return a.log }
func (a *App) DB() *database.DB               { return a.db }
func (a *App) Redis() *redis.Client           { return a.rdb }
func (a *App) Kafka() *kafka.Producer         { return a.kafka }
func (a *App) Storage() *storage.Client       { return a.storage }
func (a *App) JWTManager() *security.JWTManager { return a.jwt }
