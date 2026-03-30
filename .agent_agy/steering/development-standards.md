---
title: Development Standards
inclusion: always
---

# Development Standards

## Dependency Management
- Use latest stable versions; verify compatibility via Context7 MCP before adding
- Justify each new dependency with clear business or technical value
- Prefer well-maintained libraries with active communities
- Use dependency scanning tools; review third-party packages before adding
- Use lock files; document version constraints in project files
- Remove unused dependencies regularly

## Code Quality
- Never create duplicate files with suffixes like `_fixed`, `_clean`, `_backup`
- Work iteratively on existing files
- Follow language-specific conventions (TypeScript for CDK, Python for Lambda)
- Meaningful variable and function names; small single-responsibility functions
- Proper error handling and logging
- Include relevant documentation links in code comments

## File Management
- Clean directory structures with consistent naming conventions
- No temporary or backup files in version control
- Organize code by feature or domain
- Configuration files at appropriate levels (project vs user)

## Documentation
- Single comprehensive README covering setup, deployment, and all aspects
- Reference official sources through MCP servers when available
- Update docs when upgrading dependencies
- Inline comments for complex business logic
- Document API endpoints and data structures

## Version Control
- Frequent commits with meaningful messages in Traditional Chinese
- Feature branches; main branch always deployable
- Tag releases; use .gitignore for generated files and secrets

## Quality Assurance
- Write tests for new functionality; run before committing
- Use linting and formatting tools consistently
- Code reviews for all changes; maintain high coverage standards
