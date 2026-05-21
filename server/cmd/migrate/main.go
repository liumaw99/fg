package main

import (
	"context"
	"fmt"
	"os"

	"social-server/internal/config"
	"social-server/internal/platform/database"
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

	db, err := database.New(cfg.DatabaseURL)
	if err != nil {
		log.Fatal("failed to connect database", logger.Error(err))
	}
	defer db.Close()

	switch action {
	case "up":
		if err := db.MigrateUp(ctx); err != nil {
			log.Fatal("failed to migrate up", logger.Error(err))
		}
		log.Info("migration up completed")
	case "down":
		if err := db.MigrateDown(ctx); err != nil {
			log.Fatal("failed to migrate down", logger.Error(err))
		}
		log.Info("migration down completed")
	case "status":
		version, dirty, err := db.MigrateStatus(ctx)
		if err != nil {
			log.Fatal("failed to get migration status", logger.Error(err))
		}
		log.Info("migration status", logger.Int64("version", version), logger.Bool("dirty", dirty))
	default:
		fmt.Printf("unknown action: %s\n", action)
		os.Exit(1)
	}
}
