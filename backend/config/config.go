package config

import (
	"fmt"
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	App      AppConfig      `mapstructure:"app"`
	JWT      JWTConfig      `mapstructure:"jwt"`
	DB       DBConfig       `mapstructure:"db"`
	Redis    RedisConfig    `mapstructure:"redis"`
	Meili    MeiliConfig    `mapstructure:"meili"`
	MinIO    MinIOConfig    `mapstructure:"minio"`
	Razorpay RazorpayConfig `mapstructure:"razorpay"`
	Firebase FirebaseConfig `mapstructure:"firebase"`
	SMS      SMSConfig      `mapstructure:"sms"`
}

type AppConfig struct {
	Env  string `mapstructure:"env"`
	Port int    `mapstructure:"port"`
	Name string `mapstructure:"name"`
}

type JWTConfig struct {
	AccessSecret  string        `mapstructure:"access_secret"`
	RefreshSecret string        `mapstructure:"refresh_secret"`
	AccessExpiry  time.Duration `mapstructure:"access_expiry"`
	RefreshExpiry time.Duration `mapstructure:"refresh_expiry"`
}

type DBConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	Name     string `mapstructure:"name"`
	SSLMode  string `mapstructure:"sslmode"`
}

func (c DBConfig) DSN() string {
	return fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		c.Host, c.Port, c.User, c.Password, c.Name, c.SSLMode)
}

type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
	UseTLS   bool   `mapstructure:"use_tls"`
}

func (c RedisConfig) Addr() string {
	return fmt.Sprintf("%s:%d", c.Host, c.Port)
}

type MeiliConfig struct {
	Host      string `mapstructure:"host"`
	MasterKey string `mapstructure:"master_key"`
}

type MinIOConfig struct {
	Endpoint  string `mapstructure:"endpoint"`
	AccessKey string `mapstructure:"access_key"`
	SecretKey string `mapstructure:"secret_key"`
	Bucket    string `mapstructure:"bucket"`
	UseSSL    bool   `mapstructure:"use_ssl"`
	Region    string `mapstructure:"region"`
}

type RazorpayConfig struct {
	KeyID     string `mapstructure:"key_id"`
	KeySecret string `mapstructure:"key_secret"`
}

type FirebaseConfig struct {
	CredentialsFile string `mapstructure:"credentials_file"`
}

type SMSConfig struct {
	Provider string `mapstructure:"provider"`
	APIKey   string `mapstructure:"api_key"`
	SenderID string `mapstructure:"sender_id"`
}

func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.AddConfigPath(".")

	// Environment variable overrides
	viper.SetEnvPrefix("")
	viper.AutomaticEnv()

	// Bind env vars to config keys
	bindings := map[string]string{
		"app.env":                  "APP_ENV",
		"app.port":                 "APP_PORT",
		"app.name":                 "APP_NAME",
		"jwt.access_secret":        "JWT_ACCESS_SECRET",
		"jwt.refresh_secret":       "JWT_REFRESH_SECRET",
		"jwt.access_expiry":        "JWT_ACCESS_EXPIRY",
		"jwt.refresh_expiry":       "JWT_REFRESH_EXPIRY",
		"db.host":                  "DB_HOST",
		"db.port":                  "DB_PORT",
		"db.user":                  "DB_USER",
		"db.password":              "DB_PASSWORD",
		"db.name":                  "DB_NAME",
		"db.sslmode":               "DB_SSLMODE",
		"redis.host":               "REDIS_HOST",
		"redis.port":               "REDIS_PORT",
		"redis.password":           "REDIS_PASSWORD",
		"redis.db":                 "REDIS_DB",
		"redis.use_tls":            "REDIS_USE_TLS",
		"meili.host":               "MEILI_HOST",
		"meili.master_key":         "MEILI_MASTER_KEY",
		"minio.endpoint":           "MINIO_ENDPOINT",
		"minio.access_key":         "MINIO_ACCESS_KEY",
		"minio.secret_key":         "MINIO_SECRET_KEY",
		"minio.bucket":             "MINIO_BUCKET",
		"minio.use_ssl":            "MINIO_USE_SSL",
		"minio.region":             "MINIO_REGION",
		"razorpay.key_id":          "RAZORPAY_KEY_ID",
		"razorpay.key_secret":      "RAZORPAY_KEY_SECRET",
		"firebase.credentials_file": "FIREBASE_CREDENTIALS_FILE",
		"sms.provider":             "SMS_PROVIDER",
		"sms.api_key":              "SMS_API_KEY",
		"sms.sender_id":            "SMS_SENDER_ID",
	}

	for key, env := range bindings {
		_ = viper.BindEnv(key, env)
	}

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("reading config: %w", err)
		}
	}

	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("unmarshalling config: %w", err)
	}

	return &cfg, nil
}
