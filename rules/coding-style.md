# Coding Style

## File organization (all languages)
- Many small, focused files over few large ones; high cohesion, low coupling.
- Typical 200-400 lines, 800 max. Extract utilities from large modules.
- Organize by feature/domain, not by type.

## Error handling
- Handle errors where you can act on them; don't swallow them silently.
- No stray `console.log`/`print` debug statements left in committed code.
- No hardcoded secrets or magic values that belong in config/env.

## TypeScript / JavaScript specifics
- Prefer immutable updates (`{...obj, field}`, spread, `map`/`filter`) over in-place mutation, except in hot paths where mutation is deliberate and local.
- Validate external/untrusted input at the boundary with `zod` (or the project's existing schema lib — match what's there).

## Other languages
- Follow the language's idioms and the project's existing conventions. Don't impose JS/TS patterns (spread-immutability, zod) on Python/Go/Rust — use their native equivalents (dataclasses/pydantic, structs, ownership).

## Before marking work complete
- Readable, well-named, functions small, nesting shallow (≤4 levels).
- Errors handled, no debug prints, no hardcoded values.
