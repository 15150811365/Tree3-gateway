# Tree3-gateway

Tree3 中转站的开源组件源码和定制网络面板构建包。本仓库不包含服务器配置、真实订阅链接、账号凭据、数据库、日志或运行数据。

| 组件 | 随包版本 | 上游 |
| --- | --- | --- |
| Sub2API | 0.2.21 | [Wei-Shaw/sub2api](https://github.com/Wei-Shaw/sub2api/releases/tag/v0.2.21) |
| MetaCubeXD 定制面板 | 基于 1.273.1（上游提交 `8bbc8f5`） | [MetaCubeX/metacubexd](https://github.com/MetaCubeX/metacubexd/releases/tag/v1.273.1) |
| Mihomo | 1.19.27（原面板内置核心对应源码）、1.19.33（独立代理） | [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo/releases) |
| Docker Engine / CLI | 29.9.3 | [Moby](https://github.com/moby/moby/releases/tag/docker-v29.9.3) / [Docker CLI](https://github.com/docker/cli/tree/v29.9.3) |
| Docker Compose | 5.7.1 | [docker/compose](https://github.com/docker/compose/releases/tag/v5.7.1) |
| PostgreSQL | 18.7 | [PostgreSQL](https://www.postgresql.org/ftp/source/v18.7/) |
| Redis | 8.10.3 | [redis/redis](https://github.com/redis/redis/releases/tag/8.10.3) |
| Docker 运行时依赖 | containerd 2.4.2、runc 1.5.2、Tini 0.19.0 | [containerd](https://github.com/containerd/containerd/tree/v2.4.2) / [runc](https://github.com/opencontainers/runc/tree/v1.5.2) / [Tini](https://github.com/krallin/tini/tree/v0.19.0) |

以上是归档版本，不代表旧服务器已升级。官方容器镜像与构建配方由上游维护：[PostgreSQL 镜像](https://github.com/docker-library/postgres)、[Redis 镜像](https://github.com/redis/docker-library-redis)。各源码包保留上游许可证。

## 在新服务器上一键安装

适用环境：**Ubuntu 22.04 LTS 或更新版本（x86_64 / amd64）**，拥有 root 或 sudo 权限。服务器须能访问 GitHub、Docker 镜像仓库；未装 Docker 时还须能访问 Docker 官方 APT 源。

在新服务器的 Bash 终端粘贴：

```bash
(
  set -e
  admin=()
  if [ "$(id -u)" -ne 0 ]; then admin=(sudo); fi
  if ! command -v git >/dev/null; then
    "${admin[@]}" apt-get update
    "${admin[@]}" apt-get install -y git ca-certificates
  fi
  dir=$(mktemp -d)
  git clone --depth 1 --branch main https://github.com/jasonmin1365/Tree3-gateway.git "$dir/tree3-gateway"
  "${admin[@]}" bash "$dir/tree3-gateway/install/install.sh"
)
```

按提示输入 Sub2API 管理员邮箱。安装器使用仓库里的定制面板构建包，部署 Sub2API 0.2.21、MetaCubeXD/Mihomo、PostgreSQL 和 Redis。管理员密码（`ADMIN_PASSWORD`）和面板连接密钥（`CLASH_SECRET`）在新机生成，保存在仅 root 可读的 `/opt/tree3-gateway/.env`。已有安装目录或端口冲突时停止，不覆盖旧数据。

管理端口默认只绑定服务器的回环地址。在**你的电脑**运行下面的命令，将 `user@SERVER` 换成新服务器的 SSH 用户和地址：

```bash
ssh -N -L 18081:127.0.0.1:18081 -L 18080:127.0.0.1:18080 -L 19090:127.0.0.1:19090 user@SERVER
```

- Sub2API：`http://127.0.0.1:18081`；登录后添加上游账号。
- 定制面板：`http://127.0.0.1:18080`；如需代理，导入并激活配置，在 Sub2API 里给对应账号填写 `http://mihomo:监听端口`。
- Codex 可在项目中调用 [`$tree3-gateway-install`](.agents/skills/tree3-gateway-install/SKILL.md) 按同一流程部署。安装器不迁移旧账号、数据库或订阅。

## 使用归档

- `packages/sub2api-v0.2.21.tar.gz` 是 GitHub 标签 `v0.2.21` 的源码归档，包含 `deploy/` 中的官方 Compose 和配置示例。使用官方 Compose 示例时，把 Sub2API 的镜像固定为 `ghcr.io/wei-shaw/sub2api:0.2.21`，避免随 `latest` 漂移。
- `packages/metacubexd-custom-1.273.1-source.tar.gz` 是定制面板源码，包含 SOCKS5 链接自动拆分、可选链式代理和可编辑的多监听入口。
- `packages/metacubexd-custom-1.273.1-docker-build.tar.gz` 是定制面板的 Docker 构建上下文，包含已构建的前端与 Dockerfile，不是 Docker 镜像导出。可以用 `docker build -t tree3-metacubexd-custom:1.273.1 - < packages/metacubexd-custom-1.273.1-docker-build.tar.gz` 构建；需要先具备 Docker 和对应基础镜像的访问权限。
- `SHA256SUMS` 对应归档文件。将实际凭据和运行配置保存在部署机器，不要提交到此仓库。
