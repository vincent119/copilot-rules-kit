---
name: release-workflow
description: Standard release workflow - Test, tag, push. Supports Go, Python, Node.js, Bash, YAML projects.
keywords:
  - release
  - version
  - tag
  - git tag
  - semantic versioning
  - semver
  - publish
  - deploy
  - release workflow
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Release Workflow

Standard process for releasing new versions across different project types.

## Workflow Steps

### 1. Check Git Status

Ensure clean working directory:

```bash
git status --porcelain
```

### 2. Run Tests

Execute tests based on project type:

```bash
# Go
go test -v ./...

# Python
pytest

# Node.js
npm test

# Bash
bash -n script.sh

# YAML
yamllint .
```

### 3. Determine Version

Review existing tags and decide next version:

```bash
git tag --sort=-v:refname | head -n 5
```

**Ask user**: "What should the next version tag be? (e.g., v1.0.1)"

### 4. Create Tag

```bash
git tag <VERSION>
```

### 5. Push Tag

```bash
git push origin <VERSION>
```

### 6. Verify (Optional)

```bash
git ls-remote --tags origin | grep <VERSION>
```

## Version Guidelines

| Change Type | Version Bump | Example |
|------------|--------------|---------|
| Breaking changes | Major | v1.0.0 → v2.0.0 |
| New features | Minor | v1.0.0 → v1.1.0 |
| Bug fixes | Patch | v1.0.0 → v1.0.1 |

## Common Patterns

```bash
# Full workflow one-liner
git status --porcelain && \
go test -v ./... && \
git tag v1.0.1 && \
git push origin v1.0.1
```
