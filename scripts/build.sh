OUTPUT_DIR="build/"
cabal run
forester build --root=jdll-0001 trees/ --no-assets
cp -r output "$OUTPUT_DIR/trees"



