OUTPUT_DIR="build/"
cabal run
forester build --dev --root=jdll-0001 trees/ --no-assets
cp -r output "$OUTPUT_DIR/trees"



