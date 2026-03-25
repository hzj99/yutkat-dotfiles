{
  # === 配置描述 ===
  # 该 flake 用于管理多台主机的 NixOS 配置，使用 Flakes 系统进行版本控制
  description = "My NixOS configurations for multiple hosts using Flakes";

  # === 外部输入 ===
  # 定义了 flake 依赖的外部资源
  inputs = {
    # NixOS 包集合，使用不稳定分支
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager，用于管理用户配置
    home-manager.url = "github:nix-community/home-manager";
    # 让 Home Manager 使用与本 flake 相同的 nixpkgs 版本
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # 自定义工具：walker
    walker.url = "github:abenz1267/walker";

    # 自定义工具：elephant
    elephant.url = "github:abenz1267/elephant";
  };

  # === 输出配置 ===
  # 定义了 flake 的各种输出，包括 NixOS 系统配置和 Home Manager 配置
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # === 主机配置定义 ===
      # 定义了所有主机的配置属性
      myHosts = {

       # lemp10 主机配置
              "nixos" = {
                # 系统架构
                system = "x86_64-linux";
                # 主机特定的 NixOS 配置文件
                hostSpecificNix = ./nixos/hosts/nixos/configuration.nix;
                # 主机特定的 Home Manager 配置文件
                hostSpecificHomeConfig = ./home-manager/hosts/nixos.nix;
                # 是否启用 GUI
                enableGui = true;
                # 是否作为完整的 NixOS 系统配置
                enableSystem = true;
                # 默认用户名
                defaultUsername = "hzj";
              };

        # lemp10 主机配置
        "lemp10" = {
          # 系统架构
          system = "x86_64-linux";
          # 主机特定的 NixOS 配置文件
          hostSpecificNix = ./nixos/hosts/lemp10/configuration.nix;
          # 主机特定的 Home Manager 配置文件
          hostSpecificHomeConfig = ./home-manager/hosts/lemp10.nix;
          # 是否启用 GUI
          enableGui = true;
          # 是否作为完整的 NixOS 系统配置
          enableSystem = true;
          # 默认用户名
          defaultUsername = "hzj";
        };

        # X1C10 主机配置
        "X1C10" = {
          # 系统架构
          system = "x86_64-linux";
          # 主机特定的 Home Manager 配置文件
          hostSpecificHomeConfig = ./home-manager/hosts/X1C10.nix;
          # 是否启用 GUI
          enableGui = false;
          # 是否作为完整的 NixOS 系统配置（这里为 false，表示仅使用 Home Manager）
          enableSystem = false;
          # 默认用户名
          defaultUsername = "kata";
        };

        # test 主机配置（用于测试）
        "test" = {
          # 系统架构
          system = "x86_64-linux";
          # 是否启用 GUI
          enableGui = false;
          # 是否作为完整的 NixOS 系统配置
          enableSystem = false;
          # 默认用户名
          defaultUsername = "test";
        };

        # system-test 主机配置（用于完整系统测试）
        "system-test" = {
          # 系统架构
          system = "x86_64-linux";
          # 是否启用 GUI
          enableGui = true;
          # 是否作为完整的 NixOS 系统配置
          enableSystem = true;
          # 默认用户名
          defaultUsername = "test";
          # 主机特定的 NixOS 配置（使用空配置）
          hostSpecificNix = { };
        };

        # container 主机配置（用于容器）
        "container" = {
          # 系统架构
          system = "x86_64-linux";
          # 是否启用 GUI
          enableGui = false;
          # 是否作为完整的 NixOS 系统配置
          enableSystem = false;
          # 默认用户名
          defaultUsername = "root";
        };
      };

      # === 用户名获取函数 ===
      # 从环境变量读取用户名，如果环境变量未设置则使用默认用户名
      getUsernameForHost = hostname: hostAttrs:
        let
          # 从环境变量获取用户名
          envUser = builtins.getEnv "NIX_USERNAME";
          # 获取主机的默认用户名
          hostDefaultUser = hostAttrs.defaultUsername;
        in if envUser != "" then envUser else hostDefaultUser;

      # === NixOS 系统配置构建函数 ===
      # 为指定主机构建 NixOS 系统配置
      mkNixosSystem = hostname: hostAttrs:
        let
          # 获取系统架构
          system = hostAttrs.system;
          # 获取用户名
          username = getUsernameForHost hostname hostAttrs;
          # 特殊参数，传递给模块
          specialArgs = {
            # 传递所有输入
            inherit inputs hostname username;
            # 是否启用 GUI
            enableGui = hostAttrs.enableGui;
            # 主机特定的 Home Manager 配置，如果不存在则为 null
            hostSpecificHomeConfig = hostAttrs.hostSpecificHomeConfig or null;
          };
        in nixpkgs.lib.nixosSystem {
          # 传递系统架构和特殊参数
          inherit system specialArgs;
          # 配置模块
          modules = [
            # 空模块，用于占位
            ({ pkgs, lib, ... }: { })
            # 基础 NixOS 配置
            ./nixos/configuration.nix
            # 主机特定的 NixOS 配置
            hostAttrs.hostSpecificNix
            # Home Manager NixOS 模块
            home-manager.nixosModules.home-manager
            # Home Manager 配置
            {
              # 不使用全局包
              home-manager.useGlobalPkgs = false;
              # 使用用户包
              home-manager.useUserPackages = true;
              # 为指定用户配置 Home Manager
              home-manager.users.${username} = import ./home.nix;
              # 传递特殊参数给 Home Manager
              home-manager.extraSpecialArgs = specialArgs;
              # Home Manager 备份文件扩展名
              home-manager.backupFileExtension = "hm-backup";
            }
          ];
        };

      # === Home Manager 独立配置构建函数 ===
      # 为指定主机构建独立的 Home Manager 配置（适用于 Arch Linux 等非 NixOS 系统）
      mkHomeManagerConfiguration = hostname: hostAttrs:
        let
          # 获取系统架构
          system = hostAttrs.system;
          # 获取用户名
          username = getUsernameForHost hostname hostAttrs;
          # 导入 nixpkgs
          pkgs = import nixpkgs { inherit system; };
          # 特殊参数，传递给模块
          specialArgs = {
            # 传递所有输入
            inherit inputs username hostname;
            # 是否启用 GUI
            enableGui = hostAttrs.enableGui;
            # 主机特定的 Home Manager 配置，如果不存在则为 null
            hostSpecificHomeConfig = hostAttrs.hostSpecificHomeConfig or null;
          };
        in home-manager.lib.homeManagerConfiguration {
          # 传递包集合
          inherit pkgs;
          # 配置模块
          modules = [ ./home.nix ];
          # 传递特殊参数
          extraSpecialArgs = specialArgs;
        };

      # === 主机分类 ===
      # 根据 enableSystem 标志对主机进行分类
      # 启用系统配置的主机
      nixosHosts =
        nixpkgs.lib.filterAttrs (name: attrs: attrs.enableSystem) myHosts;
      # 仅使用 Home Manager 的主机
      homeManagerHosts =
        nixpkgs.lib.filterAttrs (name: attrs: !attrs.enableSystem) myHosts;

    in {
      # === NixOS 配置输出 ===
      # 为启用系统配置的主机生成 NixOS 配置
      nixosConfigurations = nixpkgs.lib.mapAttrs mkNixosSystem nixosHosts;

      # === Home Manager 配置输出 ===
      # 为仅使用 Home Manager 的主机生成配置
      # 用户名可以通过 NIX_USERNAME 环境变量指定
      # 使用方法：
      #   home-manager switch --flake .#X1C10  (使用默认用户名: yutkat)
      #   NIX_USERNAME=kat home-manager switch --flake .#X1C10 --impure  (使用 kat)
      homeConfigurations = nixpkgs.lib.mapAttrs' (hostname: hostAttrs:
        nixpkgs.lib.nameValuePair hostname
        (mkHomeManagerConfiguration hostname hostAttrs)) homeManagerHosts;
    };
}
