{
  description = "Jonathan Lorimer's personal website";

  inputs = {
    # Nix Inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Haskell lib overrides
    slick-src = {
      url = "github:JonathanLorimer/slick/patch-1";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , slick-src
    }:
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ] (system: function rec {
          inherit system;
          pkgs = nixpkgs.legacyPackages.${system};
          supportedGHCVersion = "927";
          compilerVersion = "ghc${supportedGHCVersion}";
          hsPkgs = pkgs.haskell.packages.${compilerVersion}.override {
            overrides = hfinal: hprev: {
              jonathanlorimerdev = hfinal.callCabal2nix "jonathanlorimerdev" ./. {};
              slick = hfinal.callCabal2nix "slick" slick-src {};
            };
          };
        });
    in
    {
      # nix fmt
      formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);

      # nix develop
      devShell = forAllSystems ({hsPkgs, pkgs, ...}:
        hsPkgs.shellFor {
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
            mprocs
            watchexec
          ] ++ (builtins.attrValues (import ./scripts.nix { s = pkgs.writeShellScriptBin; }));
        }
      );

      # nix build
      packages = forAllSystems ({hsPkgs, ...}: rec {
        jonathanlorimerdev = hsPkgs.jonathanlorimerdev;
        default = jonathanlorimerdev;
      });

      # nix run
      apps = forAllSystems ({system, ...}: rec {
        build-site = { type = "app"; program = "${self.packages.${system}.jonathanlorimerdev}/bin/build-site"; };
        default = build-site;
      });
    };
}
