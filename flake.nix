{
  description = "Home Manager configuration of chenjf";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
      let
        x64pkgs = nixpkgs.legacyPackages.x86_64-linux;
        arm64pkgs = nixpkgs.legacyPackages.aarch64-linux;
      in {
        homeConfigurations."chenjf@localvm" = home-manager.lib.homeManagerConfiguration {
          pkgs = x64pkgs;

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [
                      ./home.nix
                    ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };
        homeConfigurations."chenjf@OPi5" = home-manager.lib.homeManagerConfiguration {
          pkgs = arm64pkgs;

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [
                      ./home.nix
                    ];

          # Optionally use extraSpecialArgs
          # to pass through arguments to home.nix
        };
      };
}
