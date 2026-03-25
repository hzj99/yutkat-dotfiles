#!/usr/bin/env bash
#
# === 脚本功能 ===
# 本脚本用于设置和管理 Nix 环境，支持以下功能：
# - 在不同操作系统上安装和配置 Nix 包管理器
# - 支持单用户模式和多用户模式安装
# - 启用 Nix flakes 功能
# - 安装 Home Manager（独立模式）
# - 完整卸载 Nix 及其相关组件
# - 清理无效符号链接
#
# === 版本信息 ===
# 版本：1.0.0
# 最后更新日期：2026-03-25
#
# === 依赖环境 ===
# - bash 4.0+
# - curl（用于下载 Nix 安装脚本）
# - sudo（用于多用户模式安装）
# - systemctl（用于多用户模式管理 Nix 守护进程）
#
# === 注意事项 ===
# - 执行本脚本可能需要管理员权限（多用户模式）
# - 卸载操作会完全移除 Nix 及其所有组件，无法恢复
# - 单用户模式适用于 Docker 容器、开发环境、无 systemd 的系统或非 root 安装

set -e

# === 颜色定义 ===
# 用于输出格式化，增强用户体验
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === 全局变量 ===
SINGLE_USER_MODE=false

# === 日志函数 ===
# 提供统一的日志输出格式，便于区分不同类型的消息
log_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# === 操作系统检测 ===
# 检测当前系统类型，用于后续的针对性配置
detect_os() {
    if [[ -f /etc/NIXOS ]]; then
        echo "nixos"
    elif [[ -d /nix/store ]] && command_exists nix; then
        echo "nixos-container"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

# === 命令存在性检查 ===
# 检查指定命令是否存在于系统中
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# === 帮助信息显示 ===
# 显示脚本的使用方法和选项说明
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --single       以单用户模式安装 Nix（无守护进程）"
    echo "  --uninstall    完全卸载 Nix 并移除无效符号链接"
    echo "  --help, -h     显示此帮助信息"
    echo ""
    echo "默认行为（无选项）:"
    echo "  为基于 flake 的配置设置 Nix 环境（多用户模式）"
    echo ""
    echo "示例:"
    echo "  $0                 # 设置 Nix 环境（多用户）"
    echo "  $0 --single        # 设置 Nix 环境（单用户）"
    echo "  $0 --uninstall     # 卸载 Nix 并清理"
    echo "  $0 --help          # 显示此帮助"
    echo ""
    echo "单用户模式推荐用于:"
    echo "  • Docker 容器"
    echo "  • 开发环境"
    echo "  • 无 systemd 的系统"
    echo "  • 非 root 安装"
}

# === 移除无效符号链接 ===
# 清理指定目录中的无效符号链接，避免系统中存在指向不存在文件的链接
remove_dead_symlinks() {
    local directories=("$@")

    log_info "正在移除主目录中的无效符号链接..."

    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "检查目录中的无效符号链接: $dir"

            # 查找并移除无效符号链接
            # 注：find 命令查找类型为链接(! -exec test -e {} \;)且不存在的文件并打印
            local dead_links=$(find "$dir" -type l ! -exec test -e {} \; -print 2>/dev/null || true)

            if [[ -n "$dead_links" ]]; then
                echo "$dead_links" | while IFS= read -r link; do
                    if [[ -n "$link" ]]; then
                        log_info "移除无效符号链接: $link"
                        rm -f "$link"
                    fi
                done
                log_success "已从 $dir 移除无效符号链接"
            else
                log_info "在 $dir 中未发现无效符号链接"
            fi
        else
            log_info "目录不存在: $dir"
        fi
    done
}

# === 卸载 Nix（多用户模式） ===
# 完全卸载多用户模式下的 Nix 及其相关组件
uninstall_nix_multiuser() {
    log_info "正在卸载 Nix（多用户模式）..."

    # 尝试使用 nix-installer 卸载（如果可用）
    if [[ -x /nix/nix-installer ]]; then
        log_info "使用 nix-installer 进行干净卸载..."
        if sudo /nix/nix-installer uninstall; then
            log_success "使用 nix-installer 成功卸载 Nix"
            return 0
        else
            log_warning "nix-installer 失败，回退到手动方法"
        fi
    fi

    # 手动多用户卸载
    log_info "执行手动多用户卸载..."

    # 停止守护进程
    if systemctl is-active --quiet nix-daemon 2>/dev/null; then
        sudo systemctl stop nix-daemon
        sudo systemctl disable nix-daemon
        log_success "Nix 守护进程已停止并禁用"
    fi

    # 移除 systemd 文件
    sudo rm -f /etc/systemd/system/nix-daemon.service
    sudo rm -f /etc/systemd/system/nix-daemon.socket
    sudo rm -f /etc/systemd/system/multi-user.target.wants/nix-daemon.service
    sudo systemctl daemon-reload

    # 移除 nixbld 用户
    for i in $(seq 1 32); do
        if id "nixbld$i" &>/dev/null; then
            sudo userdel "nixbld$i"
            log_info "已移除用户 nixbld$i"
        fi
    done

    if getent group nixbld &>/dev/null; then
        sudo groupdel nixbld
        log_success "已移除组 nixbld"
    fi

    # 移除 Nix 存储
    sudo rm -rf /nix
    log_success "Nix 存储已移除"

    # 清理系统配置文件
    local system_profiles=(
        "/etc/bashrc"
        "/etc/profile.d/nix.sh"
        "/etc/zshrc"
        "/etc/bash.bashrc"
        "/etc/zsh/zshrc"
    )

    for profile in "${system_profiles[@]}"; do
        if [[ -f "$profile" ]]; then
            sudo sed -i.bak-before-nix-removal '/nix/d' "$profile" 2>/dev/null || true
            log_info "已清理 $profile"
        fi
    done

    # 移除备份文件
    sudo rm -f /etc/bash.bashrc.backup-before-nix
    sudo rm -f /etc/bashrc.backup-before-nix
    sudo rm -f /etc/profile.backup-before-nix
    sudo rm -f /etc/zsh/zshrc.backup-before-nix
    sudo rm -f /etc/zshrc.backup-before-nix
}

# === 卸载 Nix（单用户模式） ===
# 卸载单用户模式下的 Nix
uninstall_nix_singleuser() {
    log_info "正在卸载 Nix（单用户模式）..."

    # 移除 Nix 存储（用户所有）
    rm -rf /nix 2>/dev/null || {
        log_warning "无法移除 /nix（可能需要 sudo 权限）"
        sudo rm -rf /nix
    }
    log_success "Nix 存储已移除"
}

# === 通用用户文件清理 ===
# 清理用户特定的 Nix 文件，适用于两种模式
cleanup_user_files() {
    log_info "正在清理用户特定的 Nix 文件..."

    # 用户配置文件
    local user_profiles=(
        "$HOME/.bash_profile"
        "$HOME/.bashrc"
        "$HOME/.profile"
        "$HOME/.zshrc"
    )

    for profile in "${user_profiles[@]}"; do
        if [[ -f "$profile" ]]; then
            sed -i.bak-before-nix-removal '/nix/d' "$profile" 2>/dev/null || true
            log_info "已清理 $profile"
        fi
    done

    # 用户 Nix 文件
    rm -rf "$HOME/.nix-channels" 2>/dev/null || true
    rm -rf "$HOME/.nix-defexpr" 2>/dev/null || true
    rm -rf "$HOME/.nix-profile" 2>/dev/null || true
    rm -rf "$HOME/.config/nix" 2>/dev/null || true
    rm -rf "$HOME/.config/nixpkgs" 2>/dev/null || true
    rm -rf "$HOME/.cache/nix" 2>/dev/null || true
    rm -rf "$HOME/.local/state/nix" 2>/dev/null || true

    log_success "用户 Nix 文件已移除"
}

# === 完全卸载 ===
# 执行完整的 Nix 卸载和清理过程
complete_uninstall() {
    log_info "开始完整的 Nix 卸载和清理..."

    # 检测安装模式
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] || systemctl list-unit-files | grep -q nix-daemon; then
        log_info "检测到多用户 Nix 安装"
        uninstall_nix_multiuser
    elif [[ -d /nix ]] && [[ -O /nix ]] 2>/dev/null; then
        log_info "检测到单用户 Nix 安装"
        uninstall_nix_singleuser
    elif [[ -d /nix ]]; then
        log_warning "检测到 Nix 安装但模式不明确，尝试两种方法"
        uninstall_nix_multiuser 2>/dev/null || uninstall_nix_singleuser
    else
        log_info "未检测到 Nix 安装"
    fi

    # 通用清理
    cleanup_user_files

    # 移除无效符号链接
    log_info "清理无效符号链接..."
    remove_dead_symlinks "$HOME" "$HOME/.config"

    log_success "完全卸载完成！"
    log_info "所有 Nix 组件和无效符号链接已被移除。"
    log_info "您可能需要重启 shell 或注销/登录以完成清理。"
}

# === 干净安装 Nix（多用户模式） ===
# 以多用户模式安装 Nix，包括守护进程
clean_install_nix_multiuser() {
    log_info "执行干净的 Nix 安装（多用户模式）..."

    # 安装带守护进程的 Nix
    log_info "运行带守护进程的 Nix 安装程序..."
    if sh <(curl -L https://nixos.org/nix/install) --daemon; then
        log_success "Nix 安装成功（多用户）"

        # 为当前会话加载配置文件
        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            log_info "Nix 配置文件已为当前会话加载"
        fi

        # 验证安装
        if command_exists nix; then
            nix --version
            log_success "Nix 安装已验证"
        else
            log_error "Nix 安装完成但未找到 nix 命令"
            log_info "您可能需要重启 shell"
            return 1
        fi
    else
        log_error "Nix 安装失败"
        return 1
    fi
}

# === 干净安装 Nix（单用户模式） ===
# 以单用户模式安装 Nix，不使用守护进程
clean_install_nix_singleuser() {
    log_info "执行干净的 Nix 安装（单用户模式）..."

    # 安装不带守护进程的 Nix
    log_info "运行不带守护进程的 Nix 安装程序..."
    if sh <(curl -L https://nixos.org/nix/install) --no-daemon; then
        log_success "Nix 安装成功（单用户）"

        # 如果初始配置文件不存在，则创建
        if [[ ! -e "$HOME/.nix-profile" ]]; then
            log_info "创建初始 Nix 配置文件..."
            /nix/var/nix/profiles/default/bin/nix-env -i
            log_info "初始配置文件已创建"
        fi

        # 为当前会话加载配置文件
        if [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
            source "$HOME/.nix-profile/etc/profile.d/nix.sh"
            log_info "Nix 配置文件已为当前会话加载"
        else
            log_error "未找到 Nix 配置文件：$HOME/.nix-profile/etc/profile.d/nix.sh"
            log_error "初始配置文件创建可能失败"
            return 1
        fi

        # 如果尚未添加到 shell 配置文件，则添加
        local shell_profiles=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
        local nix_source_line='if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then . ~/.nix-profile/etc/profile.d/nix.sh; fi'

        for profile in "${shell_profiles[@]}"; do
            if [[ -f "$profile" ]] && ! grep -q "nix-profile/etc/profile.d/nix.sh" "$profile"; then
                echo "$nix_source_line" >> "$profile"
                log_info "已将 Nix 加载添加到 $profile"
            fi
        done

        # 验证安装
        if command_exists nix; then
            nix --version
            log_success "Nix 安装已验证"
        else
            log_error "Nix 安装完成但未找到 nix 命令"
            log_info "您可能需要重启 shell 或运行：source ~/.nix-profile/etc/profile.d/nix.sh"
            return 1
        fi
    else
        log_error "Nix 安装失败"
        return 1
    fi
}

# === 安装 Nix（适用于非 NixOS 系统） ===
# 检查 Nix 是否已安装，如需则安装
install_nix() {
    log_info "正在设置 Nix..."

    # 检查 Nix 是否已安装
    if command_exists nix; then
        log_info "Nix 已安装 ($(nix --version))"

        # 询问用户是否要重新安装
        read -p "是否要重新安装 Nix 以进行干净设置？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            complete_uninstall
            if [[ "$SINGLE_USER_MODE" == "true" ]]; then
                clean_install_nix_singleuser
            else
                clean_install_nix_multiuser
            fi
        else
            log_info "使用现有 Nix 安装"

            if [[ "$SINGLE_USER_MODE" == "false" ]]; then
                # 对于多用户模式，确保守护进程正在运行
                if ! systemctl is-active --quiet nix-daemon 2>/dev/null; then
                    log_info "启动 nix-daemon..."
                    sudo systemctl start nix-daemon 2>/dev/null || true
                fi

                # 加载配置文件
                if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
                    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
                    log_info "Nix 配置文件已为当前会话加载"
                fi
            else
                # 对于单用户模式，只需加载配置文件
                if [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
                    source "$HOME/.nix-profile/etc/profile.d/nix.sh"
                    log_info "Nix 配置文件已为当前会话加载"
                fi
            fi
        fi
    else
        # 全新安装
        if [[ "$SINGLE_USER_MODE" == "true" ]]; then
            clean_install_nix_singleuser
        else
            clean_install_nix_multiuser
        fi
    fi
}

# === 启用 Nix flakes ===
# 启用 Nix 的 flakes 功能，支持现代 Nix 配置方式
enable_flakes() {
    log_info "正在启用 Nix flakes..."

    # 创建配置目录
    mkdir -p ~/.config/nix

    # 启用实验性功能
    if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
        echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
        log_success "已在用户配置中启用 Flakes"
    else
        log_warning "Flakes 已在用户配置中启用"
    fi

    # 对于多用户模式，也尝试在系统范围内启用
    if [[ "$SINGLE_USER_MODE" == "false" ]] && ([[ -w /etc/nix ]] || sudo -n true 2>/dev/null); then
        sudo mkdir -p /etc/nix
        if ! sudo grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then
            echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf > /dev/null
            log_success "已在系统范围内启用 Flakes"
        else
            log_warning "Flakes 已在系统范围内启用"
        fi
    fi
}

# === 安装 Home Manager（独立模式） ===
# 安装独立模式的 Home Manager，用于管理用户配置
install_home_manager_standalone() {
    log_info "正在安装 Home Manager（独立模式）..."

    # 检查 Home Manager 是否已安装
    if command_exists home-manager; then
        log_warning "Home Manager 已安装"
        home-manager --version

        # 无论如何更新频道
        log_info "更新现有 Home Manager 频道..."
        nix-channel --update home-manager 2>/dev/null || true
        return 0
    fi

    # 如果不存在 Home Manager 频道，则添加
    if ! nix-channel --list | grep -q home-manager; then
        log_info "添加 Home Manager 频道..."
        nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
        log_success "已添加 Home Manager 频道"
    else
        log_warning "Home Manager 频道已存在"
    fi

    # 更新频道
    log_info "更新 Nix 频道..."
    nix-channel --update

    # 安装 Home Manager
    log_info "安装 Home Manager..."
    if nix-shell '<home-manager>' -A install; then
        log_success "Home Manager 安装成功"

        # 验证安装
        if command_exists home-manager; then
            home-manager --version
            log_success "Home Manager 安装已验证"
        else
            log_warning "Home Manager 安装完成但未找到命令"
            log_info "您可能需要重启 shell 或加载配置文件"
        fi
    else
        log_error "Home Manager 安装失败"
        return 1
    fi
}

# === 为 NixOS 设置 ===
# 为 NixOS 系统设置 Nix 环境
setup_nixos() {
    log_info "为 NixOS 设置 Nix 环境..."

    if [[ "$SINGLE_USER_MODE" == "true" ]]; then
        log_warning "单用户模式在 NixOS 系统上不常见"
        log_info "NixOS 通常使用多用户 Nix 安装"
    fi

    # 启用 flakes
    enable_flakes

    # 检查 flake.nix 是否有效
    log_info "验证 flake 配置..."
    if nix flake check --no-build 2>/dev/null; then
        log_success "Flake 配置有效"
    else
        log_warning "Flake 配置存在问题（这可能是正常的）"
    fi

    # 显示可用配置
    log_info "可用的 NixOS 配置："
    nix flake show 2>/dev/null | grep -E "nixosConfigurations" -A 10 || log_warning "无法显示配置"

    log_success "NixOS 环境设置完成！"
}

# === 为 NixOS 容器设置 ===
# 为 NixOS 容器（nixos/nix Docker 镜像）设置 Nix 环境
setup_nixos_container() {
    log_info "为 NixOS 容器设置 Nix 环境..."

    # 在容器中，Nix 已安装并配置
    # 我们只需要启用 flakes 并验证配置

    # 启用 flakes
    enable_flakes

    # 在容器模式下跳过 Home Manager 安装 - 测试不需要
    log_info "在容器模式下跳过 Home Manager 安装"

    # 检查 flake.nix 是否有效
    log_info "验证 flake 配置..."
    if nix flake check --no-build 2>/dev/null; then
        log_success "Flake 配置有效"
    else
        log_warning "Flake 配置存在问题（这可能是正常的）"
    fi

    # 显示可用配置
    log_info "可用配置："
    nix flake show 2>/dev/null || log_warning "无法显示配置"
    install_home_manager_standalone

    log_success "NixOS 容器环境设置完成！"
}

# === 为非 NixOS 系统设置 ===
# 为非 NixOS 系统（如 Arch、Debian、RedHat 等）设置 Nix 环境
setup_standalone() {
    local os_type="$1"

    if [[ "$SINGLE_USER_MODE" == "true" ]]; then
        log_info "为 $os_type 设置 Nix 环境（单用户模式）..."
    else
        log_info "为 $os_type 设置 Nix 环境（多用户模式）..."
    fi

    # 如果不存在则安装 Nix
    install_nix

    # 启用 flakes
    enable_flakes

    # 安装 Home Manager
    install_home_manager_standalone

    # 检查 flake.nix 是否有效
    log_info "验证 flake 配置..."
    if nix flake check --no-build 2>/dev/null; then
        log_success "Flake 配置有效"
    else
        log_warning "Flake 配置存在问题（这可能是正常的）"
    fi

    # 显示可用配置
    log_info "可用的 Home Manager 配置："
    nix flake show 2>/dev/null | grep -E "homeConfigurations" -A 10 || log_warning "无法显示配置"

    if [[ "$SINGLE_USER_MODE" == "true" ]]; then
        log_success "独立 Nix 环境设置完成（单用户模式）！"
    else
        log_success "独立 Nix 环境设置完成（多用户模式）！"
    fi
}

# === 显示使用说明 ===
# 显示后续步骤和使用命令的说明
show_usage_instructions() {
    local os_type="$1"
    local hostname=${HOSTNAME}

    log_info ""
    log_info "=== 后续步骤 ==="

    case "$os_type" in
        "nixos")
            log_info "对于 NixOS 系统配置："
            log_info "  sudo nixos-rebuild switch --flake .#$hostname"
            log_info ""
            log_info "查看可用配置："
            log_info "  nix flake show"
            log_info ""
            log_info "更新 flake 输入："
            log_info "  nix flake update"
            ;;
        *)
            log_info "对于 Home Manager 配置："
            log_info "  # 默认用户："
            log_info "  home-manager switch --flake .#$hostname"
            log_info ""
            log_info "  # 自定义用户名："
            log_info "  NIX_USERNAME=your_username home-manager switch --flake .#$hostname"
            log_info ""
            log_info "  # 自定义 dotfiles 路径："
            log_info "  NIX_DOTFILES_PATH=/path/to/dotfiles home-manager switch --flake .#$hostname"
            log_info ""
            log_info "  # 同时自定义用户名和路径："
            log_info "  NIX_USERNAME=kata NIX_DOTFILES_PATH=/custom/path home-manager switch --flake .#$hostname"
            log_info ""
            log_info "查看可用配置："
            log_info "  nix flake show"
            log_info ""
            log_info "更新 flake 输入："
            log_info "  nix flake update"
            log_info ""
            log_info "有用的命令："
            log_info "  home-manager generations           # 显示之前的生成"
            log_info "  nix-collect-garbage -d             # 清理旧包"
            ;;
    esac

    log_info ""
    if [[ "$SINGLE_USER_MODE" == "true" ]]; then
        log_info "如果遇到 'command not found' 错误，请尝试："
        log_info "  source ~/.nix-profile/etc/profile.d/nix.sh"
    else
        log_info "如果遇到 'command not found' 错误，请尝试："
        log_info "  source ~/.nix-profile/etc/profile.d/hm-session-vars.sh"
    fi
    log_info "或重启终端会话。"
}

# === 主函数 ===
# 解析命令行参数并执行相应的操作
main() {
    # 解析命令行参数
    case "${1:-}" in
        --single)
            SINGLE_USER_MODE=true
            log_info "已选择单用户模式"
            ;;
        --uninstall)
            log_info "已选择卸载模式"

            # 显示将被卸载的内容
            log_info ""
            log_info "=== 卸载确认 ==="
            log_info "这将完全移除："
            log_info "• Nix 包管理器及其所有组件"
            log_info "• 所有 Nix 存储内容（/nix 目录）"
            log_info "• Nix 守护进程和 systemd 服务（如果是多用户模式）"
            log_info "• nixbld 用户和组（如果是多用户模式）"
            log_info "• Nix 相关的 shell 配置修改"
            log_info "• 用户特定的 Nix 文件和缓存"
            log_info "• ~ 和 ~/.config 目录中的无效符号链接"
            log_info ""
            log_warning "此操作无法撤销！"
            log_info ""

            # 确认卸载
            read -p "您确定要继续执行完整的 Nix 卸载吗？(y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_info "正在进行卸载..."
                complete_uninstall
            else
                log_info "用户取消了卸载操作"
                log_info "未对系统进行任何更改"
            fi
            exit 0
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        "")
            # 默认行为 - 设置（多用户）
            ;;
        *)
            log_error "未知选项：$1"
            show_help
            exit 1
            ;;
    esac

    log_info "开始 Nix 环境设置..."

    # 检测操作系统
    local os_type="$(detect_os)"
    log_info "检测到的操作系统：$os_type"

    # 切换到脚本目录
    cd "$(dirname "$0")"

    # 检查 flake.nix 是否存在
    if [[ ! -f "flake.nix" ]]; then
        log_error "在当前目录中未找到 flake.nix"
        exit 1
    fi

    case "$os_type" in
        "nixos")
            if setup_nixos; then
                show_usage_instructions "$os_type"
                log_success "Nix 环境设置成功完成！"
                log_info "您现在可以使用上面显示的命令应用您的配置。"
            else
                log_error "NixOS 设置失败"
                exit 1
            fi
            ;;
        "nixos-container")
            if setup_nixos_container; then
                show_usage_instructions "nixos"
                log_success "Nix 环境设置成功完成！"
                log_info "容器设置完成 - 准备就绪，可进行测试。"
            else
                log_error "NixOS 容器设置失败"
                exit 1
            fi
            ;;
        "arch"|"debian"|"redhat"|"unknown")
            if setup_standalone "$os_type"; then
                show_usage_instructions "$os_type"
                log_success "Nix 环境设置成功完成！"
                log_info "您现在可以使用上面显示的命令应用您的配置。"
            else
                log_error "独立设置失败"
                exit 1
            fi
            ;;
        *)
            log_error "不支持的操作系统：$os_type"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
