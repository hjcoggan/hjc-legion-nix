{
  description = "hjcoggan's NixOS gaming PC (Ryzen 7 7700 + Radeon RX 9070 XT)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # No `follows` on purpose: uses its own pinned nixpkgs so it matches the
    # maintainer's binary cache and only rebuilds when Windscribe itself updates.
    windscribe-nixos.url = "github:Varmisanth/windscribe-nixos";

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.gaming-pc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/gaming-pc
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.heath = import ./home;
        }
      ];
    };
  };
}
