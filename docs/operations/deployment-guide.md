# 部署操作手册

## 一句话说明
- 这份文档是“用户把仓库拉下来以后，照着一步一步操作，就能把服务部署起来并马上开始用”的现场步骤单。

## 它在这个项目里代表什么
- 在这个项目里，它等于“现场清单”。
- 也就是说，使用者不用先理解 JFrog、Compose、Portal 这些概念，只要按顺序做，就能把服务部署起来。

## 它解决什么问题
- 解决“仓库已经拿到了，但不知道先改什么、先执行哪条命令、每一步做完应该看到什么”的问题。

## 它不是什么
- 它不是架构文档。
- 它不是源码解读。
- 它不是给开发者自己看的实现笔记。

---

## 1. 你拉下仓库以后，先按这 7 步做

如果你只想“拿到仓库后马上部署”，不要先到处翻文件，直接按下面做。

### 第 1 步：克隆仓库
```bash
git clone <你的仓库地址> jfrog-artifactory-lan
cd jfrog-artifactory-lan
```

做完以后，你应该能在当前目录看到这些关键内容：
- `.env.example`
- `docker-compose.yml`
- `scripts/`
- `docs/`
- `portal/`

### 第 2 步：确认主机环境
你至少需要这些软件：
- Docker
- Docker Compose 插件，也就是 `docker compose`
- `bash`
- `curl`
- `python3`
- `node`

逐条执行：
```bash
docker --version
docker compose version
bash --version
curl --version
python3 --version
node --version
```

判断方法：
- 这些命令都能正常返回版本号，说明环境达标
- 如果任何一条报“命令不存在”，先补环境，不要继续

### 第 3 步：复制配置模板
```bash
cp .env.example .env
```

做完以后，当前目录会多一个 `.env` 文件。  
后面所有部署脚本都读取这个文件。

### 第 4 步：先改 `.env` 里最关键的参数

第一次部署时，先只看这几个参数：

1. `PORTAL_PORT`
   - 普通用户访问 Portal 的端口
   - 默认是 `8080`
   - 如果 `8080` 被占用，就改成别的，比如 `18080`

2. `ARTIFACTORY_ADMIN_PORT`
   - 管理员本机访问后台的端口
   - 默认是 `8082`
   - 如果 `8082` 被占用，就改掉

3. `ARTIFACTORY_ADMIN_PASSWORD`
   - 后台管理员密码
   - 默认是 `Aa123456`
   - 正式交付前建议改

4. `PORTAL_PASSWORD`
   - 普通用户 Portal 密码
   - 默认是 `user`
   - 正式交付前建议改

5. `CONTENT_REPOSITORY_KEY`
   - 业务文件真实写入的 Artifactory 仓库名
   - 默认是 `lan-drop-local`
   - 如果你们现场有固定命名要求，这里改成你们自己的名字

如果你不确定其他值，不要乱改。  
其他参数的详细解释看：
- [config-explained.md](/workspaces/jfrog-artifactory-lan/docs/reference/config-explained.md)

### 第 5 步：准备宿主机目录并下载上游包
```bash
bash scripts/install-or-update.sh
```

这一步会做什么：
1. 读取 `.env` 里的 `ARTIFACTORY_VERSION`
2. 检查本地 `vendor/upstream/` 里有没有这个版本的官方包
3. 如果没有，就从 JFrog 官方下载
4. 创建本地持久化目录
5. 渲染后台启动前需要的 bootstrap 文件

你应该关注的结果：
- 没报错退出
- `vendor/upstream/` 里出现对应版本包
- `data/` 目录被创建出来

### 第 6 步：启动整套服务
```bash
bash scripts/start.sh
```

这一步内部会自动做这些动作：
1. 再次确认当前版本包已准备好
2. 启动 PostgreSQL
3. 启动 Artifactory
4. 启动 Portal
5. 等待 Artifactory 健康
6. 尝试自动创建 `CONTENT_REPOSITORY_KEY` 指定的 Generic 仓库
7. 写入两个业务目录的引导标记

### 第 7 步：查看状态
```bash
bash scripts/status.sh
```

你应该看到这几类信息：
- Portal 地址
- Artifactory 后台地址
- 如果 Docker 可用，会看到 `docker compose ps` 状态
- Portal health
- Artifactory health
- 最新备份文件路径（如果已有备份）

---

## 2. 这套系统最终会提供什么

部署成功后，你会得到三块东西：

### 2.1 管理后台
- 地址：`http://127.0.0.1:8082`
- 作用：管理员本机访问后台
- 账号：`admin / Aa123456`

### 2.2 普通用户入口
- 地址：`http://<这台机器的局域网IP>:8080`
- 作用：给局域网普通用户上传和下载刷机包、patch 包
- 账号：`user / user`

### 2.3 持久化目录
- `data/artifactory/var`
- `data/postgres/data`
- `data/backups`
- `vendor/upstream`

在项目语言里：
- 管理后台 = 管理员工作台
- Portal = 普通用户投递台
- 持久化目录 = 仓库盘和恢复材料

---

## 3. `.env` 应该怎么改

## 3.1 第一次部署通常只改这几项

### 如果端口没冲突
你可以保留：
```text
PORTAL_PORT=8080
ARTIFACTORY_ADMIN_PORT=8082
```

### 如果你要换密码
改：
```text
ARTIFACTORY_ADMIN_PASSWORD=你的后台管理员密码
PORTAL_PASSWORD=你的普通用户密码
```

### 如果你要换业务仓库名
改：
```text
CONTENT_REPOSITORY_KEY=你的仓库名
```

### 如果你什么都不想折腾
那就：
- 直接复制 `.env.example`
- 不改任何值
- 继续执行部署命令

## 3.2 哪些参数第一次不要乱动

第一次部署时，下面这些建议先别动：
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

原因：
- 这些大多是底座参数
- 你先把服务跑起来，比一上来做过多定制更重要

---

## 4. 每个脚本是干什么的

## `bash scripts/install-or-update.sh`
用途：
- 下载或确认上游包
- 准备宿主机目录
- 写启动前 bootstrap 文件

什么时候用：
- 第一次部署前
- 你改了版本后
- 你想重新确认本地包和目录状态时

## `bash scripts/start.sh`
用途：
- 启动 PostgreSQL、Artifactory、Portal
- 等待后台健康
- 自动做一次仓库 bootstrap

什么时候用：
- 正式启动整套服务时

## `bash scripts/status.sh`
用途：
- 查看配置好的访问地址
- 查看健康状态
- 查看备份信息

什么时候用：
- 每次启动后
- 你怀疑服务没起来时

## `bash scripts/stop.sh`
用途：
- 停止整套服务

## `bash scripts/backup-once.sh`
用途：
- 对当前 `.env`
- `data/artifactory/var`
- `data/postgres/data`

打一个压缩备份包

## `bash scripts/bootstrap-artifactory.sh`
用途：
- 补跑后台业务仓库初始化

什么时候用：
- `start.sh` 过程中自动建仓失败后
- 你手工在后台建完仓库后

## `bash scripts/validate.sh`
用途：
- 做仓库静态校验和测试

什么时候用：
- 你还没 Docker 环境时
- 你修改过仓库内容后想先做静态验证时

---

## 5. 部署成功怎么判断

## 5.1 对普通用户来说
在局域网其他电脑打开：
```text
http://<这台机器的局域网IP>:8080
```

成功标志：
- 能打开 Portal 页面
- 能看到两个区域：
  - 刷机镜像包
  - 补丁包
- 能用 `user / user` 或你改后的 Portal 账号登录
- 能上传
- 能下载

## 5.2 对管理员来说
在宿主机本机打开：
```text
http://127.0.0.1:8082
```

成功标志：
- 能用 `admin / 你设置的密码` 登录
- 后台里能看到 `CONTENT_REPOSITORY_KEY` 对应的仓库
- 仓库下面能对应到：
  - `firmware`
  - `patch`

---

## 6. 如果中间某一步失败了，先怎么判断

## 6.1 `install-or-update.sh` 失败
先检查：
```bash
curl -I https://releases.jfrog.io/
```

如果这里都不通：
- 先处理网络问题

## 6.2 `start.sh` 失败
先跑：
```bash
bash scripts/status.sh
```

然后再看：
- Portal health
- Artifactory health
- docker compose ps 输出

## 6.3 自动建仓失败
在宿主机本机打开后台：
```text
http://127.0.0.1:8082
```

手工创建：
- Local repository
- Generic
- Repository Key = `.env` 里的 `CONTENT_REPOSITORY_KEY`

然后执行：
```bash
bash scripts/bootstrap-artifactory.sh
```

更多故障处理看：
- [troubleshooting.md](/workspaces/jfrog-artifactory-lan/docs/operations/troubleshooting.md)

---

## 7. 服务起来以后日常怎么用

## 普通用户

### 上传刷机包
1. 打开 Portal
2. 进入“刷机镜像包”
3. 输入你要放的子路径
4. 选择文件
5. 点击上传

### 上传 patch 包
1. 打开 Portal
2. 进入“补丁包”
3. 输入你要放的子路径
4. 选择文件
5. 点击上传

### 下载
1. 打开 Portal
2. 进入对应区域
3. 点目录
4. 点文件下载

特别强调：
- 普通用户没有删除按钮
- 普通用户不要直接碰 Artifactory 后台

## 管理员

### 查看状态
```bash
bash scripts/status.sh
```

### 停服务
```bash
bash scripts/stop.sh
```

### 再启动
```bash
bash scripts/start.sh
```

### 手工做一次备份
```bash
bash scripts/backup-once.sh
```

---

## 8. 如果你要升级版本

## 正常重启，不升级版本
```bash
bash scripts/install-or-update.sh
bash scripts/start.sh
```

这代表：
- 继续使用 `.env` 里写死的版本
- 不会偷偷升级

## 明确要追上游最新版本
```bash
bash scripts/install-or-update.sh --track-latest
```

这代表：
- 主动去查 JFrog 官方最新版本
- 如果有更新，就改写 `.env` 里的 `ARTIFACTORY_VERSION`

---

## 9. 建议的交付方式

如果你是把这个仓库交给基础薄弱的同事，建议至少一起交付：
- 仓库代码
- 已经按现场情况改好的 `.env`
- 一份主机信息表

主机信息表至少写：
- 服务器 IP
- Portal 访问地址
- 管理后台本机访问地址
- 当前使用端口
- 当前使用密码保管方式
- 数据盘路径
- 备份目录路径

---

## 10. 看完这份文档以后，你下一步看什么
- 需要逐项看 `.env` 的含义：
  - [config-explained.md](/workspaces/jfrog-artifactory-lan/docs/reference/config-explained.md)
- 遇到启动失败、端口不通、建仓失败：
  - [troubleshooting.md](/workspaces/jfrog-artifactory-lan/docs/operations/troubleshooting.md)
