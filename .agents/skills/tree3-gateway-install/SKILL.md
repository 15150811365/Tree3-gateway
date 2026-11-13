---
name: tree3-gateway-install
description: 在全新的 Ubuntu 22.04 LTS 及以上 x86_64 服务器上，从 Tree3-gateway GitHub 仓库一键安装 Sub2API、定制 MetaCubeXD/Mihomo 和数据库依赖。用于换服务器或全新部署，不用于覆盖现有实例、迁移数据或升级。
---

# Tree3 中转站安装

- 仓库：`https://github.com/jasonmin1365/Tree3-gateway.git`。若改为私有，先在新机配置 Git 认证或只读部署密钥，不把令牌写入命令、仓库或聊天。
- 使用下方命令前，先获得用户对目标新机及安装动作的批准。按用户指定的终端执行；用户要手动时只提供命令。不要在旧机或当前开发机试跑安装器。

```bash
(set -e; admin=(); if [ "$(id -u)" -ne 0 ]; then admin=(sudo); fi; if ! command -v git >/dev/null; then "${admin[@]}" apt-get update && "${admin[@]}" apt-get install -y git ca-certificates || exit 1; fi; dir=$(mktemp -d); git clone --depth 1 --branch main https://github.com/jasonmin1365/Tree3-gateway.git "$dir/tree3-gateway"; "${admin[@]}" bash "$dir/tree3-gateway/install/install.sh")
```

安装器提示输入管理员邮箱，在新机生成凭据，默认安装到 `/opt/tree3-gateway`。需要访问界面时，在客户端建立 SSH 转发：

```bash
ssh -N -L 18081:127.0.0.1:18081 -L 18080:127.0.0.1:18080 -L 19090:127.0.0.1:19090 用户@新服务器
```

- Sub2API：`http://127.0.0.1:18081`；面板：`http://127.0.0.1:18080`。管理员密码和 Mihomo API 密钥保存在新机 `/opt/tree3-gateway/.env`（仅 root 可读）。只在新机查看，不输出到对话。
- 新机需能访问 GitHub、Docker 镜像仓库，未安装 Docker 时还需访问 Docker 官方 APT 源。已有安装目录、冲突端口或不完整 Docker 环境时停止，不覆盖，也不自动卸载。
- 安装后由用户添加上游凭据；需要代理时在定制面板导入并激活配置，再在 Sub2API 中按账号配置 `http://mihomo:监听端口`。两服务在同一 Docker 网络；不自动迁移账号、数据库或订阅，也不公开代理监听。
