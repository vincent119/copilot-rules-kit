---
name: test-coverage
description: Run tests with coverage reports for Go, Python, and Node.js projects.
---

# Test Coverage

Generate test coverage reports across multiple languages.

## Go

```bash
# Run tests with coverage
go test -v -coverprofile=coverage.out ./...

# Terminal summary
go tool cover -func=coverage.out

# HTML report
go tool cover -html=coverage.out -o coverage.html
```

## Python

Requires `pytest` and `pytest-cov`:

```bash
pytest --cov=. --cov-report=term --cov-report=html
```

HTML report: `htmlcov/index.html`

## Node.js

Using Jest:

```bash
npm test -- --coverage
```

HTML report: `coverage/lcov-report/index.html`

## Coverage Goals

| Metric | Target |
|--------|--------|
| Overall | >80% |
| Critical paths | >90% |
| New code | 100% |

**Cleanup**: Remove `coverage.out`, `htmlcov/`, `coverage/` after review.
