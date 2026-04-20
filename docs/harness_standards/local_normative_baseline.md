# Local Normative Baseline

## Purpose
- Translate upstream OpenAI, Anthropic, and Meta-Harness guidance into a small set of durable rules for this repository.
- Keep these rules stable enough for long-term agent maintenance without turning them into a giant prompt.

## Normative Rules

### 1. Separate instruction layers by job
- `AGENTS.md` stays short and repo-wide.
- `CLAUDE.md` points to the canonical docs an agent should read before non-trivial work.
- `.codex/agents/` and `.codex/hooks.json` carry specialized reviewers and deterministic enforcement.
- `docs/harness_standards/` holds durable repo-local standards derived from upstream sources.

### 2. Prefer the smallest stable control surface
- Keep one clear operator-facing workflow per task category.
- Do not introduce multi-agent orchestration when a single agent plus tools and validation is enough.
- When subagents are used, give them narrow, non-overlapping responsibilities.

### 3. Treat the filesystem as the durable context plane
- Keep persistent operator and governance knowledge in checked-in docs.
- Keep session-local artifacts in ignored paths such as `tmp/` or `.planning/`.
- Do not rely on one conversation or one prompt as the only source of truth for repo behavior.

### 4. Use deterministic enforcement before prose
- Prefer validation scripts, tests, hooks, and narrow reviewer agents over longer policy text.
- Use hooks for mechanical checks and blocking conditions.
- Use documentation to explain intent, boundaries, and workflows that code alone cannot express.

### 5. Re-verify drift-prone external assumptions
- Re-check upstream product capabilities, configuration semantics, and harness guidance before changing local standards.
- Record the source date and URLs in `docs/harness_sources/` when the standards shelf is refreshed.
