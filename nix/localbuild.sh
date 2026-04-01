#! /bin/bash

RANGE=$(jq -r '. | length' emulators-src.json)
for ((index = 0; index < $RANGE; index++));
do
    ./getrev.sh $(jq -r ".[$index].owner" emulators-src.json) $(jq -r ".[$index].repo" emulators-src.json) $(jq -r ".[$index].nixpkg" emulators-src.json);
    ./prefetch.sh $(jq -r ".[$index].nixpkg" emulators-src.json);
done
