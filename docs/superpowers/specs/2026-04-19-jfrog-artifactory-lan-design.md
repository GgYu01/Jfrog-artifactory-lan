# JFrog Artifactory LAN Design

## Problem
- Non-DevOps operators need a fast, local, HTTP-only artifact appliance for flashing-image bundles and patch bundles.
- The system must stay persistent across container refreshes.
- The admin account is fixed by requirement.
- Ordinary users must upload and download but not delete.

## Chosen design
- Use JFrog Artifactory OSS plus PostgreSQL for the storage appliance.
- Use `bootstrap.creds` so the required admin password is set before first login.
- Use a repo-local ordinary-user portal instead of OSS-native permission targets, because the documented OSS API surface does not guarantee the requested no-delete user model.
- Store firmware and patch content as two top-level folders inside one operator-configurable content repository key, defaulting to `lan-drop-local`.
- Bind the delete-capable Artifactory admin UI to localhost by default so LAN users cannot bypass the portal.
- Attempt repository creation automatically during bootstrap and document a single-step admin fallback if the instance rejects it.

## Data flow
- Admins use Artifactory directly on port `8082`.
- Ordinary users use the portal on port `8080`.
- The portal authenticates `user / user`, validates the requested target area, then proxies upload and download operations to Artifactory using the admin service credential.

## Persistence
- Persist the whole Artifactory `var` tree on the host.
- Persist PostgreSQL data on the host.
- Keep upstream templates and release tarballs under `vendor/` for traceability.

## Safety and recovery
- Backup keeps one generation by default.
- The portal never exposes delete.
- Scripts fail fast when required tools or expected repo paths are missing.
