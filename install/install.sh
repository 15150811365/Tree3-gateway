#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

die() { printf '%s\n' "$*" >&2; exit 1; }
trap 'printf "安装在第 %s 行停止；未自动删除数据。\n" "$LINENO" >&2' ERR
[[ $EUID == 0 ]] || die '请用 sudo bash 执行此脚本。'
. /etc/os-release
[[ ${ID:-} == ubuntu ]] && dpkg --compare-versions "${VERSION_ID:-0}" ge 22.04 ||
  die '需要 Ubuntu 22.04 或更新版本。'
[[ $(dpkg --print-architecture) == amd64 ]] || die '当前安装包仅支持 x86_64 / amd64。'

installer_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd -- "${1:-$installer_dir/..}" && pwd)
target=/opt/tree3-gateway
bundle=packages/metacubexd-custom-1.273.1-docker-build.tar.gz
[[ ! -e $target && ! -L $target ]] || die "$target 已存在，未覆盖。"
[[ -f $repo/$bundle && -f $repo/SHA256SUMS ]] || die '请从完整的 Tree3-gateway 仓库运行。'
(
  cd "$repo"
  checksum=$(awk -v path="$bundle" '$2 == path { print $1 "  " $2 }' SHA256SUMS)
  [[ -n $checksum ]] || die '仓库缺少面板构建包的 SHA256。'
  printf '%s\n' "$checksum" | sha256sum -c -
)
ports=$(ss -H -ltn '( sport = :18080 or sport = :18081 or sport = :19090 )')
[[ -z $ports ]] || die '18080、18081 或 19090 已被占用，未安装。'
read -r -p 'Sub2API 管理员邮箱：' admin
[[ $admin =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] || die '请输入有效邮箱。'

export DOCKER_HOST=unix:///var/run/docker.sock
unset DOCKER_CONTEXT
if ! command -v docker >/dev/null; then
  [[ ! -e /etc/apt/sources.list.d/docker.sources && ! -e /etc/apt/keyrings/docker.asc ]] ||
    die '发现已有 Docker APT 配置，请先处理现有安装。'
  for pkg in docker.io docker-ce docker-ce-cli docker-compose docker-compose-v2 podman-docker containerd containerd.io runc; do
    if dpkg-query -W -f='${db:Status-Status}\n' "$pkg" 2>/dev/null | grep -qx installed; then
      die "发现已安装的 $pkg，未修改现有 Docker 环境。"
    fi
  done
  apt-get update
  apt-get install -y ca-certificates curl openssl
  install -m 0755 -d /etc/apt/keyrings
  key=$(mktemp)
  curl --proto '=https' -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$key"
  install -m 0644 "$key" /etc/apt/keyrings/docker.asc
  rm -f -- "$key"
  cat >/etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
EOF
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
fi
docker info >/dev/null || die '现有 Docker 守护进程不可用。'
docker compose version >/dev/null || die '现有 Docker 缺少 Compose 插件。'
[[ -z $(docker ps -a -q --filter label=com.docker.compose.project=tree3-gateway) &&
   -z $(docker volume ls -q --filter label=com.docker.compose.project=tree3-gateway) ]] ||
  die '发现同名 Compose 项目或数据卷，未覆盖。'
command -v openssl >/dev/null || die '缺少 openssl。'
if docker image inspect tree3-metacubexd-custom:1.273.1 >/dev/null 2>&1; then
  die '发现同名定制面板镜像，未覆盖。'
fi

mkdir -m 0700 -- "$target"
install -m 0644 "$installer_dir/compose.yaml" "$target/compose.yaml"
{
  printf 'ADMIN_EMAIL=%s\n' "$admin"
  for name in ADMIN_PASSWORD POSTGRES_PASSWORD REDIS_PASSWORD JWT_SECRET TOTP_ENCRYPTION_KEY CONTROL_TOKEN CLASH_SECRET; do
    value=$(openssl rand -hex 32)
    printf '%s=%s\n' "$name" "$value"
  done
} >"$target/.env"

docker build --pull -t tree3-metacubexd-custom:1.273.1 \
  --build-arg BASE_IMAGE=ghcr.io/metacubex/metacubexd-server:v1.273.1 \
  - <"$repo/$bundle"
docker compose --project-name tree3-gateway --env-file "$target/.env" \
  -f "$target/compose.yaml" up -d --wait --wait-timeout 300

printf '%s\n' 'Sub2API: http://127.0.0.1:18081' 'MetaCubeXD: http://127.0.0.1:18080' \
  '凭据文件：/opt/tree3-gateway/.env（仅 root 可读）'
