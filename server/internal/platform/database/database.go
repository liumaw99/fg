package database

import (
	"context"
	"database/sql"
	"fmt"
	"os"

	"entgo.io/ent/dialect"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/stdlib"
)

// DB wraps pgx connection pool and migration capabilities.
type DB struct {
	*sql.DB
	driverName string
	migrationsPath string
}

// New creates a new DB connection.
func New(databaseURL string) (*DB, error) {
	if databaseURL == "" {
		return nil, fmt.Errorf("database url is empty")
	}

	config, err := pgx.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("parse database url: %w", err)
	}

	// Register pgx driver with standard library
	db := stdlib.OpenDB(*config)

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("ping database: %w", err)
	}

	// Set sensible defaults
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	migrationsPath := os.Getenv("MIGRATIONS_PATH")
	if migrationsPath == "" {
		migrationsPath = "file://internal/ent/migrate/migrations"
	}

	return &DB{
		DB:             db,
		driverName:     dialect.Postgres,
		migrationsPath: migrationsPath,
	}, nil
}

// EntDriver returns the dialect name for Ent client initialization.
func (db *DB) EntDriver() string {
	return db.driverName
}

// MigrateUp applies all pending migrations.
func (db *DB) MigrateUp(ctx context.Context) error {
	// For Ent-based migrations, we'll use Ent's migrate package.
	// This is a placeholder that will be replaced when Ent schema is defined.
	_ = ctx
	return nil
}

// MigrateDown rolls back one migration.
func (db *DB) MigrateDown(ctx context.Context) error {
	_ = ctx
	return nil
}

// MigrateStatus returns current migration version.
func (db *DB) MigrateStatus(ctx context.Context) (version int64, dirty bool, err error) {
	_ = ctx
	return 0, false, nil
}

// WithTx executes fn inside a transaction.
func (db *DB) WithTx(ctx context.Context, fn func(*sql.Tx) error) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}

	if err := fn(tx); err != nil {
		if rbErr := tx.Rollback(); rbErr != nil {
			return fmt.Errorf("rollback failed: %v (original: %w)", rbErr, err)
		}
		return err
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit tx: %w", err)
	}
	return nil
}
