package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"social-server/internal/bootstrap"
	"social-server/internal/config"
	"social-server/internal/platform/logger"
)

func main() {
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

	worker, err := bootstrap.NewWorker(cfg, log)
	if err != nil {
		log.Fatal("failed to bootstrap worker", logger.Error(err))
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go func() {
		log.Info("worker starting")
		if err := worker.Run(ctx); err != nil {
			log.Fatal("worker failed", logger.Error(err))
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("shutting down worker")

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	if err := worker.Close(shutdownCtx); err != nil {
		log.Error("worker forced to shutdown", logger.Error(err))
	}

	log.Info("worker exited")
}
