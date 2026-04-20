# 常见问题排查

## 一句话说明
- 这份文档不是解释原理，而是给现场人员快速判断“卡在哪一步、先看什么、先怎么处理”。

## 它在这个项目里代表什么
- 在这个项目里，它等于“故障分流表”。

## 它解决什么问题
- 解决“部署失败了，但不知道问题属于环境、配置、启动顺序还是业务仓库没建好”的问题。

## 它不是什么
- 它不是深入源码调试手册。
- 它不是 JFrog 官方故障全集。

---

## 问题 1：一开始就提示 `docker: command not found`

### 现象
- 运行脚本时直接报 `docker: command not found`

### 直接原因
- 当前主机没装 Docker，或者当前用户没有权限使用 Docker

### 根因
- 这个项目本质上是 Docker Compose 部署项目，底座缺失时，后面的配置和文档都无法真正落地

### 为什么以前没暴露
- 很多开发环境能跑 `python3` 和 `node`，但不代表它具备容器运行条件

### 处理
先执行：
```bash
docker --version
docker compose version
```

如果任一失败，先补环境，不要继续排业务问题。

---

## 问题 2：`install-or-update.sh` 下载失败

### 现象
- 下载上游包时报错
- `vendor/upstream/` 下没有目标版本包

### 直接原因
- 当前主机访问 JFrog 官方上游失败

### 根因
- 这是网络连通性问题，不是项目逻辑问题

### 处理
先试：
```bash
curl -I https://releases.jfrog.io/
```

如果这里都不通，先处理网络。

---

## 问题 3：`start.sh` 能跑，但访问 `8080` 打不开

### 现象
- 启动命令没有明显报错
- 但浏览器访问 Portal 地址失败

### 直接原因
- Portal 容器没起来，或者宿主机端口没开放，或者服务还没完全启动

### 根因
- 访问入口依赖 compose 服务状态，而不是只依赖脚本有没有退出

### 处理
先看：
```bash
bash scripts/status.sh
```

如果有 Docker：
```bash
docker compose ps
docker compose logs portal --tail=200
```

---

## 问题 4：Portal 能打开，但上传失败

### 现象
- 页面能进
- 登录也正常
- 但上传时报错

### 直接原因
- Portal 到 Artifactory 的后台写入失败

### 根因
常见是这三类：
1. `CONTENT_REPOSITORY_KEY` 对应的仓库不存在
2. Artifactory 还没完全健康
3. 管理员密码与 bootstrap 渲染结果不一致

### 处理顺序
1. 先看后台仓库是否存在：
   - `lan-drop-local`
2. 再看 bootstrap 脚本是否成功：
```bash
bash scripts/bootstrap-artifactory.sh
```
3. 再看 Portal 日志：
```bash
docker compose logs portal --tail=200
```

---

## 问题 5：自动建仓失败

### 现象
- 启动流程卡在 bootstrap
- 提示自动创建 `lan-drop-local` 失败

### 直接原因
- 当前 Artifactory 实例不接受自动建仓 API 请求

### 根因
- 不同版本、不同构建形态、不同接口能力边界下，自动建仓行为可能不完全一致

### 为什么会这样设计
- 项目优先追求“能自动就自动”
- 但也必须给出一条稳定人工回退路径，避免整个项目只能赌 API 行为

### 处理
从浏览器打开后台：
```text
http://<主机IP>:8082
```

创建：
- Local repository
- Generic
- key = `lan-drop-local` 或 `.env` 中配置的 `CONTENT_REPOSITORY_KEY`

然后重跑：
```bash
bash scripts/bootstrap-artifactory.sh
```

---

## 问题 6：备份目录一直增长

### 现象
- 担心备份越来越多，空间不够

### 直接原因
- 可能是人工额外拷贝了旧备份，或者备份策略被改过

### 根因
- 项目默认策略其实只保留一代，但现场运维动作可能绕过脚本本身

### 处理
先看：
```bash
find data/backups -maxdepth 1 -type f | sort
```

如果超过一份，说明有人在脚本之外保留了额外文件。

---

## 问题 7：改了 `.env` 以后感觉不生效

### 现象
- 改了密码、仓库名或者端口
- 但运行结果和预期不一致

### 直接原因
- 你只改了 `.env`，但没有重新执行目录准备或启动流程

### 根因
- 部分配置会影响启动前生成的文件，而不是只影响运行时环境变量

### 处理
建议顺序：
```bash
bash scripts/prepare-host.sh
bash scripts/stop.sh
bash scripts/start.sh
```

---

## 最后一个判断原则

如果你分不清是“配置问题”还是“环境问题”，先看这三件事：
1. Docker 有没有
2. `.env` 有没有改对
3. 后台仓库 `lan-drop-local` 有没有存在

这三件事先确定，绝大多数现场问题都会收敛到明确方向。
