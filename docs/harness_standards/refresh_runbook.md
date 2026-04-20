# Harness Standards Refresh Runbook

## When To Refresh
- Before changing `AGENTS.md`, `CLAUDE.md`, `.codex/agents/`, `.codex/hooks.json`, or `docs/agent-evals.md`.
- Before claiming repo-local standards still match current OpenAI, Anthropic, or Meta-Harness guidance.
- After a major harness or agent-runtime upgrade.

## Refresh Steps
1. Review the current standards shelf under `docs/harness_standards/`.
2. Run `bash scripts/refresh_harness_sources.sh`.
3. Open the newest dated file under `docs/harness_sources/` and confirm the source URLs are still reachable.
4. If a source returns a non-200 status because of bot or browser gating, re-check it manually in a browser-capable tool and record that exception in the refresh evidence.
5. Update `docs/harness_sources/README.md` if a newer dated snapshot should become the default reference.
6. Update `docs/harness_standards/local_normative_baseline.md` and `docs/harness_standards/project_mapping.md` only if the upstream guidance changed the local rule.
7. Run `bash scripts/validate.sh`.

## What Not To Do
- Do not copy large upstream documents into the repo.
- Do not turn `AGENTS.md` into a standards dump.
- Do not update local standards from memory alone when the upstream source is easy to re-check.
