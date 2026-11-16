RANGE=$(jq -r '. | length' emulators-src.json)
for ((index = 0; index < $RANGE; index++));
do
    ./getrev.sh $(jq -r ".[$index].owner" emulators-src.json) $(jq -r ".[$index].repo" emulators-src.json) $(jq -r ".[$index].nixpkg" emulators-src.json);
    ./prefetch.sh $(jq -r ".[$index].nixpkg" emulators-src.json);
done

# Pin the mutable Xenia compatibility_data.json hash (a release asset behind a
# mutable tag) to a JSON the xenia-edge overlay reads; see fetch-compat-hash.sh.
./fetch-compat-hash.sh
