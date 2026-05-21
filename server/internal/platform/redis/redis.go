package redis

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// Client wraps go-redis client.
type Client struct {
	*redis.Client
}

// New creates a new Redis client.
func New(addr string, db int, password string) (*Client, error) {
	if addr == "" {
		addr = "localhost:6379"
	}

	rdb := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
		DB:       db,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := rdb.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("ping redis: %w", err)
	}

	return &Client{rdb}, nil
}

// SetJSON stores a JSON-serializable value with TTL.
func (c *Client) SetJSON(ctx context.Context, key string, value any, ttl time.Duration) error {
	return c.Client.Set(ctx, key, value, ttl).Err()
}

// GetString gets a string value.
func (c *Client) GetString(ctx context.Context, key string) (string, error) {
	return c.Client.Get(ctx, key).Result()
}

// Delete removes keys.
func (c *Client) Delete(ctx context.Context, keys ...string) error {
	return c.Client.Del(ctx, keys...).Err()
}

// Exists checks if keys exist.
func (c *Client) Exists(ctx context.Context, keys ...string) (int64, error) {
	return c.Client.Exists(ctx, keys...).Result()
}

// Close closes the client.
func (c *Client) Close() error {
	return c.Client.Close()
}
