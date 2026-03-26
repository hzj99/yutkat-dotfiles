# 不要修改此文件！它是由 ‘nixos-generate-config’ 生成的
# 未来的调用可能会覆盖此文件。请修改 /etc/nixos/configuration.nix 代替。
#
# 配置文件入口，接收多个参数：
# - config: 系统配置对象
# - lib: Nix 库函数
# - pkgs: 包集合
# - modulesPath: 模块路径
# - ...: 剩余参数
{ config, lib, pkgs, modulesPath, ... }:

{
  # 导入模块
  # 导入 not-detected.nix 模块，用于处理未自动检测到的硬件
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # 引导相关配置
  boot.initrd.availableKernelModules = [
    "xhci_pci"        # USB 3.0 控制器驱动
    "thunderbolt"     # Thunderbolt 接口驱动
    "nvme"            # NVMe 固态硬盘驱动
    "usb_storage"     # USB 存储设备驱动
    "usbhid"          # USB 人机接口设备驱动
    "sd_mod"          # SD 卡驱动
    "rtsx_pci_sdmmc"  # Realtek SD/MMC 卡控制器驱动
  ];
  boot.initrd.kernelModules = [ ];  # 初始 RAM 磁盘中加载的内核模块（空）
  boot.kernelModules = [ "kvm-intel" ];  # 系统启动时加载的内核模块，kvm-intel 用于 Intel CPU 虚拟化
  boot.extraModulePackages = [ ];  # 额外的内核模块包（空）

  # 交换设备配置
  swapDevices = [ ];  # 没有配置交换设备

  # 网络配置
  networking.useDHCP = lib.mkDefault true;  # 默认使用 DHCP 获取网络配置

  # CPU 配置
  # 启用 Intel CPU 微码更新，依赖于硬件是否启用了可再分发固件
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
