# JFrog Artifactory LAN Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a git-managed LAN deployment project for JFrog Artifactory OSS with persistent storage, one-generation backups, upstream version detection, and an ordinary-user upload/download-only portal for firmware and patch bundles.

**Architecture:** The stack uses PostgreSQL, Artifactory OSS, and a repo-local Node portal. Admin bootstrap is handled with `bootstrap.creds`; ordinary-user restrictions are enforced in the portal because OSS-native permission controls are insufficient for the requested model.

**Tech Stack:** Docker Compose, Bash, Python 3 unittest, Node.js built-in HTTP server, JFrog OSS upstream release package.

---

### Task 1: Governance And Operator Docs

**Files:**
- Create: `AGENTS.md`
- Create: `CLAUDE.md`
- Create: `docs/agent-evals.md`
- Create: `docs/architecture/overview.md`
- Create: `docs/operations/runbook.md`
- Create: `README.md`

- [ ] Write the governance and operator docs.
- [ ] Verify the docs match the chosen architecture and user model.

### Task 2: Compose And Config Skeleton

**Files:**
- Create: `.env.example`
- Create: `docker-compose.yml`
- Create: `config/artifactory/var/etc/access/bootstrap.creds`
- Create: `config/artifactory/var/etc/security/master.key`
- Create: `config/artifactory/var/etc/security/join.key`

- [ ] Write deterministic compose and config templates with explicit bind mounts.
- [ ] Verify YAML parses through `yq`.

### Task 3: Operator Scripts

**Files:**
- Create: `scripts/lib/common.sh`
- Create: `scripts/install-or-update.sh`
- Create: `scripts/prepare-host.sh`
- Create: `scripts/start.sh`
- Create: `scripts/stop.sh`
- Create: `scripts/status.sh`
- Create: `scripts/wait-artifactory.sh`
- Create: `scripts/bootstrap-artifactory.sh`
- Create: `scripts/backup-once.sh`
- Create: `scripts/validate.sh`

- [ ] Implement version detection, upstream package fetch, host directory creation, start/stop/status, bootstrap checks, backup, and validation.
- [ ] Run shell syntax checks.

### Task 4: Ordinary-User Portal

**Files:**
- Create: `portal/Dockerfile`
- Create: `portal/server.js`
- Create: `portal/public/index.html`
- Create: `portal/public/app.js`
- Create: `portal/public/styles.css`
- Create: `portal/lib/paths.js`
- Create: `portal/tests/paths.test.js`

- [ ] Implement a small HTTP portal with fixed credentials `user / user`.
- [ ] Limit content areas to firmware and patch.
- [ ] Support list, upload, and download only.
- [ ] Run `node --test`.

### Task 5: Python Validation Tests

**Files:**
- Create: `tests/test_release_logic.py`
- Create: `tests/test_repo_layout.py`

- [ ] Add unittest coverage for upstream version parsing and repo-local configuration assumptions.
- [ ] Run `python3 -m unittest discover -s tests -p 'test_*.py'`.

