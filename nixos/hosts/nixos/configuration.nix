# 编辑此配置文件以定义系统上应安装的内容
# 帮助信息可在 configuration.nix(5) 手册页和 NixOS 手册中找到
# （可通过运行 ‘nixos-help’ 访问）

# 配置文件入口，接收两个参数：
# - config: 系统配置对象，包含所有配置选项
# - pkgs: 包集合，包含所有可用的 Nix 包
# - ...: 剩余参数，用于忽略其他不需要的参数
{ config, pkgs, ... }:

{
  # 导入配置文件
  imports =
    [ # 包含硬件扫描的结果
      ./hardware-configuration.nix  # 硬件配置文件，通常由 NixOS 安装过程自动生成
    ];

  # 引导加载器配置
  boot.loader.grub.enable = true;  # 启用 GRUB 引导加载器
  boot.loader.grub.device = "/dev/sda";  # GRUB 安装设备
  boot.loader.grub.useOSProber = true;  # 启用 OSProber 以检测其他操作系统

  # 网络配置
  networking.hostName = hostname; # 使用外部传入的 hostname 参数
  # 无线网络配置
  # networking.wireless.enable = true;  # 通过 wpa_supplicant 启用无线支持

  # 网络代理配置（如有必要）
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # 启用网络管理
  networking.networkmanager.enable = true;  # 启用 NetworkManager 服务

  # 设置时区
  time.timeZone = "Asia/Tokyo";  # 设置为东京时区

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


  # 启用 X11 窗口系统
  services.xserver.enable = true;

  # 桌面环境配置
  services.xserver.displayManager.gdm.enable = true;  # 启用 GDM 显示管理器
#  services.xserver.desktopManager.gnome.enable = true;  # 可选：启用 GNOME 桌面环境

  # X11 键盘映射配置
  services.xserver.xkb = {
    layout = "us";  # 键盘布局为美式英语
    variant = "";  # 键盘变体（空表示默认）
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

  # 启用打印服务
  services.printing.enable = true;  # 启用 CUPS 打印服务

  # 音频和安全配置
  services.pulseaudio.enable = false;  # 禁用 PulseAudio（使用 PipeWire 替代）
  security.rtkit.enable = true;  # 启用实时权限管理
  security.polkit.enable = true;  # 启用 Polkit 权限管理
  services.pipewire = {
    enable = true;  # 启用 PipeWire
    alsa.enable = true;  # 启用 ALSA 支持
    alsa.support32Bit = true;  # 支持 32 位应用
    pulse.enable = true;  # 启用 PulseAudio 兼容层
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # 触摸板支持
  # services.xserver.libinput.enable = true;  # 启用触摸板支持（在大多数桌面管理器中默认启用）

  # 用户账户配置
  # 定义用户账户。不要忘记使用 ‘passwd’ 设置密码。
  users.users.hzj = {
    isNormalUser = true;  # 是普通用户
    description = "hzj";  # 用户描述
    extraGroups = [ "networkmanager" "wheel" ];  # 用户所属的额外组
    # 用户级别的包安装
    packages = with pkgs; [
    #  thunderbird  # 可选：安装 Thunderbird
    ];
  };

  # 安装 Firefox
  programs.firefox.enable = true;  # 启用 Firefox（会自动安装）

  # 允许安装非自由软件包
  nixpkgs.config.allowUnfree = true;

  # 系统级包安装
  # 列在系统配置文件中安装的包。要搜索包，请运行：
  # $ nix search wget
  # with pkgs; 语法使我们可以直接引用包名而不需要前缀
  environment.systemPackages = with pkgs; [
    vim # 不要忘记添加编辑器来编辑 configuration.nix！Nano 编辑器也默认安装。
    wget  # 网络下载工具
    git   # 版本控制系统
    fzf   # 命令行模糊查找工具
    curl  # 网络请求工具

  ];



  # 一些程序需要 SUID 包装器，可以进一步配置或在用户会话中启动
  # programs.mtr.enable = true;  # 启用 mtr 网络诊断工具
  # programs.gnupg.agent = {
  #   enable = true;  # 启用 GnuPG 代理
  #   enableSSHSupport = true;  # 启用 SSH 支持
  # };

  # 列出要启用的服务：

  # 启用 OpenSSH 守护进程
  services.openssh.enable = true;  # 启用 SSH 服务

  # 防火墙配置
  # 打开防火墙中的端口
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # 或者完全禁用防火墙
  # networking.firewall.enable = false;

  # 系统状态版本
  # 此值决定了系统上状态数据的默认设置，如文件位置和数据库版本
  # 这些设置取自指定的 NixOS 版本
  # 保持此值为系统首次安装时的版本是完全没问题的，也是推荐的做法
  # 在更改此值之前，请阅读此选项的文档
  # （例如 man configuration.nix 或 https://nixos.org/nixos/options.html）
  system.stateVersion = "25.11"; # 你阅读了注释吗？

}
