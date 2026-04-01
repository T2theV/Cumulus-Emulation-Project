let
    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/78ca23098c5ff0adcafaff27174adf441eae4e78.tar.gz";
    pkgs = import nixpkgs { config = { permittedInsecurePackages = [ "freeimage-3.18.0-unstable-2024-04-18" ];}; overlays = [];};
in
{
    es-de-new = pkgs.emulationstation-de.overrideAttrs(finalAttrs: previousAttrs: {
    });
}