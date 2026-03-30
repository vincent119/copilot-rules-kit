---
name: go-database
description: |
  Go Database Migration 與 ORM 規範：Migration 工具選擇（golang-migrate/goose）、
  命名慣例、版本控制、CI/CD 整合、最佳實務（pt-online-schema-change, gh-ost）。

  **適用場景**：設計資料庫遷移策略、實作 Migration、管理 Schema 版本、處理大型表變更、
  配置 CI/CD Pipeline、避免 AutoMigrate、GORM 使用規範。
keywords:
  - database migration
  - golang-migrate
  - goose
  - schema
  - version control
  - pt-online-schema-change
  - gh-ost
  - ci/cd
  - migrations
  - up/down
  - rollback
  - gorm
  - orm
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go Database Migration 與 ORM 規範

> **相關 Skills**：本規範建議搭配 `go-ddd`（Repository Pattern）

---

## Migration 工具選擇

### 推薦工具

1. **[golang-migrate/migrate](https://github.com/golang-migrate/migrate)** - 最流行、支援多種資料庫
2. **[pressly/goose](https://github.com/pressly/goose)** - 支援 Go 與 SQL 混合 Migration

**原則**：
- 選擇後**全專案統一**，禁止混用
- **禁止**使用 `gorm.AutoMigrate()` 於生產環境（僅限本地開發）

### 安裝

```bash
# golang-migrate
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# goose
go install github.com/pressly/goose/v3/cmd/goose@latest
```

---

## 命名慣例

### 檔案結構

```
migrations/
├── 20260108120000_create_users_table.up.sql
├── 20260108120000_create_users_table.down.sql
├── 20260108130000_add_email_index.up.sql
├── 20260108130000_add_email_index.down.sql
├── 20260109100000_alter_orders_add_status.up.sql
└── 20260109100000_alter_orders_add_status.down.sql
```

### 命名格式

**格式**：`YYYYMMDDHHMMSS_<description>.<up|down>.sql`

**規則**：
- 時間戳：使用 UTC 時間，確保唯一性與排序
- 描述：使用**蛇形命名法**（snake_case），簡潔描述變更
- 必須成對：每個 `.up.sql` 都有對應的 `.down.sql`

**範例**：
```bash
# 正確
20260108120000_create_users_table.up.sql
20260108120000_create_users_table.down.sql

# 錯誤
2026-01-08-CreateUsers.sql          # 格式錯誤
create_users.up.sql                 # 缺少時間戳
20260108120000_AddUserEmail.up.sql  # 應使用 snake_case
```

---

## Migration 內容範例

### CREATE TABLE

**`20260108120000_create_users_table.up.sql`**：
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

**`20260108120000_create_users_table.down.sql`**：
```sql
DROP INDEX IF EXISTS idx_users_email;
DROP TABLE IF EXISTS users;
```

### ALTER TABLE

**`20260109100000_alter_orders_add_status.up.sql`**：
```sql
-- 新增欄位（帶預設值避免 NULL 問題）
ALTER TABLE orders
ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending';

-- 新增索引
CREATE INDEX idx_orders_status ON orders(status);
```

**`20260109100000_alter_orders_add_status.down.sql`**：
```sql
DROP INDEX IF EXISTS idx_orders_status;

ALTER TABLE orders
DROP COLUMN IF EXISTS status;
```

---

## 版本控制

### 規範

1. Migration 檔案**必須**納入 Git
2. **禁止**修改已執行的 migration（新增新檔案修正）
3. 復原（down）**必須**與 up 對應，確保可回退
4. 團隊共享：所有開發者使用相同的 migration 版本

### 驗證 Migration 一致性

**錯誤做法**：
```sql
-- ❌ 修改已執行的 migration
-- 20260108120000_create_users_table.up.sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    -- 後來加上的欄位（不應修改已執行的 migration）
    phone VARCHAR(20) NOT NULL
);
```

**正確做法**：
```sql
-- ✅ 新增一個新的 migration
-- 20260110150000_add_phone_to_users.up.sql
ALTER TABLE users
ADD COLUMN phone VARCHAR(20);
```

---

## CI/CD 整合

### 執行時機

**原則**：
- Migration 應在**應用啟動前**執行（init container 或 pre-deploy hook）
- **禁止**在應用程式 `main()` 中執行 migration（避免多副本競爭）

### Kubernetes 範例（Init Container）

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      initContainers:
        - name: db-migration
          image: myapp:latest
          command:
            - /bin/sh
            - -c
            - |
              migrate -path /migrations \
                      -database "${DATABASE_URL}" \
                      up
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: url
      containers:
        - name: app
          image: myapp:latest
          # ...
```

### GitHub Actions 範例

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run migrations
        run: |
          migrate -path ./migrations \
                  -database "${{ secrets.DATABASE_URL }}" \
                  up

      - name: Deploy application
        run: |
          # ...部署應用
```

---

## 最佳實務

### 大型表變更

**問題**：ALTER TABLE 在大型表（百萬行級別）會鎖表，影響線上服務。

**解決方案**：使用 **pt-online-schema-change** 或 **gh-ost**

#### pt-online-schema-change（Percona Toolkit）

```bash
# 範例：新增欄位到大型表
pt-online-schema-change \
  --alter "ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending'" \
  --execute \
  D=mydb,t=orders,h=localhost,u=root,p=password
```

**特性**：
- 建立影子表（shadow table）
- 透過 trigger 同步資料
- 最後瞬間切換表名（最小化鎖表時間）

#### gh-ost（GitHub 開發）

```bash
# 範例
gh-ost \
  --user="root" \
  --password="password" \
  --host="localhost" \
  --database="mydb" \
  --table="orders" \
  --alter="ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending'" \
  --execute
```

**特性**：
- 無 trigger 設計（透過 binlog 同步）
- 可即時暫停/繼續
- 適合 MySQL/MariaDB

### 新增 NOT NULL 欄位

**問題**：直接新增 NOT NULL 欄位會失敗（舊資料無值）。

**正確步驟**：
1. 新增欄位（允許 NULL 或給預設值）
2. 回填資料
3. 改為 NOT NULL

**Migration 範例**：

**Step 1**：`20260110100000_add_status_nullable.up.sql`
```sql
ALTER TABLE orders
ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
```

**Step 2**：`20260110110000_backfill_status.up.sql`
```sql
-- 回填舊資料
UPDATE orders
SET status = 'pending'
WHERE status IS NULL;
```

**Step 3**：`20260110120000_make_status_not_null.up.sql`
```sql
ALTER TABLE orders
ALTER COLUMN status SET NOT NULL;
```

### Migration 測試

**本地測試流程**：
```bash
# 1. 執行 up
migrate -path ./migrations -database "postgres://localhost/testdb" up

# 2. 驗證 Schema
psql testdb -c "\d orders"

# 3. 執行 down（測試回退）
migrate -path ./migrations -database "postgres://localhost/testdb" down 1

# 4. 再次執行 up（確保可重複執行）
migrate -path ./migrations -database "postgres://localhost/testdb" up
```

---

## GORM 使用規範

### 禁止 AutoMigrate 於生產環境

```go
// ❌ 禁止：生產環境使用 AutoMigrate
func main() {
    db, _ := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    db.AutoMigrate(&User{}, &Order{})  // 不可預測、缺少版本控制
}

// ✅ 正確：僅在本地開發使用
func setupTestDB(t *testing.T) *gorm.DB {
    db, _ := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
    db.AutoMigrate(&User{}, &Order{})  // 測試環境可用
    return db
}
```

### Repository 層隔離 GORM 實作

**分離 Domain Entity 與 GORM Model**：

```go
// internal/order/domain/order.go (Domain Entity)
package domain

type Order struct {
    id         string
    customerID string
    amount     float64
}

// internal/order/infra/order_model.go (GORM Model)
package infra

type OrderModel struct {
    ID         string    `gorm:"type:uuid;primaryKey"`
    CustomerID string    `gorm:"type:uuid;not null"`
    Amount     float64   `gorm:"type:decimal(10,2);not null"`
    CreatedAt  time.Time
    UpdatedAt  time.Time
}

func (OrderModel) TableName() string {
    return "orders"
}

// 轉換函式
func toDomainOrder(m *OrderModel) *domain.Order {
    return &domain.Order{
        id:         m.ID,
        customerID: m.CustomerID,
        amount:     m.Amount,
    }
}

func toGORMModel(o *domain.Order) *OrderModel {
    return &OrderModel{
        ID:         o.ID(),
        CustomerID: o.CustomerID(),
        Amount:     o.Amount(),
    }
}
```

---

## 檢查清單

**Migration 檔案**
- [ ] 使用統一的 Migration 工具（golang-migrate 或 goose）
- [ ] 命名遵循 `YYYYMMDDHHMMSS_description.up/down.sql`
- [ ] 每個 `.up.sql` 都有對應的 `.down.sql`
- [ ] 描述使用 snake_case
- [ ] Migration 檔案納入 Git

**版本控制**
- [ ] 不修改已執行的 migration
- [ ] 新需求使用新 migration 修正
- [ ] down migration 能正確回退

**CI/CD**
- [ ] Migration 在應用啟動前執行（init container）
- [ ] 不在應用程式 `main()` 中執行 migration
- [ ] CI 階段驗證 migration 可執行

**最佳實務**
- [ ] 大型表使用 pt-online-schema-change 或 gh-ost
- [ ] 新增 NOT NULL 欄位分步驟執行（先 nullable → 回填 → not null）
- [ ] 本地測試 up/down 流程
- [ ] 生產環境禁用 `gorm.AutoMigrate()`
- [ ] Domain Entity 與 GORM Model 分離
