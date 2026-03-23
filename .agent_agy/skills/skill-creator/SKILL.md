---
name: skill-creator
description: Guide for creating effective skills. Use when creating/updating skills to extend Claude's capabilities with workflows, tools, or domain knowledge.
---

# Skill Creator

Skills extend Claude with specialized workflows, tools, and domain knowledge through modular packages.

## What Skills Provide

- Specialized multi-step workflows
- Tool integrations and file format handling
- Domain expertise and business logic
- Bundled resources (scripts, references, assets)

## Core Principles

**Be Concise**: Context window is shared. Assume Claude is smart—only add what's truly needed.

**Set Appropriate Freedom**:
- **High** (text instructions): Multiple valid approaches
- **Medium** (pseudocode/scripts): Preferred patterns with flexibility
- **Low** (specific scripts): Fragile operations requiring consistency

## Skill Structure

```bash
skill-name/
├── SKILL.md (required)
│   ├── YAML: name + description
│   └── Markdown: instructions
└── Optional resources:
    ├── scripts/     - Executable code
    ├── references/  - Docs loaded as needed
    └── assets/      - Output templates/files
```

**Resources**:
- `scripts/`: Reusable code (Python/Bash)
- `references/`: Domain docs, schemas, APIs
- `assets/`: Templates, images, boilerplates

**Exclude**: README, CHANGELOG, docs not needed by Claude

## Progressive Disclosure

3-tier loading:
1. **Metadata** (~100 words) - Always loaded
2. **SKILL.md body** (<500 lines) - When triggered
3. **Resources** - On demand

**Patterns**:
```markdown
# Core workflow in SKILL.md
* Advanced: See [ADVANCED.md]
* API: See [API.md]
```

Organize by domain/framework:
```
cloud-deploy/
├── SKILL.md
└── references/
    ├── aws.md
    └── gcp.md
```

## Creation Process

1. **Understand**: Clarify use cases with examples
2. **Plan**: Identify reusable scripts/references/assets
3. **Initialize**: `scripts/init_skill.py <name> --path <dir>`
4. **Edit**:
   - Add resources (scripts/references/assets)
   - Write SKILL.md with:
     - **Frontmatter**: `name` + `description` (trigger conditions)
     - **Body**: Instructions and workflows
5. **Package**: `scripts/package_skill.py <path>`
6. **Iterate**: Test and refine

## Writing Guidelines

- Use imperative/infinitive tense
- `description`: Include what + when to use
- Keep SKILL.md <500 lines
- Test scripts before packaging
- Remove unused example files
