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
  # 导入 qemu-guest.nix 模块，适用于 QEMU 虚拟机环境
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  # 引导相关配置
  boot.initrd.availableKernelModules = [
    "uhci_hcd"      # USB 1.1 控制器驱动
    "ehci_pci"      # USB 2.0 控制器驱动
    "ahci"          # SATA 控制器驱动
    "virtio_pci"    # VirtIO PCI 设备驱动（QEMU 虚拟机常用）
    "virtio_scsi"   # VirtIO SCSI 设备驱动（QEMU 虚拟机常用）
    "sd_mod"        # SD 卡驱动
  ];
  boot.initrd.kernelModules = [ ];  # 初始 RAM 磁盘中加载的内核模块（空）
  boot.kernelModules = [ "kvm-intel" ];  # 系统启动时加载的内核模块，kvm-intel 用于 Intel CPU 虚拟化
  boot.extraModulePackages = [ ];  # 额外的内核模块包（空）

  # 文件系统配置
  # 根文件系统配置
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/bf427e46-3822-4ab7-b405-5cd0c69812f4";  # 通过 UUID 识别的磁盘设备
      fsType = "ext4";  # 文件系统类型为 ext4
    };

  # 交换设备配置
  swapDevices = [ ];  # 没有配置交换设备

  # 主机平台配置
  # 默认主机平台为 x86_64-linux
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
