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
    runtimeInputs = with pkgs; [ forester texlive cabal-install ruplacer ];
    text = builtins.readFile ./build.sh;
  };
  buildForest = pkgs.writeShellApplication {
    name = "build-forest";
    runtimeInputs = with pkgs; [ forester texlive ruplacer ];
    text = builtins.readFile ./build-forest.sh;
  };
  
}
