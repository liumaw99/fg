//go:build wireinject
// +build wireinject

package container

import (
	"github.com/google/wire"
	"social-server/internal/bootstrap"
	"social-server/internal/config"
	"social-server/internal/platform/logger"
)

// ProvideAPI wires the API application.
func ProvideAPI(cfg *config.Config, log *logger.Logger) (*bootstrap.App, error) {
	wire.Build(bootstrap.NewAPI)
	return nil, nil
}

// ProvideWorker wires the Worker application.
func ProvideWorker(cfg *config.Config, log *logger.Logger) (*bootstrap.Worker, error) {
	wire.Build(bootstrap.NewWorker)
	return nil, nil
}
