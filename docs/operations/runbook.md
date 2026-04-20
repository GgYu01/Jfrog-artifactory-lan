# Operations Runbook

## 先看哪份文档
- 第一次部署，先看 [deployment-guide.md](/workspaces/jfrog-artifactory-lan/docs/operations/deployment-guide.md)
- 如果你是把仓库直接交给基础薄弱的同事，就只让他先看这一份
- 需要逐项看配置，去看 [config-explained.md](/workspaces/jfrog-artifactory-lan/docs/reference/config-explained.md)
- 遇到问题，去看 [troubleshooting.md](/workspaces/jfrog-artifactory-lan/docs/operations/troubleshooting.md)

## 第一次部署最短路径
1. `cp .env.example .env`
2. 打开 `.env`，确认端口、密码、仓库 key
3. `bash scripts/install-or-update.sh`
4. `bash scripts/start.sh`
5. `bash scripts/status.sh`
6. 局域网用户访问 `http://<host>:8080`
7. 管理员在宿主机本机访问 `http://127.0.0.1:8082`

## 默认账号
- Artifactory admin UI: `admin / Aa123456`
- Ordinary-user portal: `user / user`

`user / user` is the portal credential, not a native Artifactory OSS user. This is intentional: the portal is the upload/download-only surface, while the delete-capable Artifactory admin UI stays localhost-bound by default.

## 普通用户怎么用
- Upload firmware bundles through the Firmware area.
- Upload patch bundles through the Patch area.
- Download from both areas.
- Delete is intentionally unavailable in the portal.
- The portal writes into the Generic local repository configured by `CONTENT_REPOSITORY_KEY`, defaulting to `lan-drop-local`.

## 备份
- Run `bash scripts/backup-once.sh`.
- Only the newest backup archive is retained by default.

## 升级版本
- Normal install or restart path: `bash scripts/install-or-update.sh`
- Track the latest upstream release intentionally: `bash scripts/install-or-update.sh --track-latest`
- The default path keeps the configured version pinned and only downloads the package for that configured version if it is missing locally.

## 如果内容仓库没有自动创建
The bootstrap step tries to create `CONTENT_REPOSITORY_KEY` as a Generic local repository.

If your running Artifactory build rejects that API call:
1. Log in to the admin UI on port `8082` from the host
2. Create a Local repository
3. Choose package type `Generic`
4. Set the Repository Key to the value of `CONTENT_REPOSITORY_KEY` in `.env`
5. Rerun `bash scripts/bootstrap-artifactory.sh`
