forester build \
  --root=jdll-0001 \
  --no-assets \
  --no-theme \
  trees/ 

# Hacky mangling for setting forest as subroute
mv output/index.xml output/trees.xml
ruplacer index.xml trees.xml ./output --go --quiet
cp -r output/* build
