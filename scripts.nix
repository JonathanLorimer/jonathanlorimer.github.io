{ s }:
rec
{
  ghcidScript = s "dev" "ghcid --command 'cabal new-repl exe:build-site' --allow-eval --warnings";
  allScripts = [ ghcidScript ];
}
