package main

import (
	"context"
	"fmt"
	"os"

	_ "github.com/lib/pq"
	"social-server/internal/config"
	"social-server/internal/ent"
	"social-server/internal/ent/migrate"
	"social-server/internal/platform/logger"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("usage: migrate [up|down|status]")
		os.Exit(1)
	}

	action := os.Args[1]

	cfg, err := config.Load(".")
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to load config: %v\n", err)
		os.Exit(1)
	}

	log, err := logger.New(cfg.LogLevel, cfg.ServiceName, cfg.Env)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create logger: %v\n", err)
		os.Exit(1)
	}
	defer log.Sync()

	ctx := context.Background()

	client, err := ent.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		log.Fatal("failed to connect database", logger.Error(err))
	}
	defer client.Close()

	switch action {
	case "up":
		if err := client.Schema.Create(ctx, migrate.WithDropIndex(true), migrate.WithDropColumn(true)); err != nil {
			log.Fatal("failed to migrate up", logger.Error(err))
		}
		log.Info("migration up completed")
	case "down":
		log.Info("migrate down not supported with ent auto-migration, use manual rollback")
	case "status":
		log.Info("ent auto-migration: schema will be synchronized on next 'up' run")
	default:
		fmt.Printf("unknown action: %s\n", action)
		os.Exit(1)
	}
}
