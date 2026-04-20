# AGENTS.md

## Scope
- This file governs the whole repository.
- Keep it light. Stable repo-wide instructions only.
- Runtime switches, hook wiring, and model choices do not belong here.

## Repository Expectations
- Treat this repository as an appliance-style deployment project for JFrog Artifactory OSS on a LAN.
- Default operator UX must stay simple: predictable scripts, explicit defaults, and recoverable state on disk.
- Prefer bind-mounted persistence over opaque Docker volumes so operators can inspect and back up data directly.
- Keep all operator-facing paths and commands Linux-first and copy-pasteable.

## Verification
- Before claiming the repository is ready, run the repo validation script and the automated tests.
- Do not claim live container verification unless Docker or an equivalent runtime actually exists in the current environment.
- When behavior depends on JFrog edition limits, state the limit explicitly and show the fallback design used here.

## Boundaries
- Do not silently remove persisted paths, backup logic, or the user portal without replacing the underlying capability.
- Do not replace Artifactory OSS with another product unless the user explicitly asks for that pivot.
- Keep ordinary-user delete capability blocked by design.

## Delegation
- Use subagents only for clearly independent research or review tasks.
- Keep delegated tasks narrow and avoid overlapping write scopes.

## Evidence
- Prefer exact file paths, exact commands, and concrete defaults.
- Separate verified facts from assumptions or environment limits.

## Documentation
- Update `README.md`, `docs/architecture/overview.md`, and `docs/operations/runbook.md` whenever operator workflow or persistence layout changes.
- Keep AI-maintenance guidance in `CLAUDE.md`, `.codex/agents/`, `.codex/hooks.json`, `docs/agent-evals.md`, and `docs/harness_standards/`.
- Keep external agent/harness source snapshots in `docs/harness_sources/`.
- Treat `docs/superpowers/` as historical working material, not the canonical operator or governance surface.

## Non-Goals
- Do not turn this file into a repo map or an incident notebook.
- Do not duplicate long runbooks or design rationale here.
