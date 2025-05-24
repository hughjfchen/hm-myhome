{
  description = "Home Manager configuration of chenjf";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      systems = ["x86_64-linux" "aarch64-linux"];
    in
      {
        packages =
          nixpkgs.lib.attrsets.genAttrs systems (system:
            {
              homeConfigurations."chenjf" = home-manager.lib.homeManagerConfiguration {
                pkgs = nixpkgs.legacyPackages.${system};

                # Specify your home configuration modules here, for example,
                # the path to your home.nix.
                modules = [
                  ./home.nix
                ];

                # Optionally use extraSpecialArgs
                # to pass through arguments to home.nix
              };
            }
          );
      };
}
