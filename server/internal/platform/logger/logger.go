package logger

import (
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

type Logger struct {
	*zap.Logger
}

type Field = zap.Field

func New(level, service, env string) (*Logger, error) {
	var cfg zap.Config
	if isDev(env) {
		cfg = zap.NewDevelopmentConfig()
		cfg.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	} else {
		cfg = zap.NewProductionConfig()
		cfg.EncoderConfig.TimeKey = "timestamp"
		cfg.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	}

	l, err := zap.ParseAtomicLevel(level)
	if err != nil {
		return nil, err
	}
	cfg.Level = l

	logger, err := cfg.Build(
		zap.Fields(
			zap.String("service", service),
			zap.String("env", env),
		),
	)
	if err != nil {
		return nil, err
	}

	return &Logger{logger}, nil
}

func isDev(env string) bool {
	return env == "development" || env == "dev" || env == "local"
}

func (l *Logger) With(fields ...Field) *Logger {
	return &Logger{l.Logger.With(fields...)}
}

func (l *Logger) Sync() error {
	return l.Logger.Sync()
}

func String(key, val string) Field   { return zap.String(key, val) }
func Int(key string, val int) Field  { return zap.Int(key, val) }
func Int64(key string, val int64) Field { return zap.Int64(key, val) }
func Bool(key string, val bool) Field { return zap.Bool(key, val) }
func Error(err error) Field           { return zap.Error(err) }
func Any(key string, val any) Field   { return zap.Any(key, val) }
func Duration(key string, val any) Field { return zap.Any(key, val) }
func UUID(key string, val any) Field  { return zap.Any(key, val) }
