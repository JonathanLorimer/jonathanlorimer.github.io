{
  description = "Jonathan Lorimer's personal website";
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, haskellNix, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
    let
      overlays = [
        haskellNix.overlay
        (final: prev: {
          # This overlay adds our project to pkgs
          jonathanlorimerdev =
            final.haskell-nix.project' {
              src = ./.;
              compiler-nix-name = "ghc8104";
              # This is used by `nix develop .` to open a shell for use with
              # `cabal`, `hlint` and `haskell-language-server`
              shell.tools = {
                ghcid = {};
                cabal = "3.4.0.0";
                hlint = "3.3.1";
                haskell-language-server = "1.2.0.0";
              };
            };
          }
        )
      ];
      pkgs = import nixpkgs { inherit system overlays; };
      flake = pkgs.jonathanlorimerdev.flake {};
    in flake // {
      # Built by `nix build .`
      defaultPackage = flake.packages."jonathanlorimerdev:exe:build-site";
    });
}
