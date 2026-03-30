---
name: changelog-generator
description: Transform Git commits into user-facing changelogs. Auto-categorize, filter noise, generate professional Release Notes.
keywords:
  - changelog
  - release notes
  - git log
  - version release
  - commit history
  - keep a changelog
  - semantic versioning
  - app store update
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Changelog Generator

Convert technical commits into user-friendly release notes. Supports GitHub Release, App Store updates, email notifications, and more.

## When to Use

Version releases, product update summaries, App Store submissions, public CHANGELOG maintenance.

## Core Features

1. **Auto-categorize**: feat→Added, fix→Fixed, perf→Improved
2. **Filter noise**: Exclude CI/CD, tests, refactors, docs
3. **Language transform**: Technical terms → User value descriptions
4. **Follow standards**: Semantic Versioning + Keep a Changelog

## Usage

```bash
# Basic usage
Generate changelog for commits from the last 7 days
Create release notes for v2.5.0

# Specify range
Create changelog for commits between 3/1 and 3/15
Generate changelog for commits after v2.4.0
```

## Output Format

```markdown
## [X.Y.Z] - YYYY-MM-DD

### ✨ Added
- Feature description (emphasize user value)

### 🔧 Changed
- Improvement description (explain benefits)

### 🐛 Fixed
- Fix description (problem solved)

### ⚠️ Breaking Changes
- Change description (impact & migration guide)
```

## Filter Rules

**Exclude**: CI/CD, version bumps, refactors, tests, comments, logs, non-impactful dependency updates
**Include**: All changes affecting end users

## Writing Principles

1. One item per logical change
2. No commit hashes, PR numbers, internal module names
3. Avoid vague terms (improve/update), be specific about impact
4. Use past tense, affirmative tone
5. Emphasize "what was solved" or "what was gained"

## Example

**Input**: Last 7 days commits
**Output**:
```markdown
## [2.5.0] - 2024-03-10

### ✨ Added
- **Team Workspaces**: Create separate workspaces and invite team members
- **Keyboard Shortcuts**: Press ? to view all shortcuts

### 🔧 Changed
- 2x faster file sync across devices
- Search now includes file content

### 🐛 Fixed
- Fixed large image upload failures
- Resolved notification count errors
```
