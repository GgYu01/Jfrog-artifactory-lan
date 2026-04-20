# Agent Evaluations

## Purpose
- Keep repo-local AI maintenance disciplined without bloating `AGENTS.md`.
- Define what must be checked before agent-generated changes are treated as ready.

## High-Value Task Categories
- Deployment flow changes
- Persistence layout changes
- Ordinary-user portal changes
- Backup and recovery changes
- Upstream JFrog version update logic
- Harness standards and agent-governance changes

## Required Checks
- `python3 -m unittest discover -s tests -p 'test_*.py'`
- `node --test portal/tests/*.test.js`
- `bash scripts/validate.sh`

## Reviewer Routing
- Operator workflow, persistence, portal, or shell-script changes: run `.codex/agents/reviewer.toml`.
- Operator-doc changes under `README.md`, `docs/operations/`, `docs/reference/`, or `docs/architecture/`: run `.codex/agents/docs_guard.toml`.
- Harness-standards changes under `docs/harness_sources/` or `docs/harness_standards/`: run `.codex/agents/docs_guard.toml` and keep source links/date stamps current.

## Success Criteria
- No test failures
- Compose file parses cleanly through Python YAML loading
- Shell scripts pass `bash -n`
- Portal path validation rejects traversal and unsupported repositories
- Documentation and operator commands stay aligned with the implementation

## Evidence Retention
- Keep design, plan, and runbook docs checked in.
- Keep the final delivery report under `tmp/`.
- When Docker is available, attach command output and service health evidence to the temp report.
- Keep session-local planning artifacts out of the durable repo surface unless they were explicitly requested as checked-in deliverables.

## Leakage and Drift Controls
- Do not encode transient incident logs into `AGENTS.md`.
- Keep stable workflow rules in checked-in docs and deterministic hooks.
- Re-check upstream JFrog version metadata instead of relying on memory when updating versions.
- Re-check upstream OpenAI, Anthropic, and Meta-Harness sources before changing repo-local harness standards.
