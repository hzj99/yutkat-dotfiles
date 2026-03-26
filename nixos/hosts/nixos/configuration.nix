# ===============================================
# NixOS 系统配置文件
# ===============================================
# 编辑此配置文件以定义系统上应安装的内容
# 帮助信息可在 configuration.nix(5) 手册页和 NixOS 手册中找到
# （可通过运行 `nixos-help` 访问）

# 配置文件入口，接收多个参数：
# - config: 系统配置对象，包含所有配置选项
# - pkgs: 包集合，包含所有可用的 Nix 包
# - inputs: flake 输入，来自 flake.nix 中定义的依赖
# - username: 用户名，通过外部传入
# - hostname: 主机名，通过外部传入
# - ...: 剩余参数，用于忽略其他不需要的参数
{
  config,
  pkgs,
  inputs,
  username,
  hostname,
  ...
}: {
  # ===============================================
  # 导入配置文件
  # ===============================================
  imports = [
    # 包含硬件扫描的结果
    ./hardware-configuration.nix  # 硬件配置文件，通常由 NixOS 安装过程自动生成
  ];

  # ===============================================
  # Nix 配置
  # ===============================================
  nix = {
    # 环境变量配置
    envVars = {
      GOPROXY = "https://goproxy.cn,direct";  # Go 代理配置
    };

    # Nix 设置
    settings = {
      # 启用实验性功能：nix-command 和 flakes
      # 注意：在较新的 Nix 版本中，这些功能可能已经成为默认功能
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  # ===============================================
  # 引导加载器配置
  # ===============================================
  boot.loader = {
    systemd-boot.enable = true;  # 启用 systemd-boot 引导加载器
    efi.canTouchEfiVariables = true;  # 允许修改 EFI 变量
    timeout = 0;  # 引导菜单超时时间为 0 秒（直接启动）
  };
  # boot.kernelPackages = pkgs.linuxPackages_lts;  # 可选：使用 LTS 内核

  # ===============================================
  # 网络配置
  # ===============================================
  networking = {
    hostName = hostname;  # 使用外部传入的 hostname 参数
    networkmanager.enable = true;  # 启用 NetworkManager 服务
    firewall = {
      enable = true;  # 启用防火墙
      allowedTCPPorts = [ 22 ];  # 仅允许 SSH 端口
    };
  };
  # 无线网络配置
  # networking.wireless.enable = true;  # 通过 wpa_supplicant 启用无线支持

  # 网络代理配置（如有必要）
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # ===============================================
  # 系统时间与国际化
  # ===============================================
  # 设置时区
  time.timeZone = "Asia/Shanghai";  # 设置为上海时区

  # 国际化设置
  i18n = {
    defaultLocale = "zh_CN.UTF-8";  # 默认区域设置为中文（中国）UTF-8
    extraLocaleSettings = {
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
  };

  # ===============================================
  # 图形界面配置
  # ===============================================
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
        # 使用 cage（Wayland compositor）运行 regreet 登录界面
        command = "${pkgs.cage}/bin/cage -s -- ${config.programs.regreet.package}/bin/regreet";
        user = "greeter";  # 运行登录界面的用户
      };
      # 初始会话配置（登录后自动启动）
      initial_session = {
        # 使用 uwsm 启动 Hyprland 会话
        command = "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
        user = username;  # 使用外部传入的用户名
      };
    };
  };

  # ===============================================
  # 音频配置
  # ===============================================
  services = {
    pulseaudio.enable = false;  # 禁用 PulseAudio（使用 PipeWire 替代）
    pipewire = {
      enable = true;  # 启用 PipeWire
      alsa = {
        enable = true;  # 启用 ALSA 支持
        support32Bit = true;  # 支持 32 位应用
      };
      pulse.enable = true;  # 启用 PulseAudio 兼容层
      # If you want to use JACK applications, uncomment this
      # jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      # media-session.enable = true;
    };
  };

  # ===============================================
  # 安全配置
  # ===============================================
  security = {
    rtkit.enable = true;  # 启用实时权限管理
    polkit.enable = true;  # 启用 Polkit 权限管理
    sudo = {
      enable = true;  # 启用 sudo
      wheelNeedsPassword = false;  # wheel 组用户使用 sudo 不需要密码
    };
  };

  # ===============================================
  # 服务配置
  # ===============================================
  services = {
    # 启用 OpenSSH 守护进程
    openssh = {
      enable = true;  # 启用 SSH 服务
      settings.PermitRootLogin = "yes";  # 允许 root 登录（注意：生产环境建议设置为 no）
    };

    # 禁用不需要的服务
    #bluetooth.enable = false;  # 禁用蓝牙
    #printing.enable = false;  # 禁用打印服务

    # 启用其他服务
    locate.enable = true;  # 启用 locate 服务（用于快速查找文件）
    fwupd.enable = true;  # 启用 fwupd 用于固件更新
  };


  # ===============================================
  # 虚拟化配置
  # ===============================================
  virtualisation = {
    containers.enable = true;  # 启用容器支持
    podman = {
      enable = true;  # 启用 Podman 容器引擎
      dockerCompat = true;  # 启用 Docker 兼容性
      defaultNetwork.settings.dns_enabled = true;  # 启用默认网络的 DNS
    };
  };

  # ===============================================
  # 用户账户配置
  # ===============================================
  users.users.${username} = {
    isNormalUser = true;  # 是普通用户
    description = username;  # 用户描述
    extraGroups = [ "networkmanager" "wheel" "video" "input" "podman" ];  # 用户所属的额外组
    packages = with pkgs; [ ];  # 用户级别的包安装（这里为空）
    # shell = pkgs.zsh;  # 默认 shell 为 zsh
  };

  # ===============================================
  # 程序配置
  # ===============================================
  programs = {
    # programs.firefox.enable = true;  # 可选：启用 Firefox
    zsh.enable = true;  # 启用 Zsh shell
    git.enable = true;  # 启用 Git 版本控制

    # 非 Nix 可执行文件支持
    # https://nix.dev/guides/faq#how-to-run-non-nix-executables
    nix-ld = {
      enable = true;  # 启用 nix-ld
      libraries = with pkgs; [
        icu  # ICU 库
      ];  # 为非 Nix 可执行文件提供所需的库
    };
  };

  # ===============================================
  # 包管理配置
  # ===============================================
  # 允许安装非自由软件包
  nixpkgs.config.allowUnfree = true;

  # 系统级包安装
  # 全局安装的包，所有用户都可以使用
  environment.systemPackages = with pkgs; [
    nix-index  # 安装 nix-index 工具
    vim        # 文本编辑器
    wget       # 网络下载工具
    git        # 版本控制系统
    fzf        # 命令行模糊查找工具
    curl       # 网络请求工具
  ];

  # 一些程序需要 SUID 包装器，可以进一步配置或在用户会话中启动
  # programs.mtr.enable = true;  # 启用 mtr 网络诊断工具
  # programs.gnupg.agent = {
  #   enable = true;  # 启用 GnuPG 代理
  #   enableSSHSupport = true;  # 启用 SSH 支持
  # };

  # ===============================================
  # 系统状态版本
  # ===============================================
  # 这个值决定了系统状态数据的默认设置
  # 建议保持为首次安装时的版本
  system.stateVersion = "25.11";
}
