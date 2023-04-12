{
  description = "Jonathan Lorimer's personal website";

  inputs = {
    # Nix Inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:
    let utils = flake-utils.lib;
    in
    utils.eachDefaultSystem (system:
    let
      supportedGHCVersion = "927";
      compilerVersion = "ghc${supportedGHCVersion}";
      pkgs = nixpkgs.legacyPackages.${system};
      hsPkgs = pkgs.haskell.packages.${compilerVersion}.override {
        overrides = hfinal: hprev: {
          jonathanlorimerdev = hfinal.callCabal2nix "jonathanlorimerdev" ./. { };
        };
      };
    in
    {
      # nix develop
      devShell = hsPkgs.shellFor {
        packages = p: [
          p.jonathanlorimerdev
        ];
        buildInputs = with pkgs; [
          hsPkgs.haskell-language-server
          haskellPackages.cabal-install
          haskellPackages.ghcid
          haskellPackages.fourmolu
          haskellPackages.cabal-fmt
          nodePackages.serve
          dig
        ] ++ (builtins.attrValues (import ./scripts.nix { s = pkgs.writeShellScriptBin; }));
      };

      # nix build
      packages = utils.flattenTree {
        jonathanlorimerdev = hsPkgs.jonathanlorimerdev;
        default = hsPkgs.jonathanlorimerdev;
      };

      # nix run
      apps = {
        build-site = utils.mkApp { name = "build-site"; drv = self.packages.${system}.jonathanlorimerdev; };
        default = utils.mkApp { name = "build-site"; drv = self.packages.${system}.jonathanlorimerdev; };
      };
    });
}
