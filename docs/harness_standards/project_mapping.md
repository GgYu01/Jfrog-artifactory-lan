# Project Mapping

## Canonical Document Roles

### Operator truth
- [README.md](/workspaces/jfrog-artifactory-lan/README.md)
- [docs/architecture/overview.md](/workspaces/jfrog-artifactory-lan/docs/architecture/overview.md)
- [docs/operations/runbook.md](/workspaces/jfrog-artifactory-lan/docs/operations/runbook.md)
- [docs/operations/deployment-guide.md](/workspaces/jfrog-artifactory-lan/docs/operations/deployment-guide.md)
- [docs/operations/troubleshooting.md](/workspaces/jfrog-artifactory-lan/docs/operations/troubleshooting.md)
- [docs/reference/config-explained.md](/workspaces/jfrog-artifactory-lan/docs/reference/config-explained.md)

### Governance truth
- [AGENTS.md](/workspaces/jfrog-artifactory-lan/AGENTS.md)
- [CLAUDE.md](/workspaces/jfrog-artifactory-lan/CLAUDE.md)
- [docs/agent-evals.md](/workspaces/jfrog-artifactory-lan/docs/agent-evals.md)
- [docs/harness_standards/local_normative_baseline.md](/workspaces/jfrog-artifactory-lan/docs/harness_standards/local_normative_baseline.md)
- [docs/harness_standards/project_mapping.md](/workspaces/jfrog-artifactory-lan/docs/harness_standards/project_mapping.md)
- [docs/harness_standards/refresh_runbook.md](/workspaces/jfrog-artifactory-lan/docs/harness_standards/refresh_runbook.md)
- [docs/harness_sources/](/workspaces/jfrog-artifactory-lan/docs/harness_sources/README.md)

### Deterministic enforcement
- [.codex/hooks.json](/workspaces/jfrog-artifactory-lan/.codex/hooks.json)
- [.codex/agents/reviewer.toml](/workspaces/jfrog-artifactory-lan/.codex/agents/reviewer.toml)
- [.codex/agents/docs_guard.toml](/workspaces/jfrog-artifactory-lan/.codex/agents/docs_guard.toml)
- [scripts/validate.sh](/workspaces/jfrog-artifactory-lan/scripts/validate.sh)

### Historical working material
- [docs/superpowers/](/workspaces/jfrog-artifactory-lan/docs/superpowers/specs/2026-04-19-jfrog-artifactory-lan-design.md)

These files explain how the repo was designed at a point in time. They are useful evidence, but they are not the first place to update when current behavior changes.

### Session-local artifacts
- `tmp/`
- `reports/`
- `.planning/`
- ignored root planning files if a local harness creates them

These surfaces are for work-in-progress evidence and local planning, not durable repo policy.

## Reviewer Routing
- Workflow, persistence, portal, or backup logic changes: run `repo-reviewer`.
- Operator-doc changes: run `docs-guard`.
- Harness standards shelf changes: run `docs-guard`, refresh sources first, then run `bash scripts/validate.sh`.

## CLI Direction
- The current scripts remain the low-level operator control surface.
- Future CLI consolidation should preserve the same business abstractions: `firmware`, `patch`, no ordinary-user delete, explicit defaults, recoverable state, and copy-pasteable Linux commands.
- If a unified CLI is introduced later, `status`, `doctor`, and `restore` should become first-class subcommands before adding broader automation.
