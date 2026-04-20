# Architecture Overview

## Goal
- Provide a LAN-only JFrog Artifactory OSS appliance for storing firmware flashing bundles and patch bundles over plain HTTP, while preserving on-disk state and shielding ordinary users from delete-capable administration.

## Components
- `postgres`: persistent metadata database for Artifactory.
- `artifactory`: JFrog Artifactory OSS service bound to `0.0.0.0:8082` by default so administrators can reach the UI from the LAN.
- `portal`: repo-local ordinary-user web portal exposed on LAN HTTP port `8080`.

## Why the portal exists
- The requested ordinary-user model is `user / user`, upload and download only, no delete.
- JFrog’s documented permission target and legacy Artifactory user-management APIs are Pro-only, so Artifactory OSS cannot be trusted to enforce this exact model by itself.
- The portal therefore becomes the safety boundary for ordinary users:
  - only two logical content areas are exposed
  - uploads are allowed
  - downloads are allowed
  - delete is not implemented
  - Artifactory admin access remains a separate credential surface on `8082`; ordinary users are still expected to work through the portal instead of the admin UI

## Content model
- Default Artifactory content repository: `lan-drop-local`
- Firmware path prefix: `firmware/`
- Patch path prefix: `patch/`

That produces these operator-visible logical spaces:
- `lan-drop-local/firmware/...`
- `lan-drop-local/patch/...`

The bootstrap script attempts to create `lan-drop-local` as a Generic local repository. If the running Artifactory build rejects repository creation through the API, the only required manual fallback is to create that Generic local repository once in the admin UI.

## Persistence model
- Keep a root bind mount for the entire Artifactory `var` tree.
- Also bind critical subpaths explicitly for operator visibility and backup granularity:
  - `bootstrap`
  - `data`
  - `etc`
  - `log`
  - `backup`
  - `etc/access`
  - `etc/security`
  - `etc/artifactory`
  - `etc/router`
- Persist PostgreSQL data separately.

Current default host-to-container mappings are:
- `./data/postgres/data` -> `/var/lib/postgresql/data`
- `./data/artifactory/var` -> `/var/opt/jfrog/artifactory`
- `./data/artifactory/var/bootstrap` -> `/var/opt/jfrog/artifactory/bootstrap`
- `./data/artifactory/var/data` -> `/var/opt/jfrog/artifactory/data`
- `./data/artifactory/var/etc` -> `/var/opt/jfrog/artifactory/etc`
- `./data/artifactory/var/log` -> `/var/opt/jfrog/artifactory/log`
- `./data/artifactory/var/backup` -> `/var/opt/jfrog/artifactory/backup`
- `./data/artifactory/var/etc/access` -> `/var/opt/jfrog/artifactory/etc/access`
- `./data/artifactory/var/etc/security` -> `/var/opt/jfrog/artifactory/etc/security`
- `./data/artifactory/var/etc/artifactory` -> `/var/opt/jfrog/artifactory/etc/artifactory`
- `./data/artifactory/var/etc/router` -> `/var/opt/jfrog/artifactory/etc/router`

Those host paths are currently defined directly in `docker-compose.yml`. They are configurable by editing the compose file, but they are not yet parameterized in `.env`.

## Backup model
- Default backup policy keeps a single compressed snapshot generation.
- The snapshot covers both Artifactory state and PostgreSQL state.
- This matches the user requirement of short-retention rollback without long-term storage pressure.
