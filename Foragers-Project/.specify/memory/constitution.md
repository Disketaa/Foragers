# Foragers Constitution
<!-- Sync Impact Report:
- Version change: 0.0.0 (uninitialized) → 1.0.0
- Modified principles: N/A (initial creation)
- Added sections: Core Principles (I–VII), Technology Constraints, Development Workflow, Governance
- Removed sections: None
- Templates requiring updates:
  - ✅ .specify/templates/plan-template.md (Constitution Check gates align with new principles)
  - ✅ .specify/templates/spec-template.md (mandatory sections preserved)
  - ✅ .specify/templates/tasks-template.md (task categories reflect principle-driven work)
  - ✅ .specify/templates/constitution-template.md (source template; no changes needed)
- Follow-up TODOs: None
-->

## Core Principles

### I. Code Style & Analyzer Compliance (NON-NEGOTIABLE)
All code MUST conform to the project `.editorconfig` and analyzer rules. `TreatWarningsAsErrors` is enabled; builds fail on violations. `var` is used only when the type is apparent from the right-hand side. Explicit types are used everywhere else. The null-forgiving operator (`!`) is forbidden — nulls are handled explicitly. IDE0005/IDE0007/IDE0008 are never suppressed; the underlying code is fixed instead.

**Rationale**: The project enforces a strict, opinionated style. Violations break the build, so compliance is binary — either the code conforms or it does not compile.

### II. One Class Per File, File-Scoped Namespaces
Every file contains exactly one top-level type. Namespaces use file-scoped syntax (`namespace Foragers_Project.Core;`). Private fields use `_camelCase`; public members use `PascalCase`. File names use kebab-case (e.g., `Game-Root.cs`).

**Rationale**: Predictable structure makes navigation trivial and enforces single-responsibility at the file level.

### III. Composition Over Inheritance
Prefer composition and small focused classes. Minimal changes to existing code. Follow existing patterns before introducing new ones.

**Rationale**: Inheritance hierarchies in game code tend to become rigid and hard to refactor. Composition keeps systems decoupled and testable.

### IV. Data-Driven Configuration
Use JSON files for configuration and entity data. Use the `Runtime` helper for loading and accessing JSON data. Hot-reload via `FileSystemWatcher` is preferred for data files that change during development.

**Rationale**: Designers and tools can tweak values without recompiling. Centralizing data access through `Runtime` ensures a single, consistent loading path.

### V. MonoGame Rendering Standards
Base resolution is 640×360. Pixel perfect rendering with `SamplerState.PointClamp`. Render to a `RenderTarget2D` at base resolution, then scale to the window.

**Rationale**: Pixel-art aesthetics require point sampling and integer-scale rendering to avoid blurriness and distortion.

### VI. Sprite Tween System
Compose a `SpriteRenderer` field in any entity that needs visual effects. Call `_renderer.TriggerTween(new SpriteTween(SpriteTarget, from, to, duration, curve))` to fire an effect. Call `_renderer.Update(gameTime)` and `_renderer.Draw(...)` each frame. `SpriteTarget` values: `ScaleX`/`ScaleY` multiply (factors), `X`/`Y` add (pixels). Curves live in `Tweens` as static methods (e.g., `Tweens.BackOut`).

**Rationale**: A centralized tween system avoids ad-hoc animation code scattered across entities and keeps visual effects data-driven and composable.

### VII. Read Before Write, Build After Change
Read related files first. After changes, run `dotnet build`. If it fails, fix the underlying code — never suppress via `#pragma`, `[SuppressMessage]`, or lowering severity in `.editorconfig`. Re-build until it succeeds before reporting the task as complete.

**Rationale**: Game projects with native dependencies and strict analyzers cannot tolerate silent failures. A green build is the minimum bar for "done."

## Technology Constraints

- **Language**: C# 12 / .NET 8
- **Framework**: MonoGame DesktopGL 3.8.1.303
- **Platform**: Windows 11, VS Code
- **Analyzers**: Microsoft.CodeAnalysis.NetAnalyzers, Roslynator.Analyzers — both enforced at build
- **Formatting**: CSharpier (runs on build via MSBuild target)

## Development Workflow

1. Load or create the relevant JSON data via `Runtime.Load`.
2. Read existing code in the target area before editing.
3. Make minimal, focused changes — one class per file.
4. Run `dotnet build` and fix all errors/warnings.
5. Verify hot-reload behavior if data files changed.

## Governance

This constitution supersedes all other practices. Amendments require documentation, approval, and a migration plan. All PRs/reviews must verify compliance with these principles. Complexity must be justified. Use `.clinerules/AI.md` for runtime development guidance.

**Version**: 1.0.0 | **Ratified**: 2026-06-28 | **Last Amended**: 2026-06-28