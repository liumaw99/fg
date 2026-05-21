package storage

import (
	"context"
	"fmt"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// Client wraps MinIO client for object storage operations.
type Client struct {
	client     *minio.Client
	bucket     string
	useSSL     bool
	endpoint   string
}

// New creates a new storage client.
func New(endpoint, accessKey, secretKey, bucket string, useSSL bool) (*Client, error) {
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: useSSL,
	})
	if err != nil {
		return nil, fmt.Errorf("create minio client: %w", err)
	}

	ctx := context.Background()
	exists, err := minioClient.BucketExists(ctx, bucket)
	if err != nil {
		return nil, fmt.Errorf("check bucket exists: %w", err)
	}
	if !exists {
		if err := minioClient.MakeBucket(ctx, bucket, minio.MakeBucketOptions{}); err != nil {
			return nil, fmt.Errorf("create bucket: %w", err)
		}
	}

	return &Client{
		client:   minioClient,
		bucket:   bucket,
		useSSL:   useSSL,
		endpoint: endpoint,
	}, nil
}

// PresignedPutURL generates a presigned URL for uploading an object.
func (c *Client) PresignedPutURL(ctx context.Context, objectKey string, expiry time.Duration) (string, error) {
	url, err := c.client.PresignedPutObject(ctx, c.bucket, objectKey, expiry)
	if err != nil {
		return "", fmt.Errorf("presigned put url: %w", err)
	}
	return url.String(), nil
}

// PresignedGetURL generates a presigned URL for downloading an object.
func (c *Client) PresignedGetURL(ctx context.Context, objectKey string, expiry time.Duration) (string, error) {
	url, err := c.client.PresignedGetObject(ctx, c.bucket, objectKey, expiry, nil)
	if err != nil {
		return "", fmt.Errorf("presigned get url: %w", err)
	}
	return url.String(), nil
}

// PublicURL returns the public URL for an object.
func (c *Client) PublicURL(objectKey string) string {
	scheme := "http"
	if c.useSSL {
		scheme = "https"
	}
	return fmt.Sprintf("%s://%s/%s/%s", scheme, c.endpoint, c.bucket, objectKey)
}

// DeleteObject removes an object from storage.
func (c *Client) DeleteObject(ctx context.Context, objectKey string) error {
	return c.client.RemoveObject(ctx, c.bucket, objectKey, minio.RemoveObjectOptions{})
}
