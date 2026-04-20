# 配置说明

## 一句话说明
- 这份文档告诉你：仓库刚拉下来以后，`.env` 里哪些参数必须先看，哪些参数通常不用改，改了以后会影响什么。

## 先给结论
- 大多数用户第一次部署时，只需要重点确认 5 个值：
  - `PORTAL_PORT`
  - `ARTIFACTORY_ADMIN_PORT`
  - `ARTIFACTORY_ADMIN_PASSWORD`
  - `PORTAL_PASSWORD`
  - `CONTENT_REPOSITORY_KEY`
- 如果你没有端口冲突、没有密码要求、也不想改仓库名，那么复制 `.env.example` 以后基本可以直接用默认值。

## 使用顺序
1. `cp .env.example .env`
2. 打开 `.env`
3. 先看“第一次部署最应该确认的参数”
4. 如果不需要改，直接保存
5. 执行：
```bash
bash scripts/install-or-update.sh
bash scripts/start.sh
```

---

## 第一次部署最应该确认的参数

### 1. `PORTAL_PORT`
- 这是普通用户在局域网里访问 Portal 的端口
- 默认值：`8080`
- 什么时候一定要改：
  - 你的主机上 `8080` 已经被别的服务占用了
- 改成什么：
  - 例如改成 `18080`
- 改完以后用户访问地址会变成：
  - `http://主机IP:18080`

### 2. `ARTIFACTORY_ADMIN_PORT`
- 这是管理员在宿主机本机访问 Artifactory 后台的端口
- 默认值：`8082`
- 什么时候一定要改：
  - 你的主机上 `8082` 已经被占用
- 改完以后后台地址会变成：
  - `http://127.0.0.1:<你改后的端口>`

### 3. `ARTIFACTORY_ADMIN_PASSWORD`
- 这是 Artifactory 后台管理员密码
- 默认值：`Aa123456`
- 什么时候建议改：
  - 你不想继续使用默认后台密码
- 改的时候注意：
  - 这是管理员密码，不是普通用户密码
  - 改完以后脚本会用这个新密码做后台 bootstrap
  - 如果密码里包含空格，建议用双引号包起来
- 例子：
```text
ARTIFACTORY_ADMIN_PASSWORD="My Strong Password 2026"
```

### 4. `PORTAL_PASSWORD`
- 这是普通用户登录 Portal 的密码
- 默认值：`user`
- 什么时候建议改：
  - 你要把仓库交给别人正式使用时
- 改的时候注意：
  - 这是 Portal 账号，不是 Artifactory 原生账号
  - 普通用户仍然只能上传和下载，不能删

### 5. `CONTENT_REPOSITORY_KEY`
- 这是 Artifactory 里真正存放业务文件的本地仓库名
- 默认值：`lan-drop-local`
- 什么时候改：
  - 你们现场已经有固定命名规范
  - 你不想继续用默认仓库名
- 改完以后最终业务路径会跟着变
- 例如改成：
```text
CONTENT_REPOSITORY_KEY=team-drop-local
```
那最终路径就会变成：
- `team-drop-local/firmware/...`
- `team-drop-local/patch/...`

---

## 哪些参数通常不要改

如果你不是明确知道自己在做什么，下面这些参数一般保持默认：
- `POSTGRES_VERSION`
- `JFROG_DOCKER_REGISTRY`
- `JFROG_RELEASE_INDEX_URL`
- `ARTIFACTORY_ADMIN_BIND_HOST`
- `ARTIFACTORY_SERVICE_PORT`
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `FIRMWARE_PREFIX`
- `PATCH_PREFIX`

原因很简单：
- 这些参数大多是底座参数
- 它们决定的是容器、数据库、官方源地址或者内部业务前缀
- 普通现场交付通常不需要碰它们

---

## 逐项说明

## 1. 版本与上游来源

### `ARTIFACTORY_VERSION`
- 作用：
  - 指定当前要部署哪个 Artifactory OSS 版本
- 默认值：
```text
7.146.7
```
- 正常重启时要不要改：
  - 不要改
- 什么时候改：
  - 你明确要升级版本时
- 改完以后要执行什么：
```bash
bash scripts/install-or-update.sh
```
- 如果你希望自动追官方最新版本：
```bash
bash scripts/install-or-update.sh --track-latest
```

### `POSTGRES_VERSION`
- 作用：
  - 指定 PostgreSQL 镜像版本
- 默认值：
```text
17.6-alpine
```
- 一般要不要改：
  - 一般不要改

### `JFROG_DOCKER_REGISTRY`
- 作用：
  - 告诉 Docker 去哪里拉 Artifactory 官方镜像
- 默认值：
```text
releases-docker.jfrog.io
```
- 一般要不要改：
  - 一般不要改

### `JFROG_RELEASE_INDEX_URL`
- 作用：
  - 告诉下载脚本去哪里找官方 OSS compose 发行包
- 一般要不要改：
  - 一般不要改

---

## 2. 端口与访问入口

### `ARTIFACTORY_ADMIN_BIND_HOST`
- 作用：
  - 控制后台绑定到哪个地址
- 默认值：
```text
127.0.0.1
```
- 这代表什么：
  - 只有宿主机本机能直接打开后台
- 为什么默认这样设计：
  - 因为普通用户应该走 Portal，不应该直接接触后台
- 一般要不要改：
  - 一般不要改
- 特别提醒：
  - 如果你的目标是“普通用户只走 Portal”，这里不要改成 `0.0.0.0`

### `ARTIFACTORY_ADMIN_PORT`
- 作用：
  - 管理后台端口
- 默认值：
```text
8082
```
- 什么时候改：
  - `8082` 被占用时

### `ARTIFACTORY_SERVICE_PORT`
- 作用：
  - 保留 Artifactory 另一条服务映射端口
- 默认值：
```text
8081
```
- 一般要不要改：
  - 没有明确冲突时不要改

### `PORTAL_PORT`
- 作用：
  - 普通用户访问 Portal 的端口
- 默认值：
```text
8080
```
- 什么时候改：
  - `8080` 被占用时

---

## 3. 账号和密码

### `ARTIFACTORY_ADMIN_USER`
- 作用：
  - 后台管理员用户名
- 默认值：
```text
admin
```
- 一般要不要改：
  - 一般不改用户名

### `ARTIFACTORY_ADMIN_PASSWORD`
- 作用：
  - 后台管理员密码
- 默认值：
```text
Aa123456
```
- 一般什么时候改：
  - 正式交付前建议改
- 改完以后要不要额外执行命令：
  - 只要你后面仍按标准流程执行 `install-or-update.sh` 和 `start.sh`，脚本会自动使用新值
- 如果你是服务已经部署完后才临时改这个值：
```bash
bash scripts/prepare-host.sh
bash scripts/stop.sh
bash scripts/start.sh
```

### `PORTAL_USERNAME`
- 作用：
  - Portal 普通用户用户名
- 默认值：
```text
user
```
- 一般要不要改：
  - 可以不改

### `PORTAL_PASSWORD`
- 作用：
  - Portal 普通用户密码
- 默认值：
```text
user
```
- 一般什么时候改：
  - 交付给真实用户前建议改

---

## 4. 数据库参数

### `POSTGRES_DB`
### `POSTGRES_USER`
### `POSTGRES_PASSWORD`
- 作用：
  - 给 Artifactory 后台元数据提供 PostgreSQL 存储
- 一般要不要改：
  - 一般不要改
- 什么时候才改：
  - 你明确要接现有 PostgreSQL 策略，或者现场安全规范要求你换数据库密码

---

## 5. 业务仓库和业务路径

### `CONTENT_REPOSITORY_KEY`
- 作用：
  - 业务文件真正写入的 Artifactory 本地仓库 key
- 默认值：
```text
lan-drop-local
```
- 改完会影响什么：
  - 影响后台仓库名
  - 影响 Portal 最终上传和下载落点
- 如果自动建仓失败：
  - 你要在后台手工建一个同名 Generic Local repository

### `FIRMWARE_PREFIX`
- 作用：
  - 刷机包一级路径前缀
- 默认值：
```text
firmware
```
- 一般要不要改：
  - 一般不要改

### `PATCH_PREFIX`
- 作用：
  - patch 包一级路径前缀
- 默认值：
```text
patch
```
- 一般要不要改：
  - 一般不要改

默认最终路径就是：
- `lan-drop-local/firmware/...`
- `lan-drop-local/patch/...`

---

## 最常见的修改场景

## 场景一：8080 被占用
只改：
```text
PORTAL_PORT=18080
```
改完以后普通用户访问：
```text
http://主机IP:18080
```

## 场景二：8082 被占用
只改：
```text
ARTIFACTORY_ADMIN_PORT=18082
```
改完以后管理员访问：
```text
http://127.0.0.1:18082
```

## 场景三：你要换普通用户密码
只改：
```text
PORTAL_PASSWORD=你想要的新密码
```

## 场景四：你要换后台管理员密码
只改：
```text
ARTIFACTORY_ADMIN_PASSWORD=你想要的新密码
```

如果你是在部署前改，后面直接继续正常执行：
```bash
bash scripts/install-or-update.sh
bash scripts/start.sh
```

如果你是在部署后才改，建议执行：
```bash
bash scripts/prepare-host.sh
bash scripts/stop.sh
bash scripts/start.sh
```

## 场景五：你要换业务仓库名
改：
```text
CONTENT_REPOSITORY_KEY=新的仓库名
```

改完以后：
- 自动建仓成功时，脚本会用新名字创建
- 自动建仓失败时，你需要去后台手工建同名 Generic 仓库

---

## 最后一个实用建议

如果你不是在做正式定制，第一次部署最稳的做法是：
1. 只确认端口和密码
2. 其他参数保持默认
3. 先把服务跑起来
4. 服务跑通以后再做更细的现场调整
