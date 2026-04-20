# Harness Source Snapshot 2026-04-20

Captured on 2026-04-20 for repo-local governance work in `/workspaces/jfrog-artifactory-lan`.

## OpenAI

### Harness Engineering
- Source: <https://openai.com/index/harness-engineering/>
- Key signals:
  - Treat harness design as an engineering surface, not just a prompt-writing exercise.
  - Keep context on disk in scoped files instead of collapsing everything into one giant prompt.
  - Use deterministic validation and iterate on the environment around the model, not only the instructions.

### How OpenAI Uses Codex
- Source: <https://cdn.openai.com/pdf/6a2631dc-783e-479b-b1a4-af0cfbd38630/how-openai-uses-codex.pdf>
- Key signals:
  - Start larger changes with an explicit plan before coding.
  - Maintain `AGENTS.md` as persistent repo context.
  - Improve the agent's environment and task structure over time instead of expecting one prompt to solve everything.

### A Practical Guide To Building Agents
- Source: <https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf>
- Key signals:
  - Prefer a single agent with tools before adding orchestration complexity.
  - Reuse existing policy and operating documents as instruction sources.
  - Add clearer actions, edge-case handling, and guardrails before reaching for more agents.

## Anthropic

### Claude Code Settings
- Source: <https://code.claude.com/docs/en/settings>
- Key signals:
  - Keep `CLAUDE.md` for instructions and context.
  - Keep JSON settings for permissions, environment variables, hooks, and tool behavior.
  - Respect configuration scopes and precedence instead of mixing policy into one file.

### Claude Code Subagents
- Source: <https://code.claude.com/docs/en/sub-agents>
- Key signals:
  - Use subagents for narrow, independent work that benefits from specialization.
  - Keep project-level agent definitions in repo-scoped config rather than embedding long reviewer prompts in top-level docs.

### Claude Code Hooks
- Source: <https://code.claude.com/docs/en/hooks>
- Key signals:
  - Use hooks for deterministic enforcement and repeatable checks.
  - Use agent hooks only when verification requires reading actual files or outputs.
  - Keep hook handlers explicit about their inputs, outputs, and blocking behavior.

## Meta-Harness

### Paper
- Source: <https://arxiv.org/abs/2603.28052>
- Key signals:
  - The harness around a model can materially change outcomes even when the model weights stay fixed.
  - Filesystem-visible execution traces and prior candidates are valuable optimization inputs.
  - Harness quality should be treated as an iterated engineering target, not a frozen prompt artifact.

### Project Page
- Source: <https://yoonholee.com/meta-harness/>
- Key signals:
  - Rich on-disk trace access beats over-compressed summaries for diagnosing agent failures.
  - Strong results come from improving the surrounding harness code, validation, and context management together.

### Reference Code
- Source: <https://github.com/stanford-iris-lab/meta-harness>
- Key signals:
  - The framework is organized around reusable onboarding, reference experiments, and stored artifacts on disk.
  - The paper's reference implementation reinforces the idea that harnesses should be inspectable code and files, not just opaque prompts.
