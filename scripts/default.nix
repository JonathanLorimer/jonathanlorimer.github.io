{
  pkgs,
  ghcid,
  cabal-install,
}: {
  dev = pkgs.writeShellApplication {
    name = "dev";
    runtimeInputs = [ghcid cabal-install];
    text = builtins.readFile ./dev.sh;
  };
}
