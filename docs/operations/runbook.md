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
7. 管理员访问 `http://<host>:8082`

## 默认账号
- Artifactory admin UI: `admin / 你在 .env 里设置的密码`
- Ordinary-user portal: `user / user`

`user / user` is the portal credential, not a native Artifactory OSS user. This is intentional: the portal is the upload/download-only surface, while the delete-capable Artifactory admin UI remains a separate admin-only credential surface.
Because the admin UI is LAN-reachable by default, `start.sh` refuses to start if `ARTIFACTORY_ADMIN_PASSWORD` is still using the template/default value.

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
1. Log in to the admin UI on port `8082` with the admin credential
2. Create a Local repository
3. Choose package type `Generic`
4. Set the Repository Key to the value of `CONTENT_REPOSITORY_KEY` in `.env`
5. Rerun `bash scripts/bootstrap-artifactory.sh`

## Docker 挂载路径
当前默认挂载如下：
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

这些是宿主机目录，不是 `CONTENT_REPOSITORY_KEY` 这种 Artifactory 仓库 key。
`CONTENT_REPOSITORY_KEY` 只决定 Artifactory 里的逻辑仓库名，例如 `lan-drop-local/firmware/...`，不是相对于脚本执行目录的本地文件夹。

这些路径现在可以改，但当前仓库还没有把它们抽成 `.env` 参数。
如果你要改，请同步修改 [`docker-compose.yml`](/workspaces/jfrog-artifactory-lan/docker-compose.yml) 以及相关脚本里的目录创建和备份路径。
