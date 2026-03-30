---
name: go-configuration
description: |
  Go 設定管理最佳實務：Viper 配置、環境變數優先級、Secrets 處理、設定驗證、
  動態重載、多環境管理、12-Factor App 原則。

  **適用場景**：使用 Viper、環境變數管理、Secrets 處理、設定驗證、動態重載設定、
  多環境配置（dev/staging/prod）、Kubernetes ConfigMap/Secret 整合。
keywords:
  - configuration
  - viper
  - environment variables
  - secrets
  - validation
  - env vars
  - config reload
  - 12-factor
  - configmap
  - kubernetes config
  - dotenv
  - yaml config
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go 設定管理規範

> **相關 Skills**：本規範建議搭配 `go-observability`（日誌配置）與 `go-graceful-shutdown`（動態重載）

---

## 12-Factor App 原則

### 核心原則

1. **設定與程式碼分離**：不將設定硬編碼
2. **環境變數優先**：使用環境變數覆蓋預設設定
3. **Secrets 管理**：敏感資訊不進入版本控制
4. **多環境支援**：dev/staging/prod 使用相同程式碼

### 優先級（從高到低）

```
環境變數 > 設定檔 > 預設值
```

---

## Viper 基本使用

### 安裝

```bash
go get github.com/spf13/viper
```

### 基本配置

```go
package config

import (
    "fmt"
    "github.com/spf13/viper"
)

type Config struct {
    Server   ServerConfig   `mapstructure:"server"`
    Database DatabaseConfig `mapstructure:"database"`
    Redis    RedisConfig    `mapstructure:"redis"`
    Log      LogConfig      `mapstructure:"log"`
}

type ServerConfig struct {
    Host string `mapstructure:"host"`
    Port int    `mapstructure:"port"`
}

type DatabaseConfig struct {
    Host     string `mapstructure:"host"`
    Port     int    `mapstructure:"port"`
    User     string `mapstructure:"user"`
    Password string `mapstructure:"password"`  // 敏感資訊
    Database string `mapstructure:"database"`
}

type RedisConfig struct {
    Host     string `mapstructure:"host"`
    Port     int    `mapstructure:"port"`
    Password string `mapstructure:"password"`
}

type LogConfig struct {
    Level  string `mapstructure:"level"`
    Format string `mapstructure:"format"`  // json or console
}

func Load() (*Config, error) {
    // 1. 設定檔路徑
    viper.SetConfigName("config")         // config.yaml
    viper.SetConfigType("yaml")
    viper.AddConfigPath(".")              // 當前目錄
    viper.AddConfigPath("./configs")      // ./configs 目錄
    viper.AddConfigPath("/etc/myapp")     // 系統目錄

    // 2. 預設值
    setDefaults()

    // 3. 讀取設定檔
    if err := viper.ReadInConfig(); err != nil {
        // 設定檔不存在不算錯誤（使用預設值 + 環境變數）
        if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
            return nil, fmt.Errorf("read config: %w", err)
        }
    }

    // 4. 環境變數覆蓋
    viper.AutomaticEnv()
    viper.SetEnvPrefix("MYAPP")  // 環境變數前綴：MYAPP_SERVER_PORT

    // 5. 綁定到 Struct
    var cfg Config
    if err := viper.Unmarshal(&cfg); err != nil {
        return nil, fmt.Errorf("unmarshal config: %w", err)
    }

    // 6. 驗證設定
    if err := cfg.Validate(); err != nil {
        return nil, fmt.Errorf("validate config: %w", err)
    }

    return &cfg, nil
}

func setDefaults() {
    viper.SetDefault("server.host", "0.0.0.0")
    viper.SetDefault("server.port", 8080)
    viper.SetDefault("log.level", "info")
    viper.SetDefault("log.format", "json")
}
```

### 設定檔範例（config.yaml）

```yaml
server:
  host: 0.0.0.0
  port: 8080

database:
  host: localhost
  port: 5432
  user: postgres
  password: ${DB_PASSWORD}  # 從環境變數讀取（Viper 不支援）
  database: myapp

redis:
  host: localhost
  port: 6379
  password: ""

log:
  level: info
  format: json
```

---

## 環境變數管理

### 命名慣例

```bash
# 格式：<PREFIX>_<SECTION>_<KEY>
export MYAPP_SERVER_PORT=8080
export MYAPP_DATABASE_HOST=postgres.example.com
export MYAPP_DATABASE_PASSWORD=secret123
export MYAPP_LOG_LEVEL=debug
```

### Viper 環境變數綁定

```go
import "strings"

func Load() (*Config, error) {
    // 自動替換 . 為 _
    viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
    viper.AutomaticEnv()
    viper.SetEnvPrefix("MYAPP")

    // 現在可以這樣使用：
    // MYAPP_SERVER_PORT=9000 -> viper.GetInt("server.port")

    var cfg Config
    if err := viper.Unmarshal(&cfg); err != nil {
        return nil, err
    }

    return &cfg, nil
}
```

### .env 檔案（開發環境）

```bash
# .env
MYAPP_SERVER_PORT=8080
MYAPP_DATABASE_HOST=localhost
MYAPP_DATABASE_PASSWORD=dev_password
MYAPP_LOG_LEVEL=debug
```

```go
import "github.com/joho/godotenv"

func init() {
    // 開發環境載入 .env（生產環境不需要）
    if os.Getenv("ENV") != "production" {
        _ = godotenv.Load()
    }
}
```

---

## Secrets 處理

### 原則

- **不要將 Secrets 提交到版本控制**
- **使用環境變數或 Secret Management 工具**
- **限制 Secrets 存取權限**

### 方法 1：環境變數

```go
type DatabaseConfig struct {
    Host     string `mapstructure:"host"`
    Port     int    `mapstructure:"port"`
    User     string `mapstructure:"user"`
    Password string `mapstructure:"password"`  // 從環境變數讀取
}

func main() {
    // 直接從環境變數讀取
    dbPassword := os.Getenv("DB_PASSWORD")
    if dbPassword == "" {
        log.Fatal("DB_PASSWORD not set")
    }
}
```

### 方法 2：Kubernetes Secret

```yaml
# k8s-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
type: Opaque
data:
  db-password: cGFzc3dvcmQxMjM=  # base64 編碼
```

```yaml
# deployment.yaml
env:
  - name: MYAPP_DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: myapp-secrets
        key: db-password
```

### 方法 3：AWS Secrets Manager / Vault

```go
import (
    "github.com/aws/aws-sdk-go/aws/session"
    "github.com/aws/aws-sdk-go/service/secretsmanager"
)

func LoadSecrets() (string, error) {
    sess := session.Must(session.NewSession())
    svc := secretsmanager.New(sess)

    input := &secretsmanager.GetSecretValueInput{
        SecretId: aws.String("myapp/database/password"),
    }

    result, err := svc.GetSecretValue(input)
    if err != nil {
        return "", err
    }

    return *result.SecretString, nil
}
```

---

## 設定驗證

### 使用 validator

```bash
go get github.com/go-playground/validator/v10
```

```go
import "github.com/go-playground/validator/v10"

type Config struct {
    Server   ServerConfig   `mapstructure:"server" validate:"required"`
    Database DatabaseConfig `mapstructure:"database" validate:"required"`
}

type ServerConfig struct {
    Host string `mapstructure:"host" validate:"required,hostname|ip"`
    Port int    `mapstructure:"port" validate:"required,min=1,max=65535"`
}

type DatabaseConfig struct {
    Host     string `mapstructure:"host" validate:"required"`
    Port     int    `mapstructure:"port" validate:"required,min=1,max=65535"`
    User     string `mapstructure:"user" validate:"required"`
    Password string `mapstructure:"password" validate:"required,min=8"`
    Database string `mapstructure:"database" validate:"required"`
}

func (c *Config) Validate() error {
    validate := validator.New()
    return validate.Struct(c)
}
```

### 自訂驗證邏輯

```go
func (c *Config) Validate() error {
    // 使用 validator
    validate := validator.New()
    if err := validate.Struct(c); err != nil {
        return err
    }

    // 自訂邏輯
    if c.Database.Host == "localhost" && os.Getenv("ENV") == "production" {
        return errors.New("production should not use localhost database")
    }

    if c.Log.Level != "debug" && c.Log.Level != "info" && c.Log.Level != "warn" && c.Log.Level != "error" {
        return fmt.Errorf("invalid log level: %s", c.Log.Level)
    }

    return nil
}
```

---

## 動態重載設定

### 監聽設定檔變更

```go
import "github.com/fsnotify/fsnotify"

func WatchConfig(cfg *Config) {
    viper.WatchConfig()
    viper.OnConfigChange(func(e fsnotify.Event) {
        log.Info("config file changed", zap.String("file", e.Name))

        // 重新載入設定
        var newCfg Config
        if err := viper.Unmarshal(&newCfg); err != nil {
            log.Error("failed to reload config", zap.Error(err))
            return
        }

        if err := newCfg.Validate(); err != nil {
            log.Error("invalid config after reload", zap.Error(err))
            return
        }

        // 更新設定（需要 atomic 操作）
        *cfg = newCfg
        log.Info("config reloaded successfully")
    })
}
```

### 使用 atomic.Value（安全更新）

```go
import "sync/atomic"

type ConfigHolder struct {
    cfg atomic.Value
}

func NewConfigHolder(cfg *Config) *ConfigHolder {
    holder := &ConfigHolder{}
    holder.cfg.Store(cfg)
    return holder
}

func (h *ConfigHolder) Get() *Config {
    return h.cfg.Load().(*Config)
}

func (h *ConfigHolder) Update(cfg *Config) {
    h.cfg.Store(cfg)
}

// 使用範例
func main() {
    cfg, _ := config.Load()
    holder := NewConfigHolder(cfg)

    // 監聽變更
    go func() {
        viper.WatchConfig()
        viper.OnConfigChange(func(e fsnotify.Event) {
            var newCfg Config
            if err := viper.Unmarshal(&newCfg); err != nil {
                log.Error("reload failed", zap.Error(err))
                return
            }
            holder.Update(&newCfg)
        })
    }()

    // 讀取設定（執行緒安全）
    currentCfg := holder.Get()
}
```

---

## 多環境管理

### 方法 1：環境變數指定設定檔

```go
func Load() (*Config, error) {
    env := os.Getenv("ENV")
    if env == "" {
        env = "development"
    }

    configFile := fmt.Sprintf("config.%s.yaml", env)
    viper.SetConfigName(configFile)
    viper.AddConfigPath("./configs")

    // config.development.yaml
    // config.staging.yaml
    // config.production.yaml

    if err := viper.ReadInConfig(); err != nil {
        return nil, err
    }

    // ...
}
```

### 方法 2：Base Config + Override

```go
func Load() (*Config, error) {
    // 1. 載入基礎設定
    viper.SetConfigName("config.base")
    viper.AddConfigPath("./configs")
    if err := viper.ReadInConfig(); err != nil {
        return nil, err
    }

    // 2. 載入環境特定設定（覆蓋）
    env := os.Getenv("ENV")
    if env != "" {
        viper.SetConfigName(fmt.Sprintf("config.%s", env))
        if err := viper.MergeInConfig(); err != nil {
            // 環境設定可選
            if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
                return nil, err
            }
        }
    }

    // 3. 環境變數覆蓋
    viper.AutomaticEnv()

    // ...
}
```

---

## Kubernetes ConfigMap 整合

### ConfigMap 定義

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  config.yaml: |
    server:
      host: 0.0.0.0
      port: 8080
    log:
      level: info
      format: json
```

### Deployment 掛載

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        volumeMounts:
        - name: config
          mountPath: /etc/myapp
          readOnly: true
        env:
        - name: MYAPP_DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: db-password
      volumes:
      - name: config
        configMap:
          name: myapp-config
```

### 程式碼讀取

```go
func Load() (*Config, error) {
    viper.SetConfigName("config")
    viper.SetConfigType("yaml")
    viper.AddConfigPath("/etc/myapp")  // Kubernetes 掛載路徑
    viper.AddConfigPath(".")           // 本地開發

    if err := viper.ReadInConfig(); err != nil {
        return nil, err
    }

    // 環境變數覆蓋（包含 Secret）
    viper.AutomaticEnv()

    var cfg Config
    if err := viper.Unmarshal(&cfg); err != nil {
        return nil, err
    }

    return &cfg, nil
}
```

---

## 檢查清單

**基本設定**
- [ ] 設定與程式碼分離（不硬編碼）
- [ ] 使用 Viper 管理設定
- [ ] 設定多個搜尋路徑（當前目錄、系統目錄）
- [ ] 定義合理的預設值

**環境變數**
- [ ] 環境變數優先於設定檔
- [ ] 使用統一的前綴（例如 `MYAPP_`）
- [ ] 支援 `.env` 檔案（開發環境）
- [ ] 生產環境使用環境變數

**Secrets**
- [ ] Secrets 不提交到版本控制
- [ ] 使用環境變數或 Secret Management
- [ ] 限制 Secrets 存取權限
- [ ] 定期輪替 Secrets

**驗證**
- [ ] 使用 `validator` 驗證設定
- [ ] 啟動時驗證設定（Fail Fast）
- [ ] 提供清晰的錯誤訊息
- [ ] 驗證業務邏輯規則

**多環境**
- [ ] 支援 dev/staging/prod 環境
- [ ] 環境特定設定覆蓋基礎設定
- [ ] 環境變數覆蓋所有設定
- [ ] 文件說明各環境差異

**動態重載**
- [ ] 使用 `viper.WatchConfig` 監聽變更
- [ ] 重載後重新驗證設定
- [ ] 使用 `atomic.Value` 安全更新
- [ ] 記錄重載事件

**Kubernetes**
- [ ] 使用 ConfigMap 管理設定
- [ ] 使用 Secret 管理敏感資訊
- [ ] 正確設定 `volumeMounts` 路徑
- [ ] 考慮設定變更的部署策略
