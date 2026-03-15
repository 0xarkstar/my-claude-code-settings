# Magic UI (MCP Component Registry)

## What It Is

Magic UI is a component registry accessible via `mcp__magic__` tools.
It provides 69 animated/interactive components that install via shadcn CLI
and coexist with shadcn/ui primitives.

## When to Use (Trigger Conditions)

Check Magic UI registry BEFORE implementing from scratch when:
- Building landing pages, portfolios, or marketing sites
- Adding animations or visual effects (text, background, borders)
- Creating bento grids, marquees, or showcase layouts
- Needing device mockups (iPhone, Android, Safari browser)
- Adding interactive elements (dock, globe, file tree, icon cloud)
- Any React + Tailwind project that uses shadcn/ui

## Workflow

```
1. Search:  mcp__magic__searchRegistryItems(query="bento grid")
2. Detail:  mcp__magic__getRegistryItem(name="bento-grid", includeSource=true, includeExamples=true)
3. Install: npx shadcn@latest add "https://magicui.design/r/{name}.json"
4. Customize: modify the installed component in @/components/ui/
```

## shadcn + Magic Relationship

| Layer | Role | Examples |
|-------|------|----------|
| shadcn/ui | Base primitives | Button, Input, Dialog, Card, Table |
| Magic UI | Animated/effect components | Bento Grid, Marquee, Globe, Animated Beam |

Magic components depend on shadcn primitives. They are complementary, not competing.
Always install shadcn base components first, then layer Magic components on top.

## Available Tools

| Tool | Purpose |
|------|---------|
| `mcp__magic__listRegistryItems` | Browse by kind (component/example/style), with pagination |
| `mcp__magic__searchRegistryItems` | Search by keyword or use case |
| `mcp__magic__getRegistryItem` | Get source code, install command, and examples |

## Component Categories (69 total)

- **Text/Animation (18)**: animated-gradient-text, aurora-text, hyper-text, morphing-text, typing-animation, word-rotate, etc.
- **Backgrounds/Patterns (10)**: dot-pattern, grid-pattern, retro-grid, particles, flickering-grid, etc.
- **Buttons (6)**: shimmer-button, rainbow-button, pulsating-button, shiny-button, etc.
- **Layout/Cards (4)**: bento-grid, magic-card, neon-gradient-card, marquee
- **Visual Effects (9)**: animated-beam, border-beam, confetti, meteors, number-ticker, etc.
- **Device Mockups (3)**: android, iphone, safari
- **Interactive (7)**: dock, file-tree, globe, icon-cloud, lens, pointer, smooth-cursor
- **Other (12)**: animated-list, tweet-card, code-comparison, terminal, hero-video-dialog, etc.

## Priority

When a UI task matches Magic UI capabilities:
1. **Magic registry search first** — check if a ready-made component exists
2. **Install + customize** — faster and more polished than building from scratch
3. **Build from scratch** — only if nothing in the registry fits
