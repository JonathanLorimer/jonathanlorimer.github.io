OUTPUT_DIR="build/"
cabal run
forester build --dev --root=jdll-0001 trees/ --no-assets --no-theme

# Hacky mangling for setting forest as subroute
mv output/index.xml output/trees.xml
ruplacer index.xml trees.xml ./output --go --quiet
cp -r output/* "$OUTPUT_DIR"



