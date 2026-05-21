package kafka

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/segmentio/kafka-go"
)

// EventEnvelope is the standard Kafka event envelope.
type EventEnvelope struct {
	EventID       string          `json:"event_id"`
	EventType     string          `json:"event_type"`
	EventVersion  int             `json:"event_version"`
	AggregateType string          `json:"aggregate_type"`
	AggregateID   string          `json:"aggregate_id"`
	OccurredAt    time.Time       `json:"occurred_at"`
	Producer      string          `json:"producer"`
	TraceID       string          `json:"trace_id"`
	Payload       json.RawMessage `json:"payload"`
}

// Producer wraps kafka.Writer.
type Producer struct {
	writers map[string]*kafka.Writer
	brokers []string
}

// NewProducer creates a new Kafka producer.
func NewProducer(brokers []string) *Producer {
	return &Producer{
		writers: make(map[string]*kafka.Writer),
		brokers: brokers,
	}
}

// Send publishes an event to a topic.
func (p *Producer) Send(ctx context.Context, topic string, key string, envelope EventEnvelope) error {
	writer, ok := p.writers[topic]
	if !ok {
		writer = kafka.NewWriter(kafka.WriterConfig{
			Brokers:      p.brokers,
			Topic:        topic,
			RequiredAcks: 1,
			Async:        false,
		})
		p.writers[topic] = writer
	}

	data, err := json.Marshal(envelope)
	if err != nil {
		return fmt.Errorf("marshal envelope: %w", err)
	}

	msg := kafka.Message{
		Key:   []byte(key),
		Value: data,
	}

	if err := writer.WriteMessages(ctx, msg); err != nil {
		return fmt.Errorf("write kafka message: %w", err)
	}

	return nil
}

// Close closes all writers.
func (p *Producer) Close() error {
	for _, w := range p.writers {
		if err := w.Close(); err != nil {
			return err
		}
	}
	return nil
}

// Consumer wraps kafka.Reader.
type Consumer struct {
	reader *kafka.Reader
	handler func(ctx context.Context, msg kafka.Message) error
}

// NewConsumer creates a new Kafka consumer.
func NewConsumer(brokers []string, topic, groupID string, handler func(ctx context.Context, msg kafka.Message) error) *Consumer {
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:        brokers,
		Topic:          topic,
		GroupID:        groupID,
		MinBytes:       1,
		MaxBytes:       10e6,
		CommitInterval: 0, // manual commit
		StartOffset:    kafka.FirstOffset,
	})

	return &Consumer{
		reader:  reader,
		handler: handler,
	}
}

// Run starts consuming messages.
func (c *Consumer) Run(ctx context.Context) error {
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		msg, err := c.reader.ReadMessage(ctx)
		if err != nil {
			if ctx.Err() != nil {
				return nil
			}
			return fmt.Errorf("read message: %w", err)
		}

		if err := c.handler(ctx, msg); err != nil {
			// Error handling: log and skip commit for retry
			continue
		}

		if err := c.reader.CommitMessages(ctx, msg); err != nil {
			return fmt.Errorf("commit message: %w", err)
		}
	}
}

// Close closes the consumer.
func (c *Consumer) Close() error {
	return c.reader.Close()
}
