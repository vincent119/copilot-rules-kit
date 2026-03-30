---
name: go-ci-tooling
description: |
  Go CI/CD 工具配置：Makefile、golangci-lint、GitHub Actions、Docker、測試覆蓋率、
  自動化流程、Pre-commit Hook。

  **適用場景**：設計 CI/CD Pipeline、配置 golangci-lint、撰寫 Makefile、
  Docker 多階段建置、測試自動化、程式碼品質檢查、GitHub Actions。
keywords:
  - ci/cd
  - makefile
  - golangci-lint
  - github actions
  - docker
  - pre-commit
  - test coverage
  - lint
  - build automation
  - continuous integration
  - pipeline
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go CI/CD 與工具配置規範

> **相關 Skills**：本規範建議搭配 `go-testing-advanced`（測試）與 `go-graceful-shutdown`（建置）

---

## Makefile

### 基本結構

```makefile
.PHONY: help
help: ## 顯示此說明
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# 變數
BINARY_NAME=myapp
VERSION?=dev
COMMIT=$(shell git rev-parse --short HEAD)
BUILD_TIME=$(shell date -u '+%Y-%m-%d_%H:%M:%S')

# Go 變數
GOBASE=$(shell pwd)
GOBIN=$(GOBASE)/bin
GOCMD=go
GOBUILD=$(GOCMD) build
GOTEST=$(GOCMD) test
GOMOD=$(GOCMD) mod

# Ldflags（注入版本資訊）
LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.Commit=$(COMMIT) -X main.BuildTime=$(BUILD_TIME)"

.PHONY: build
build: ## 建置二進位檔
	@echo "Building $(BINARY_NAME)..."
	$(GOBUILD) $(LDFLAGS) -o $(GOBIN)/$(BINARY_NAME) ./cmd/server

.PHONY: test
test: ## 執行單元測試
	$(GOTEST) -v -race -coverprofile=coverage.out ./...

.PHONY: test-coverage
test-coverage: test ## 測試覆蓋率報告
	$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

.PHONY: lint
lint: ## 執行 Linter
	@which golangci-lint > /dev/null || (echo "Installing golangci-lint..." && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest)
	golangci-lint run --timeout=5m

.PHONY: fmt
fmt: ## 格式化程式碼
	gofmt -s -w .
	goimports -w .

.PHONY: tidy
tidy: ## 整理依賴
	$(GOMOD) tidy
	$(GOMOD) verify

.PHONY: clean
clean: ## 清理建置產物
	@echo "Cleaning..."
	@rm -rf $(GOBIN)
	@rm -f coverage.out coverage.html

.PHONY: docker-build
docker-build: ## 建置 Docker Image
	docker build -t $(BINARY_NAME):$(VERSION) .

.PHONY: run
run: build ## 執行應用程式
	$(GOBIN)/$(BINARY_NAME)

.PHONY: install-tools
install-tools: ## 安裝開發工具
	@echo "Installing development tools..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install golang.org/x/tools/cmd/goimports@latest
	go install go.uber.org/mock/mockgen@latest

.PHONY: generate
generate: ## 執行 go generate
	go generate ./...

.PHONY: all
all: tidy fmt lint test build ## 執行所有檢查與建置
```

### 進階：依賴追蹤

```makefile
# 只在原始碼變更時重新建置
$(GOBIN)/$(BINARY_NAME): $(shell find . -name '*.go')
	@echo "Source changed, rebuilding..."
	$(GOBUILD) $(LDFLAGS) -o $@ ./cmd/server

.PHONY: build
build: $(GOBIN)/$(BINARY_NAME)
```

---

## golangci-lint 配置

### .golangci.yml

```yaml
run:
  timeout: 5m
  tests: true
  skip-dirs:
    - mocks
    - vendor
  skip-files:
    - ".*\\.pb\\.go$"
    - ".*_gen\\.go$"

linters:
  enable:
    - errcheck       # 檢查未處理的錯誤
    - gosimple       # 簡化程式碼
    - govet          # Go vet
    - ineffassign    # 檢測無效的賦值
    - staticcheck    # 靜態分析
    - typecheck      # 型別檢查
    - unused         # 檢查未使用的變數
    - gofmt          # 格式檢查
    - goimports      # Import 排序
    - misspell       # 拼寫檢查
    - gocritic       # 程式碼評論
    - godox          # 檢查 TODO/FIXME
    - revive         # 取代 golint
    - cyclop         # 循環複雜度
    - dupl           # 重複程式碼檢測
    - gosec          # 安全性檢查
    - gocognit       # 認知複雜度
    - nestif         # 巢狀 if 檢查
    - prealloc       # Slice 預分配
    - gci            # Import 排序
    - lll            # 行長度檢查

linters-settings:
  errcheck:
    check-blank: true
    check-type-assertions: true

  govet:
    check-shadowing: true

  gocognit:
    min-complexity: 15

  cyclop:
    max-complexity: 15

  lll:
    line-length: 120

  revive:
    rules:
      - name: exported
        severity: warning
      - name: unexported-return
        severity: warning
      - name: indent-error-flow
        severity: warning

  gosec:
    excludes:
      - G104  # 允許部分未檢查的錯誤（需有註釋）
      - G304  # 允許檔案路徑來自變數

issues:
  exclude-rules:
    # 測試檔案放寬限制
    - path: _test\.go
      linters:
        - dupl
        - gosec
        - gocognit
        - cyclop

    # Mock 檔案不檢查
    - path: mock/
      linters:
        - all

  max-issues-per-linter: 50
  max-same-issues: 3
```

---

## GitHub Actions

### .github/workflows/ci.yml

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
          cache: true

      - name: golangci-lint
        uses: golangci/golangci-lint-action@v3
        with:
          version: latest
          args: --timeout=5m

  test:
    name: Test
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
          cache: true

      - name: Run tests
        run: |
          go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/testdb?sslmode=disable
          REDIS_URL: redis://localhost:6379

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.out
          flags: unittests
          fail_ci_if_error: true

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
          cache: true

      - name: Build
        run: make build

      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: binary
          path: bin/myapp
```

### .github/workflows/release.yml

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    name: Release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Run GoReleaser
        uses: goreleaser/goreleaser-action@v4
        with:
          version: latest
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Docker

### Dockerfile（多階段建置）

```dockerfile
# Stage 1: Builder
FROM golang:1.21-alpine AS builder

# 安裝必要工具
RUN apk add --no-cache git make

WORKDIR /app

# 複製 go.mod 和 go.sum（利用快取）
COPY go.mod go.sum ./
RUN go mod download

# 複製原始碼
COPY . .

# 建置
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o bin/myapp ./cmd/server

# Stage 2: Runtime
FROM alpine:latest

# 安裝 CA 憑證與時區資料
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# 複製二進位檔
COPY --from=builder /app/bin/myapp .

# 複製設定檔（可選）
COPY ./configs ./configs

# 建立非 root 使用者
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

ENTRYPOINT ["./myapp"]
```

### .dockerignore

```
# Git
.git
.gitignore

# IDE
.vscode
.idea
*.swp

# Build artifacts
bin/
coverage.out
coverage.html

# Docs
docs/
*.md

# Tests
*_test.go

# Temp files
tmp/
*.log
```

---

## Pre-commit Hook

### .pre-commit-config.yaml

```yaml
repos:
  - repo: https://github.com/golangci/golangci-lint
    rev: v1.54.2
    hooks:
      - id: golangci-lint
        args: ['--timeout=5m']

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
```

### 安裝

```bash
# 安裝 pre-commit
pip install pre-commit

# 安裝 Hooks
pre-commit install

# 手動執行（所有檔案）
pre-commit run --all-files
```

---

## 測試覆蓋率

### Coverage Badge（README）

```markdown
[![codecov](https://codecov.io/gh/username/repo/branch/main/graph/badge.svg)](https://codecov.io/gh/username/repo)
```

### 本地生成報告

```bash
# HTML 報告
make test-coverage
open coverage.html

# 終端顯示
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out

# 按套件統計
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out | grep -E '^total:'
```

---

## 檢查清單

**Makefile**
- [ ] 包含 `help` 目標（自動生成說明）
- [ ] 定義常用任務（build、test、lint、clean）
- [ ] 注入版本資訊到二進位檔（Ldflags）
- [ ] 支援依賴追蹤（原始碼變更時重建）

**golangci-lint**
- [ ] 配置 `.golangci.yml`
- [ ] 啟用關鍵 Linter（errcheck、gosimple、staticcheck、gosec）
- [ ] 設定合理的超時時間（5 分鐘）
- [ ] 排除生成的程式碼（*.pb.go、mock/）

**GitHub Actions**
- [ ] CI Pipeline 包含 lint、test、build
- [ ] 整合測試使用 Service Containers（Postgres、Redis）
- [ ] 上傳測試覆蓋率到 Codecov
- [ ] Release 自動化（GoReleaser）

**Docker**
- [ ] 使用多階段建置（減少映像大小）
- [ ] 設定非 root 使用者
- [ ] 利用建置快取（分離 go mod download）
- [ ] 配置 `.dockerignore`

**Pre-commit**
- [ ] 安裝 `.pre-commit-config.yaml`
- [ ] 執行 golangci-lint
- [ ] 檢查檔案格式（trailing whitespace、EOF）
- [ ] 防止提交大檔案

**測試覆蓋率**
- [ ] 目標覆蓋率 ≥ 80%
- [ ] CI 自動檢查覆蓋率
- [ ] 重要邏輯 100% 覆蓋
- [ ] 生成 HTML 報告供查看
