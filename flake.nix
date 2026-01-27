{
  description = "Hytale Launcher";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    packages.x86_64-linux = rec {
      hytale-launcher = pkgs.callPackage ./package.nix {};
      default = hytale-launcher;
    };

    overlay = import ./overlay.nix;
    overlays.default = self.overlay;
  };
}
