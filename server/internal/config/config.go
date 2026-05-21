package config

import (
	"fmt"
	"strings"

	"github.com/spf13/viper"
)

type Config struct {
	ServiceName  string `mapstructure:"SERVICE_NAME"`
	Env          string `mapstructure:"ENV"`
	Version      string `mapstructure:"VERSION"`
	LogLevel     string `mapstructure:"LOG_LEVEL"`
	HTTPPort     int    `mapstructure:"HTTP_PORT"`
	DatabaseURL  string `mapstructure:"DATABASE_URL"`
	RedisAddr    string `mapstructure:"REDIS_ADDR"`
	RedisDB      int    `mapstructure:"REDIS_DB"`
	RedisPassword string `mapstructure:"REDIS_PASSWORD"`
	KafkaBrokers []string `mapstructure:"KAFKA_BROKERS"`
	StorageEndpoint  string `mapstructure:"STORAGE_ENDPOINT"`
	StorageAccessKey string `mapstructure:"STORAGE_ACCESS_KEY"`
	StorageSecretKey string `mapstructure:"STORAGE_SECRET_KEY"`
	StorageBucket    string `mapstructure:"STORAGE_BUCKET"`
	StorageUseSSL    bool   `mapstructure:"STORAGE_USE_SSL"`
	JWTSecret        string `mapstructure:"JWT_SECRET"`
	JWTAccessTTL     int    `mapstructure:"JWT_ACCESS_TTL_MINUTES"`
	JWTRefreshTTL    int    `mapstructure:"JWT_REFRESH_TTL_DAYS"`
	OTLPEndpoint     string `mapstructure:"OTLP_ENDPOINT"`
	CORSOrigins      []string `mapstructure:"CORS_ORIGINS"`
	RateLimitRPS   int    `mapstructure:"RATE_LIMIT_RPS"`
	RateLimitBurst int    `mapstructure:"RATE_LIMIT_BURST"`
}

func Load(path string) (*Config, error) {
	v := viper.New()
	v.SetConfigFile(".env")
	v.SetConfigType("env")
	v.AddConfigPath(path)

	setDefaults(v)
	bindEnvs(v)

	if err := v.ReadInConfig(); err != nil {
		// .env file is optional, env vars take precedence
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("read config: %w", err)
		}
	}

	var cfg Config
	if err := v.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("unmarshal config: %w", err)
	}

	if cfg.ServiceName == "" {
		cfg.ServiceName = "social-server"
	}
	if cfg.Env == "" {
		cfg.Env = "development"
	}
	if cfg.Version == "" {
		cfg.Version = "dev"
	}
	if cfg.LogLevel == "" {
		cfg.LogLevel = "info"
	}
	if cfg.HTTPPort == 0 {
		cfg.HTTPPort = 8080
	}
	if cfg.JWTAccessTTL == 0 {
		cfg.JWTAccessTTL = 15
	}
	if cfg.JWTRefreshTTL == 0 {
		cfg.JWTRefreshTTL = 7
	}
	if cfg.RateLimitRPS == 0 {
		cfg.RateLimitRPS = 100
	}
	if cfg.RateLimitBurst == 0 {
		cfg.RateLimitBurst = 200
	}

	return &cfg, nil
}

func setDefaults(v *viper.Viper) {
	v.SetDefault("SERVICE_NAME", "social-server")
	v.SetDefault("ENV", "development")
	v.SetDefault("VERSION", "dev")
	v.SetDefault("LOG_LEVEL", "info")
	v.SetDefault("HTTP_PORT", 8080)
	v.SetDefault("REDIS_ADDR", "localhost:6379")
	v.SetDefault("REDIS_DB", 0)
	v.SetDefault("JWT_ACCESS_TTL_MINUTES", 15)
	v.SetDefault("JWT_REFRESH_TTL_DAYS", 7)
	v.SetDefault("RATE_LIMIT_RPS", 100)
	v.SetDefault("RATE_LIMIT_BURST", 200)
}

func bindEnvs(v *viper.Viper) {
	v.BindEnv("SERVICE_NAME")
	v.BindEnv("ENV")
	v.BindEnv("VERSION")
	v.BindEnv("LOG_LEVEL")
	v.BindEnv("HTTP_PORT")
	v.BindEnv("DATABASE_URL")
	v.BindEnv("REDIS_ADDR")
	v.BindEnv("REDIS_DB")
	v.BindEnv("REDIS_PASSWORD")
	v.BindEnv("KAFKA_BROKERS")
	v.BindEnv("STORAGE_ENDPOINT")
	v.BindEnv("STORAGE_ACCESS_KEY")
	v.BindEnv("STORAGE_SECRET_KEY")
	v.BindEnv("STORAGE_BUCKET")
	v.BindEnv("STORAGE_USE_SSL")
	v.BindEnv("JWT_SECRET")
	v.BindEnv("JWT_ACCESS_TTL_MINUTES")
	v.BindEnv("JWT_REFRESH_TTL_DAYS")
	v.BindEnv("OTLP_ENDPOINT")
	v.BindEnv("CORS_ORIGINS")
	v.BindEnv("RATE_LIMIT_RPS")
	v.BindEnv("RATE_LIMIT_BURST")

}

func (c *Config) IsDevelopment() bool {
	return strings.ToLower(c.Env) == "development"
}

func (c *Config) IsProduction() bool {
	return strings.ToLower(c.Env) == "production"
}
