#! /bin/sh

REVISION=$(curl https://api.github.com/repos/${1}/${2}/commits | jq ".[0]".sha | tr -d \")
# echo $REVISION
jq --null-input --arg rev $REVISION '{ rev: $rev }' > ${3}-out.json
