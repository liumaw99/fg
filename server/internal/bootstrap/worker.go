package bootstrap

import (
	"context"
	"fmt"
	"time"

	"social-server/internal/config"
	"social-server/internal/platform/database"
	"social-server/internal/platform/kafka"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/redis"
)

// Worker holds the worker application dependencies.
type Worker struct {
	cfg      *config.Config
	log      *logger.Logger
	db       *database.DB
	rdb      *redis.Client
	kafka    *kafka.Producer
	consumers []*kafka.Consumer
	closers   []func() error
}

func NewWorker(cfg *config.Config, log *logger.Logger) (*Worker, error) {
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

	w := &Worker{
		cfg:   cfg,
		log:   log,
		db:    db,
		rdb:   rdb,
		kafka: kp,
	}

	w.closers = append(w.closers, func() error {
		if kp != nil {
			return kp.Close()
		}
		return nil
	})
	w.closers = append(w.closers, rdb.Close)
	w.closers = append(w.closers, db.Close)

	return w, nil
}

// Run starts the worker processes.
func (w *Worker) Run(ctx context.Context) error {
	// Start outbox publisher
	go w.runOutboxPublisher(ctx)

	// Start consumers if Kafka is configured
	if len(w.cfg.KafkaBrokers) > 0 && w.cfg.KafkaBrokers[0] != "" {
		go w.runConsumers(ctx)
	}

	<-ctx.Done()
	return ctx.Err()
}

// runOutboxPublisher scans and publishes pending outbox events.
func (w *Worker) runOutboxPublisher(ctx context.Context) {
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if err := w.publishOutboxEvents(ctx); err != nil {
				w.log.Error("outbox publisher failed", logger.Error(err))
			}
		}
	}
}

func (w *Worker) publishOutboxEvents(ctx context.Context) error {
	// TODO: Implement outbox event scanning and publishing
	// This will be implemented when Ent schema and outbox_events table are created
	return nil
}

// runConsumers starts Kafka consumers.
func (w *Worker) runConsumers(ctx context.Context) {
	// TODO: Register actual consumers
	// timeline-fanout-consumer
	// notification-consumer
	// push-consumer
	// search-index-consumer
	// media-processing-consumer
}

// Close shuts down the worker.
func (w *Worker) Close(ctx context.Context) error {
	for _, c := range w.consumers {
		if err := c.Close(); err != nil {
			w.log.Error("consumer close failed", logger.Error(err))
		}
	}
	for _, fn := range w.closers {
		if err := fn(); err != nil {
			w.log.Error("close failed", logger.Error(err))
		}
	}
	return nil
}
