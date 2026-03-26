# 配置文件入口，接收多个参数：
# - config: 系统配置对象，包含所有配置选项
# - pkgs: 包集合，包含所有可用的 Nix 包
# - inputs: flake 输入，来自 flake.nix 中定义的依赖
# - username: 用户名，通过外部传入
# - hostname: 主机名，通过外部传入
# - ...: 剩余参数，用于忽略其他不需要的参数
{ config, pkgs, inputs, username, hostname, ... }:

{
  # 导入硬件配置文件，该文件包含系统硬件相关的配置
  # 通常由 NixOS 安装过程自动生成
  imports = [ ./hardware-configuration.nix ];

  # 引导加载器配置
  boot.loader.systemd-boot.enable = true;  # 启用 systemd-boot 引导加载器
  boot.loader.efi.canTouchEfiVariables = true;  # 允许修改 EFI 变量
  boot.loader.timeout = 0;  # 引导菜单超时时间为 0 秒（直接启动）
  # boot.kernelPackages = pkgs.linuxPackages_lts;  # 可选：使用 LTS 内核

  # 设置主机名，使用外部传入的 hostname 参数
  networking.hostName = hostname;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # 启用网络管理
  networking.networkmanager.enable = true;  # 启用 NetworkManager 服务

  # 设置时区
  time.timeZone = "Asia/Shanghai";  # 设置为东京时区

  # 国际化设置
  i18n.defaultLocale = "zh_CN.UTF-8";  # 默认区域设置为中文（中国）UTF-8

  # 额外的区域设置
  # 这些设置影响系统各个方面的区域偏好
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";      # 地址格式
    LC_IDENTIFICATION = "zh_CN.UTF-8"; # 识别信息
    LC_MEASUREMENT = "zh_CN.UTF-8";   # 度量单位
    LC_MONETARY = "zh_CN.UTF-8";      # 货币格式
    LC_NAME = "zh_CN.UTF-8";          # 人名格式
    LC_NUMERIC = "zh_CN.UTF-8";       # 数字格式
    LC_PAPER = "zh_CN.UTF-8";         # 纸张大小
    LC_TELEPHONE = "zh_CN.UTF-8";     # 电话号码格式
    LC_TIME = "zh_CN.UTF-8";          # 时间格式
  };
  # 输入法配置
  i18n.inputMethod = {
    enable = true;  # 启用输入法
    type = "fcitx5";  # 使用 fcitx5 输入法框架
    fcitx5 = {
      waylandFrontend = true;  # 启用 Wayland 前端
      # 安装 fcitx5 附加组件
      # with pkgs; 是 Nix 语法，用于在块内直接引用 pkgs 中的包
      addons = with pkgs; [ fcitx5-mozc fcitx5-gtk fcitx5-nord ];
    };
  };

  # 字体配置
  fonts = {
    # 安装的字体包
    # with pkgs; 语法使我们可以直接引用包名而不需要前缀
    packages = (with pkgs; [
      noto-fonts              # Noto 基础字体
      noto-fonts-cjk-sans     # Noto CJK 无衬线字体
      noto-fonts-color-emoji  # 彩色 emoji 字体
      fira-code               # 等宽编程字体
      fira-code-symbols       # Fira Code 符号
      dina-font               # Dina 字体
      proggyfonts             # Proggy 字体
      udev-gothic-nf          # UDEV Gothic 字体（带 nerd fonts）
      font-awesome            # Font Awesome 图标字体
      cantarell-fonts         # Cantarell 字体
    ]);

    # Fontconfig 配置
    fontconfig = {
      enable = true;  # 启用 fontconfig
      # 默认字体设置
      defaultFonts = {
        monospace = [ "UDEV Gothic 35NFLG" ];  # 等宽字体
        sansSerif = [ "Noto Sans CJK JP" "DejaVu Sans" ];  # 无衬线字体
        serif = [ "Noto Serif JP" "DejaVu Serif" ];  # 衬线字体
      };
      # 子像素渲染设置
      subpixel = { lcdfilter = "light"; };
    };
  };

  # 启用 X11 窗口系统
  services.xserver.enable = true;

  # 禁用 seatd 服务
  # seatd 是一个轻量级的 seat 管理服务，这里选择禁用
  services.seatd.enable = false;

  # greetd 登录管理器配置
  services.greetd = {
    enable = true;  # 启用 greetd
    settings = {
      # 默认会话配置（用于登录界面）
      default_session = {
        # 使用 cage（Wayland  compositor）运行 regreet 登录界面
        command =
          "${pkgs.cage}/bin/cage -s -- ${config.programs.regreet.package}/bin/regreet";
        user = "greeter";  # 运行登录界面的用户
      };
      # 初始会话配置（登录后自动启动）
      initial_session = {
        # 使用 uwsm 启动 Hyprland 会话
        #command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
        command = "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
        user = username;  # 使用外部传入的用户名
      };
    };
  };
  # regreet 登录界面配置
  programs.regreet = {
    enable = true;  # 启用 regreet
    settings = {
      # 背景设置
      background = {
        path =
          ../.config/hypr/wallpaper/Simple-Minimalist-Wallpaper-2560x1600-64817.jpg;
        fit = "Cover";  # 背景图片适应方式
      };

      # GTK 配置
      gtk = {
        application_prefer_dark_theme = true;  # 偏好暗色主题
        cursor_theme_name = "Adwaita";  # 光标主题
        font_name = "Cantarell 16";  # 字体设置
        icon_theme_name = "Adwaita";  # 图标主题
        theme_name = "Adwaita";  # GTK 主题
      };

      # 命令配置
      commands = {
        reboot = [ "systemctl" "reboot" ];  # 重启命令
        poweroff = [ "systemctl" "poweroff" ];  # 关机命令
      };

      # cage 启动参数
      cageArgs = {
        enable = true;
        cageArgs = [ "-m" "last" ];  # 启动参数
      };
    };
  };
  # Hyprland Wayland  compositor 配置
  programs.hyprland = {
    enable = true;  # 启用 Hyprland
    withUWSM = true;  # 启用 User Session Manager
    xwayland.enable = true;  # 启用 XWayland 以支持 X11 应用
  };

  # X11 键盘映射配置
  services.xserver.xkb = {
    layout = "us";  # 键盘布局为美式英语
    variant = "";  # 键盘变体（空表示默认）
  };

  # 启用 locate 服务
  # locate 用于快速查找文件
  services.locate.enable = true;

  # 启用打印服务
  services.printing.enable = true;  # 启用 CUPS 打印服务

  # 音频和安全配置
  services.pulseaudio.enable = false;  # 禁用 PulseAudio（使用 PipeWire 替代）
  security.rtkit.enable = true;  # 启用实时权限管理
  security.polkit.enable = true;  # 启用 Polkit 权限管理
  security.sudo = {
    enable = true;  # 启用 sudo
    wheelNeedsPassword = false;  # wheel 组用户使用 sudo 不需要密码
  };

  # PipeWire 音频服务配置
  services.pipewire = {
    enable = true;  # 启用 PipeWire
    alsa.enable = true;  # 启用 ALSA 支持
    alsa.support32Bit = true;  # 支持 32 位应用
    pulse.enable = true;  # 启用 PulseAudio 兼容层
  };
  # 启用固件更新服务
  services.fwupd.enable = true;  # 启用 fwupd 用于固件更新

  # 虚拟化配置
  virtualisation = {
    containers.enable = true;  # 启用容器支持
    podman = {
      enable = true;  # 启用 Podman 容器引擎
      dockerCompat = true;  # 启用 Docker 兼容性
      defaultNetwork.settings.dns_enabled = true;  # 启用默认网络的 DNS
    };
  };

  # 用户账户配置
  # 使用 ${username} 动态引用外部传入的用户名
  users.users.${username} = {
    isNormalUser = true;  # 是普通用户
    description = username;  # 用户描述
    # 用户所属的额外组
    extraGroups = [ "networkmanager" "wheel" "video" "input" "podman" ];
    # 用户级别的包安装（这里为空）
    packages = with pkgs; [ ];
    # 默认 shell 为 zsh
    shell = pkgs.zsh;
  };

  # 程序配置
  # programs.firefox.enable = true;  # 可选：启用 Firefox
  programs.zsh.enable = true;  # 启用 Zsh shell
  programs.git.enable = true;  # 启用 Git 版本控制
  # 非 Nix 可执行文件支持
  # https://nix.dev/guides/faq#how-to-run-non-nix-executables
  programs.nix-ld.enable = true;  # 启用 nix-ld
  # 为非 Nix 可执行文件提供所需的库
  programs.nix-ld.libraries = with pkgs; [
    icu  # ICU 库
  ];

  # 允许安装非自由软件包
  nixpkgs.config.allowUnfree = true;

  # 系统级包安装
  # 全局安装的包，所有用户都可以使用
  environment.systemPackages = with pkgs; [ nix-index ];  # 安装 nix-index 工具

  # 系统状态版本
  # 这个值决定了系统状态数据的默认设置
  # 建议保持为首次安装时的版本
  system.stateVersion = "25.11";

  # Nix 配置
  nix = {
    settings = {
      # 启用实验性功能：nix-command 和 flakes
      # 注意：在较新的 Nix 版本中，这些功能可能已经成为默认功能
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
}
