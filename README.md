# JFrog Artifactory LAN

这个仓库把 JFrog Artifactory OSS 包装成一个适合局域网内部使用的“交付 appliance”，目标用户是不熟悉运维的同事。

## 解决的问题
- 用 HTTP 在局域网里快速部署一个可长期保存的制品库
- 管理员账号固定为 `admin`，密码由你在 `.env` 里设置
- 普通使用者固定为 `user / user`
- 普通使用者只做上传和下载，不暴露删除能力
- 默认用于存放两类内容：
  - 刷机镜像包
  - patch 包

## 关键设计
- Artifactory 管理后台默认绑定在 `0.0.0.0:8082`
- 实际访问后台时请用 `http://主机IP:8082` 或 `http://主机名:8082`，不要把 `0.0.0.0` 当成浏览器访问地址
- 因为后台默认对局域网可达，第一次启动前必须先修改 `.env` 里的 `ARTIFACTORY_ADMIN_PASSWORD`
- 普通用户走 `http://主机:8080`
- 普通用户入口是仓库自带 Portal，而不是直接把 Artifactory 后台开放给所有人
- Portal 只暴露两条逻辑通道：
  - `firmware`
  - `patch`
- 内容默认存放在 Artifactory 的 `lan-drop-local` 仓库下：
  - `lan-drop-local/firmware/...`
  - `lan-drop-local/patch/...`

## 为什么不是直接用 OSS 原生权限
- 本项目在设计时核对了 JFrog 文档，普通用户“上传/下载允许、删除禁止”的精确权限模型依赖 Pro 能力。
- 因此这里采用更稳的 OSS 方案：管理员仍用 Artifactory，普通用户则使用仓库自带 Portal，由 Portal 从入口层面阻断删除能力。
- 也因此 `user / user` 是 Portal 账号，不是 Artifactory OSS 原生用户。

## 快速开始
如果你是第一次接手这个项目，建议按这个顺序看文档：
1. [部署操作手册](/workspaces/jfrog-artifactory-lan/docs/operations/deployment-guide.md)
2. [配置说明](/workspaces/jfrog-artifactory-lan/docs/reference/config-explained.md)
3. [常见问题排查](/workspaces/jfrog-artifactory-lan/docs/operations/troubleshooting.md)

如果你希望“拉下仓库后直接照着做”，直接打开第 1 份文档即可。那份文档已经按：
- 先装什么
- 先改哪些参数
- 每一步执行哪条命令
- 执行后应该看到什么
- 出问题先看哪里

的顺序写好了。

## 快速开始步骤
1. 复制环境文件：
   - `cp .env.example .env`
2. 编辑 `.env`，至少把 `ARTIFACTORY_ADMIN_PASSWORD` 改成你自己的密码
3. 如果你希望改端口、Portal 密码或仓库 key，也在 `.env` 一起改
4. 准备主机目录和上游包：
   - `bash scripts/install-or-update.sh`
5. 启动服务：
   - `bash scripts/start.sh`
6. 访问：
   - 普通用户 Portal：`http://主机:8080`
   - Artifactory 管理后台：`http://主机:8082`

## 常用命令
- 启动：`bash scripts/start.sh`
- 停止：`bash scripts/stop.sh`
- 状态：`bash scripts/status.sh`
- 单次备份：`bash scripts/backup-once.sh`
- 校验：`bash scripts/validate.sh`

## 文档导航
- 第一次部署直接照做：
  - [deployment-guide.md](/workspaces/jfrog-artifactory-lan/docs/operations/deployment-guide.md)
  - 这份文档已经写成“给最终使用者看的逐步操作单”
- 想知道每个配置项是什么意思：
  - [config-explained.md](/workspaces/jfrog-artifactory-lan/docs/reference/config-explained.md)
- 遇到启动失败、端口不通、自动建仓失败：
  - [troubleshooting.md](/workspaces/jfrog-artifactory-lan/docs/operations/troubleshooting.md)

## 持久化目录
- `data/artifactory/var`
- `data/postgres/data`
- `data/backups`
- `vendor/upstream`

Artifactory 的 `var` 整体被绑定到宿主机，同时又把关键子路径单独显式挂载，便于长期留痕、排障和按目录观察。

## Docker 宿主机映射
当前 `docker-compose.yml` 默认把这些宿主机路径映射进容器：

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
- `/etc/localtime` -> `/etc/localtime:ro`（`postgres` 和 `artifactory` 都会挂）

Portal 默认不挂业务数据目录，只使用容器内只读根文件系统和 `tmpfs /tmp`。

这些映射现在可以改，但默认还是写死在 [`docker-compose.yml`](/workspaces/jfrog-artifactory-lan/docker-compose.yml) 里，不是通过 `.env` 参数控制。
如果你要改宿主机目录，请同时检查 `scripts/prepare-host.sh`、`scripts/backup-once.sh`、`scripts/lib/common.sh` 和相关文档，确保目录创建、备份和排障路径一起同步。

## 版本策略
- `scripts/install-or-update.sh` 默认只保证当前 `.env` 里配置的版本已经下载到本地
- `scripts/install-or-update.sh --track-latest` 才会主动检查上游最新版本并更新 `.env`
- 两种模式都会把对应的官方 compose 发行包缓存到 `vendor/upstream/`

## 内容仓库自动创建
- 启动后的 bootstrap 会尝试自动创建 `lan-drop-local` 这个 Generic 本地仓库
- 如果你的 Artifactory 实例拒绝该 API，请在后台手工创建一次同名 Generic 仓库，然后重新执行 `bash scripts/bootstrap-artifactory.sh`

## 备份策略
- 默认只保留 1 份压缩备份
- 备份同时覆盖：
  - `data/artifactory/var`
  - `data/postgres/data`
  - `.env`

## 环境限制
- 这个仓库支持完整 Docker Compose 部署
- 但如果当前机器没有 Docker，`scripts/validate.sh` 仍然可以先做静态校验和测试
