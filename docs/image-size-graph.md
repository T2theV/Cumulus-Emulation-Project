# `hello-docker:latest` — dependency graph

Generated from the real image: 1,018 Nix store paths, 6,082 measured references
(`nix path-info` + ELF dynamic-linker scan + script/config dumps).
Sizes are MB on-disk (`du` inside the image). **Arrow A → B = "A references B"** (links against, shebang, or config reference).

**Legend:** 🔴 red = cuttable with zero feature loss · 🟢 green = keep (emulators need it) · 🟡 yellow = shared bottleneck.

---

## 1. The whole image, cut view

```mermaid
graph TD
    GB["gowbase.nix contents<br/>image on-disk 5.80 GB"]
    subgraph CUT ["CUTTABLE  -3.28 GiB"]
        C1["mesa.opencl + cross_tools + spirv2dxil<br/>169 MB variants, drag in clang-21<br/>combined 1,018 MB"]
        C2["x11docker -> xpra -> python3.14<br/>python world, 1,157 MB unique"]
        C3["glibcLocates - ALL locales<br/>223 MB (only en_US used)"]
        C4["systemd full build<br/>49 MB"]
        C5["-dev/-include packages + vulkan-headers<br/>(overlay leak) 78 MB"]
    end
    subgraph KEEP ["KEEP - emulators need this"]
        LLVM["llvm-21.1.8-lib<br/>550 MB  SHARED"]:::shared
        MESA["mesa-26.2.6 core<br/>274 MB (llvmpipe -> refs llvm)"]
        RPC["rpcs3<br/>39 MB (+128 incl. llvm)"]
        QT6["qt6: qtbase 86 + qtdeclarative 183"]
        QT5GTK["qt5 41 + gtk3 42 + ffmpeg 34"]
        APPS["emu binaries: rmg 68, dolphin 64, pcsx2 59,<br/>xenia-edge 33, flycast 32, xemu 19, pegasus 4"]
        VULK["vulkan-loader 0.7 (+headers in C5)"]
    end
    GB --> C1 & C2 & C3 & C4 & C5
    GB --> MESA & RPC & QT6 & QT5GTK & APPS & VULK
    C1 -->|"drags in"| LLVM
    MESA -->|"llvmpipe"| LLVM
    RPC -->|"JIT compiler"| LLVM
    classDef cut fill:#ffe0e0,stroke:#c00,stroke-width:1px;
    classDef shared fill:#fff3c4,stroke:#b8860b,stroke-width:2px;
    class C1,C2,C3,C4,C5 cut;
```

Cutting the red block: **5.80 GB → ~2.26 GiB** (all-in-one, every emulator kept).

---

## 2. The 550 MB LLVM fan-in (who actually needs it)

This is the whole story in one picture. Today, **six** things reference
`llvm-21.1.8-lib`. After the cuts in section 1, only **two** remain:

```mermaid
graph LR
    CLANG["clang-21.1.8-lib<br/>832 MB<br/>(dies with cut C1)"]:::cut -->|"refs"| LLVM
    CT["mesa.cross_tools<br/>68 MB (dies with C1)"]:::cut -->|"refs"| LLVM
    OC["mesa.opencl<br/>58 MB (dies with C1)"]:::cut -->|"refs"| LLVM
    SPIRV["SPIRV-LLVM-Translator<br/>7 MB (dies with C1)"]:::cut -->|"refs"| LLVM
    MESA["mesa core (llvmpipe)<br/>274 MB - KEEP"]:::keep -->|"CPU renderer"| LLVM
    RPC["rpcs3<br/>39 MB - KEEP"]:::keep -->|"JIT compiler"| LLVM
    LLVM["llvm-21.1.8-lib<br/>550 MB"]:::shared
    classDef cut fill:#ffe0e0,stroke:#c00;
    classDef keep fill:#d6f5d6,stroke:#080;
    classDef shared fill:#fff3c4,stroke:#b8860b,stroke-width:2px;
```

To delete the 550 MB entirely you must remove **both** green arrows:
mesa built without `llvmpipe` **and** rpcs3 built without dynamic LLVM
(its own PPU compiler only). That's the "GPU-only" scenario - your box
always has the real RX 7800 XT, so nothing inside the image needs
CPU software rendering or a runtime LLVM JIT.

---

## 3. Inside the 1,157 MB: what the x11docker cut actually removes

`x11docker` is a 0.5 MB script. Its value is what it drags in:

```mermaid
graph TD
    X11["x11docker<br/>0.5 MB script"]:::cut
    X11 --> XPR["xpra<br/>42 MB"]:::cut
    XPR --> PY["python3.14<br/>136 MB"]:::cut
    PY --> NUM["numpy 51 MB"]:::cut
    NUM --> OB["openblas 33 MB"]:::cut
    OB --> BL["blas 67 MB + lapack 67 MB"]:::cut
    PY --> OCV["opencv 91 MB"]:::cut
    PY --> PEO["pyopengl 23 MB + 400+ python pkgs"]:::cut
    XPR --> GST["gstreamer + all plugin packs<br/>55 MB"]:::cut
    XPR --> XORG["xorg-server 11 MB"]:::cut
    XPR --> PERL["perl (2nd build) ~52 MB"]:::cut
    classDef cut fill:#ffe0e0,stroke:#c00;
```

Nothing in `opt/gow/*` launches xpra or x11docker - it's X11-forwarding
tooling. The python/blas/opencv stack exists only to serve xpra.

---

## 4. Per-emulator images, after the cuts

One shared shell, one image per emulator. Identical layers are byte-identical
content-addressed Nix paths → the registry stores the shell **once**,
each emulator image costs only its `+N MB` delta.

```mermaid
graph LR
    SHELL["shared shell<br/>1.61 GiB<br/>(mesa core, qt6, gtk, vulkan,<br/>systemd-min, locales-en_US)"]:::keep
    XEM["xemu +26 MB"]:::keep --> SHELL
    XED["xenia-edge +33 MB"]:::keep --> SHELL
    FLY["flycast +34 MB"]:::keep --> SHELL
    PEG["pegasus +52 MB"]:::keep --> SHELL
    RMG["rmg +69 MB"]:::keep --> SHELL
    DOL["dolphin +83 MB"]:::keep --> SHELL
    PCS["pcsx2 +106 MB"]:::keep --> SHELL
    RPC["rpcs3 +128 MB"]:::keep --> SHELL
    classDef keep fill:#d6f5d6,stroke:#080;
    classDef shared fill:#fff3c4,stroke:#b8860b,stroke-width:2px;
```

| image | size | vs pegasus:fedora (1.18 GiB) |
|---|---|---|
| any of the 8 emulator images | 1.64 – 1.74 GiB | +0.5 – 0.55 GiB |
| …plus GPU-only scenario (drop llvmpipe + LLVM JIT) | **1.10 – 1.20 GiB** | ≈ **matches** |

---

## The numbers behind the diagrams

| cut | unique bytes removed | why it's safe |
|---|---|---|
| C1 mesa variants + clang chain | 1,018 MB | plain `mesa` already in image; variants are build/dev tooling |
| C2 x11docker → xpra → python world | 1,157 MB | not launched by anything in `opt/gow` |
| C3 glibcLocates → en_US only | ~205 MB | image runs with `LANG=en_US.UTF-8` |
| C4 systemd full → minimal | 49 MB | systemd-min already present via other packages |
| C5 -dev headers + vulkan-headers | 78 MB | headers only; runtime never reads them |
| **total** | **~3.28 GiB** | **floor: 5.80 GB → 2.26 GiB** |

*Full graph (all 1,018 nodes / 6,082 edges): `image-graph-full.dot` - render with
[Graphviz Online](https://dreampuf.github.io/GraphvizOnline/) or `dot -Tsvg`.*
