#!/bin/sh

# 确保脚本以 root 权限运行
if [ "$(id -u)" != "0" ]; then
    echo "错误: 请使用 root 权限运行此脚本。"
    exit 1
fi

# 1. 提示用户输入 Cloudflare Tunnel Token
printf "请输入你的 Cloudflare Tunnel Token: "
read TOKEN

# 检查输入是否为空
if [ -z "$TOKEN" ]; then
    echo "错误: Token 不能为空，部署已取消。"
    exit 1
fi

# 2. 判断架构并从 GitHub 下载对应版本的 cloudflared
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    echo "检测到 amd64 架构..."
    URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    echo "检测到 arm64 架构..."
    URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

# 统一保存为 /usr/local/bin/cf
BIN_PATH="/usr/local/bin/cf"
echo "正在从 GitHub 下载 cloudflared 并改名为 cf..."
wget -O "$BIN_PATH" "$URL"
chmod +x "$BIN_PATH"

# 3. 判断操作系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法检测操作系统版本"
    exit 1
fi

echo "检测到操作系统: $OS"

# 4. 配置并启动后台服务
if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
    # 配置 systemd 服务 (Debian/Ubuntu)
    cat > /etc/systemd/system/cf.service <<EOF
[Unit]
Description=Cloudflare Tunnel Service
After=network.target

[Service]
Type=simple
ExecStart=$BIN_PATH tunnel run --token $TOKEN --protocol http2
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable cf
    systemctl restart cf
    echo "cf 服务已通过 systemd 启动。"

elif [ "$OS" = "alpine" ]; then
    # 配置 OpenRC 服务 (Alpine)
    cat > /etc/init.d/cf <<EOF
#!/sbin/openrc-run

name="cf"
description="Cloudflare Tunnel Service"
command="$BIN_PATH"
command_args="tunnel run --token $TOKEN --protocol http2"
command_background=true
pidfile="/run/\$RC_SVCNAME.pid"
EOF

    chmod +x /etc/init.d/cf
    rc-update add cf default
    rc-service cf restart
    echo "cf 服务已通过 OpenRC 启动。"

else
    echo "不支持的系统: $OS，当前仅支持 debian, ubuntu, alpine。"
    exit 1
fi

echo "部署完成！Argo Tunnel (cf) 正在后台运行。"
