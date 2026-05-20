#!/bin/sh

# 确保脚本以 root 权限运行
if [ "$(id -u)" != "0" ]; then
    echo "错误: 请使用 root 权限运行此脚本。"
    exit 1
fi

# 1. 提示用户输入端口号
printf "请输入要使用的端口号 (例如 2096): "
read PORT

# 检查输入是否为空
if [ -z "$PORT" ]; then
    echo "错误: 端口号不能为空，部署已取消。"
    exit 1
fi

# 2. 提示用户输入协议
printf "请输入要使用的协议 (ws 或 wss, 默认回车为 ws): "
read PROTOCOL

# 如果为空则默认使用 ws
if [ -z "$PROTOCOL" ]; then
    PROTOCOL="ws"
fi

# 检查协议格式是否正确
if [ "$PROTOCOL" != "ws" ] && [ "$PROTOCOL" != "wss" ]; then
    echo "错误: 协议只能是 ws 或 wss，部署已取消。"
    exit 1
fi

echo "将使用 $PROTOCOL 协议和端口 $PORT 进行部署..."

# 3. 判断架构并下载对应二进制文件
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    echo "检测到 amd64 架构..."
    URL="https://github.com/fbrav530/one-myweb64/raw/refs/heads/main/app/xts"
elif [ "$ARCH" = "aarch64" ]; then
    echo "检测到 arm64 架构..."
    URL="https://github.com/fbrav530/one-myweb64/raw/refs/heads/main/app/xtsa"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

# 统一保存为 /usr/local/bin/xts 方便管理
BIN_PATH="/usr/local/bin/xts"
echo "正在下载文件..."
wget -O "$BIN_PATH" "$URL"
chmod +x "$BIN_PATH"

# 4. 判断操作系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法检测操作系统版本"
    exit 1
fi

echo "检测到操作系统: $OS"

# 5. 配置并启动后台服务
if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
    # 配置 systemd 服务 (Debian/Ubuntu)
    cat > /etc/systemd/system/xts.service <<EOF
[Unit]
Description=XTS Service
After=network.target

[Service]
Type=simple
ExecStart=$BIN_PATH -l ${PROTOCOL}://:$PORT/ggjj -token sliao530
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable xts
    systemctl restart xts
    echo "xts 服务已通过 systemd 启动。"

elif [ "$OS" = "alpine" ]; then
    # 配置 OpenRC 服务 (Alpine)
    cat > /etc/init.d/xts <<EOF
#!/sbin/openrc-run

name="xts"
description="XTS Proxy Service"
command="$BIN_PATH"
command_args="-l ${PROTOCOL}://:$PORT/ggjj -token sliao530"
command_background=true
pidfile="/run/\$RC_SVCNAME.pid"
EOF

    chmod +x /etc/init.d/xts
    rc-update add xts default
    rc-service xts restart
    echo "xts 服务已通过 OpenRC 启动。"

else
    echo "不支持的系统: $OS，当前仅支持 debian, ubuntu, alpine。"
    exit 1
fi

echo "部署完成！XTS 正在后台运行，当前监听地址为: ${PROTOCOL}://:$PORT/ggjj"
