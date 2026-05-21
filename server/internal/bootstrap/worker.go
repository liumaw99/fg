package bootstrap

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
	"social-server/internal/config"
	"social-server/internal/ent"
	"social-server/internal/ent/outboxevent"
	"social-server/internal/platform/kafka"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/redis"
)

// Worker holds the worker application dependencies.
type Worker struct {
	cfg       *config.Config
	log       *logger.Logger
	ent       *ent.Client
	rdb       *redis.Client
	kafka     *kafka.Producer
	consumers []*kafka.Consumer
	closers   []func() error
}

func NewWorker(cfg *config.Config, log *logger.Logger) (*Worker, error) {
	// Database (Ent)
	entClient, err := ent.Open("postgres", cfg.DatabaseURL)
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
		ent:   entClient,
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
	w.closers = append(w.closers, entClient.Close)

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
	if w.kafka == nil {
		return nil
	}

	// Fetch pending outbox events (limit 100 per run)
	events, err := w.ent.OutboxEvent.Query().
		Where(outboxevent.Status("pending")).
		Order(ent.Asc(outboxevent.FieldCreatedAt)).
		Limit(100).
		All(ctx)
	if err != nil {
		return fmt.Errorf("query outbox events: %w", err)
	}

	for _, evt := range events {
		payload := evt.Payload

		eventType, _ := payload["event_type"].(string)
		if eventType == "" {
			eventType = "Unknown"
		}

		envelope := kafka.EventEnvelope{
			EventID:       uuid.Must(uuid.NewRandom()).String(),
			EventType:     eventType,
			EventVersion:  1,
			AggregateType: "user",
			AggregateID:   evt.Key,
			OccurredAt:    time.Now(),
			Producer:      "worker",
			Payload:       mustMarshal(payload),
		}

		if err := w.kafka.Send(ctx, evt.Topic, evt.Key, envelope); err != nil {
			w.log.Error("failed to publish event",
				logger.String("event_id", evt.ID.String()),
				logger.String("topic", evt.Topic),
				logger.Error(err))
			continue
		}

		// Mark as published
		_, err := w.ent.OutboxEvent.UpdateOne(evt).
			SetStatus("published").
			SetPublishedAt(time.Now()).
			Save(ctx)
		if err != nil {
			w.log.Error("failed to mark event published",
				logger.String("event_id", evt.ID.String()),
				logger.Error(err))
		}

		w.log.Info("outbox event published",
			logger.String("event_id", evt.ID.String()),
			logger.String("topic", evt.Topic),
			logger.String("event_type", eventType))
	}

	return nil
}

func mustMarshal(v any) []byte {
	b, _ := json.Marshal(v)
	return b
}

// runConsumers starts Kafka consumers.
func (w *Worker) runConsumers(ctx context.Context) {
	// TODO: Register actual consumers
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
