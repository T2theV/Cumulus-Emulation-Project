# New format for getting package details:

## Getting Latest Revision
curl can utilize github API's to start to build a json

## Hash calculation
This gives the hash calulation
nurl -e '(import <nixpkgs> { }).${{ pkg }}.src.overrideAttrs(_:{tag=0; rev=${{ rev }};})'

This output is substituted into the hash output

## Simplify the builder source
The source of the package can be substituted and we can override just the revision and hash