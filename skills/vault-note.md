# vault-note Skill

## Trigger
`/vault-note` or "save to vault" or "vault this"

## Purpose
User-triggered capture of a high-value decision or finding into the Obsidian vault.
Use this when the user explicitly wants to save something, bypassing the 3-question gate.

## Steps

1. Ask (or infer from context): what is the title and type (adr/til/post-mortem/pattern)?
2. Identify the project from cwd or context.
3. Check for existing similar notes:
   ```
   Glob: ~/Obsidian/Dev/Projects/{project}/*.md
   ```
4. If similar note found: append to it using Edit.
5. If no similar note: create new note using Write.

## Template

```markdown
---
type: {adr|til|post-mortem|pattern}
project: {project-name}
date: {today}
tags: [{relevant-tags}]
---

# {Title}

## Context
{What were we trying to do?}

## Decision / Finding
{What was discovered/decided and why? Include rejected alternatives.}

## Why This Matters
{What breaks if this is ignored?}

## Related
{[[wikilinks]] if applicable}
```

## File path
`~/Obsidian/Dev/Projects/{project}/{YYYY-MM-DD}-{kebab-slug}.md`

## After Writing
Confirm: "Saved: `Projects/{project}/{filename}`"
