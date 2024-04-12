#!/bin/bash

# 设置输出颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

cat << "EOF"
┌─────────────────────────────────────────────────────────┐
│  ██████╗ ██╗   ██╗████████╗██╗  ██╗ ██████╗ ███╗   ██╗  │
│  ██╔══██╗╚██╗ ██╔╝╚══██╔══╝██║  ██║██╔═══██╗████╗  ██║  │
│  ██████╔╝ ╚████╔╝    ██║   ███████║██║   ██║██╔██╗ ██║  │
│  ██╔═══╝   ╚██╔╝     ██║   ██╔══██║██║   ██║██║╚██╗██║  │
│  ██║        ██║      ██║   ██║  ██║╚██████╔╝██║ ╚████║  │
│  ╚═╝        ╚═╝      ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝  │
│           ${GREEN}$Code By Syn blog:https://sysy.su              │
└─────────────────────────────────────────────────────────┘
EOF

# 函数：检查和尝试安装 'sudo'
ensure_sudo() {
    if ! command -v sudo &> /dev/null; then
        echo -e "${YELLOW}sudo 未安装, 正在尝试以 root 权限安装 sudo...${NC}"
        # 尝试以 root 用户身份安装 sudo
        su -c 'apt-get update && apt-get install -y sudo' &> /dev/null
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}sudo 安装成功。${NC}"
        else
            echo -e "${RED}尝试安装 sudo 失败。请以 root 用户手动执行：apt-get install sudo${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}sudo 命令已安装。${NC}"
    fi
}

# 函数：检查和安装 'wget' 和 'tar' 如果它们不在系统上
check_and_install_utilities() {
    echo -e "${GREEN}检查必要的工具(wget, tar)...${NC}"
    required_utilities=("wget" "tar")
    for util in "${required_utilities[@]}"; do
        if ! command -v $util &> /dev/null; then
            echo -e "${YELLOW}$util 未安装, 正在尝试安装 $util...${NC}"
            if ! sudo apt-get install -y $util 2>/dev/null; then
                echo -e "${RED}尝试安装 $util 失败。请尝试手动安装：sudo apt-get install $util${NC}"
                exit 1
            else
                echo -e "${GREEN}$util 安装完成。${NC}"
            fi
        else
            echo -e "${GREEN}$util 已安装。${NC}"
        fi
    done
}

# 函数：安装依赖
install_dependencies() {
    echo -e "${GREEN}正在安装依赖...${NC}"
    if ! sudo apt-get update; then
        echo -e "${RED}更新软件包列表失败，正在退出...${NC}"
        exit 1
    fi

    dependencies=("build-essential" "zlib1g-dev" "libncurses5-dev" "libgdbm-dev" "libnss3-dev" "libssl-dev" "libreadline-dev" "libffi-dev")
    for dep in "${dependencies[@]}"; do
        if ! sudo apt-get install -y $dep; then
            echo -e "${RED}安装 $dep 失败，正在退出...${NC}"
            exit 1
        else
            echo -e "${GREEN}$dep 安装成功。${NC}"
        fi
    done
    echo -e "${GREEN}所有依赖安装完成。${NC}"
}

# 函数：下载 Python
download_python() {
    echo -e "${GREEN}正在下载 Python $1...${NC}"
    if ! wget "https://www.python.org/ftp/python/$1/Python-$1.tgz"; then
        echo -e "${RED}下载 Python $1 失败，请检查网络连接或版本号。${NC}"
        exit 1
    fi
    if ! tar -xzf "Python-$1.tgz"; then
        echo -e "${RED}解压 Python $1 失败。${NC}"
        exit 1
    fi
    echo -e "${GREEN}下载完成。${NC}"
}

# 函数：编译和安装 Python
compile_python() {
    echo -e "${GREEN}正在编译 Python $1...${NC}"
    cd "Python-$1" || { echo -e "${RED}无法进入目录 Python-$1${NC}"; exit 1; }
    if ! ./configure --enable-optimizations; then
        echo -e "${RED}配置 Python $1 失败。${NC}"
        cd ..
        exit 1
    fi
    if ! make -j $(nproc); then
        echo -e "${RED}编译 Python $1 失败。${NC}"
        cd ..
        exit 1
    fi
    if ! sudo make altinstall; then
        echo -e "${RED}安装 Python $1 失败。${NC}"
        cd ..
        exit 1
    fi
    echo -e "${GREEN}Python $1 安装完成。${NC}"
    cd ..
    rm -rf "Python-$1" "Python-$1.tgz"
}

# 脚本主体开始
ensure_sudo
check_and_install_utilities
install_dependencies

# 获取可用的 Python 版本，从3.5开始
echo -e "${GREEN}获取可用的 Python 版本...${NC}"
VERSIONS=$(wget -qO- https://www.python.org/ftp/python/ | grep -oP 'href="\K3\.\d+(?:\.\d+)?(?=/")' | sort -V | awk -F. '{ if (($1 == 3 && $2 >= 5) || $1 > 3) print $0 }' | awk -F. -v OFS="." '{seen[$1 "." $2] = ($3 > seen[$1 "." $2] || seen[$1 "." $2] == "") ? $3 : seen[$1 "." $2]} END {for (version in seen) print version, seen[version]}' | sort -t. -k1,1n -k2,2n -k3,3r)

echo -e "${GREEN}可选的 Python 版本：${NC}"
select VERSION in $VERSIONS; do
    if [[ -n "$VERSION" ]]; then
        echo -e "${GREEN}你选择了 Python $VERSION${NC}"
        download_python $VERSION
        compile_python $VERSION
        break
    else
        echo -e "${RED}无效选择，请重新选择。${NC}"
    fi
done

echo -e "${GREEN}脚本执行完毕。${NC}"
