{ s }:
rec
{
  ghcidScript = s "dev" "ghcid --command 'cabal new-repl lib:jonathanlorimerdev' --allow-eval --warnings";
  allScripts = [ ghcidScript ];
}
