{ pkgs 
, ghcid
, cabal-install
, forester
, texlive
}:
{
  dev = pkgs.writeShellApplication {
    name = "dev";
    runtimeInputs = [ ghcid cabal-install ];
    text = builtins.readFile ./dev.sh;
  };
  buildAll = pkgs.writeShellApplication {
    name = "build-all";
    runtimeInputs = [ forester texlive cabal-install ];
    text = builtins.readFile ./build.sh;
  };
  buildForest = pkgs.writeShellApplication {
    name = "build-forest";
    runtimeInputs = [ forester texlive ];
    text = builtins.readFile ./build-forest.sh;
  };
  
}
