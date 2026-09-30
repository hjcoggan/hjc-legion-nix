{
  description = "Touch-friendly, SteamOS-like NixOS for the Lenovo Legion Go S (Ryzen Z2 Go)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Steam Deck UI (gamescope session, steamos-manager, InputPlumber, power button handling...)
    # on generic hardware. Its modules and overlay build against *our* nixpkgs.
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, jovian, ... }@inputs: {
    nixosConfigurations.legion-go-s = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        jovian.nixosModules.default
        ./hosts/legion-go-s
      ];
    };
  };
}
