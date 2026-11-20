{ pkgs ? import <nixpkgs> {} }:

# Cartouche (ROM cartridge launcher, Godot 4.7.2) — replaces
# pegasus-frontend in this test image. Same derivation as the
# T2theV/cartouche package.nix (fetchFromGitHub + headless Godot
# export), except outputs are renamed to bin/cartouche +
# bin/cartouche.pck so the launcher line stays a plain binary name.
pkgs.stdenv.mkDerivation rec {
  pname = "cartouche";
  version = "0.4.1";

  # The Godot project, fetched from GitHub at a pinned commit.
  # fetchgit (git clone, content-addressed) not fetchFromGitHub: the
  # latter's codeload tarball bytes regenerate non-deterministically on
  # GitHub cache rebuilds, so a pinned tarball hash flaps between values
  # (verified: Z9tDZo... vs QZ5LG... for the same rev). Git commits are
  # stable forever; this unpacked-tree hash is deterministic.
  src = (pkgs.fetchgit {
    url = "https://github.com/T2theV/cartouche";
    rev = "8f45671b03640f6afbb93ab34abd720fdd49b073";
    hash = "sha256-HN/WkeQUI73zmkz7b49+NnvIPzTfVUGG9aFVde4K0i0=";
  }) + "/app";

  nativeBuildInputs = [ pkgs.unzip pkgs.glibc ];

  godotEditor = pkgs.fetchurl {
    url = "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip";
    hash = "sha256-yt0yBOcoo10/E623/Q15AmNrefa5XEDCZetztsNTKeQ";
  };

  godotTemplates = pkgs.fetchurl {
    url = "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz";
    hash = "sha256-8phJC41E2TS+QlpaZaUb8V9CJCiyKaBqbhHZ/+okgBE";
  };

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR/godot-home
    mkdir -p "$HOME/.local/share/godot/export_templates"

    # Editor binary.
    mkdir -p $TMPDIR/godot
    unzip -q $godotEditor -d $TMPDIR/godot
    chmod +x $TMPDIR/godot/Godot_v4.7.2-stable_linux.x86_64

    # Templates, where the editor looks for them.
    mkdir -p $TMPDIR/godot-templates
    unzip -q $godotTemplates -d $TMPDIR/godot-templates \
      templates/linux_release.x86_64
    ln -s $TMPDIR/godot-templates/templates \
      "$HOME/.local/share/godot/export_templates/4.7.2.stable"

    # The editor is dynamically linked to glibc (interpreter
    # /lib64/ld-linux-x86-64.so.2); exec through the loader so this
    # also works in unsandboxed builds where no /lib64 exists.
    godot() {
      "${pkgs.glibc}/lib64/ld-linux-x86-64.so.2" \
        "$TMPDIR/godot/Godot_v4.7.2-stable_linux.x86_64" "$@"
    }

    # The editor writes the import cache (.godot) into the project,
    # and stdenv already made the unpacked source writable — build
    # in place.
    godot --headless --path . --import

    mkdir -p $TMPDIR/export
    godot --headless --path . \
      --export-release Linux $TMPDIR/export/cartouche-linux.x86_64
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    # Both files are required at runtime: Godot loads the PCK named
    # after the executable with its last extension stripped.
    install -m 755 $TMPDIR/export/cartouche-linux.x86_64 $out/bin/cartouche
    install -m 644 $TMPDIR/export/cartouche-linux.pck $out/bin/cartouche.pck
    # The project.godot file is required for the release export to
    # find the main scene. Godot looks for it next to the binary.
    install -m 644 project.godot $out/bin/project.godot
    runHook postInstall
  '';
}
