target "default" {
    context = "nix"
    dockerfile = "Dockerfile"
    tags = ["testemunix:latest"]
    contexts = {
        esde-dist = "target:esde-build"
    }
}

// ================================================================
// =      ===============  =====  =======       ===================
// =  ===  ==============  =====  =======  ====  ==================
// =  ====  =============  =====  =======  ====  ==============  ==
// =  ===  ===  =  ==  ==  =====  =======  ====  ==  ===   ===    =
// =      ====  =  ======  ===    =======  ====  ======  =  ===  ==
// =  ===  ===  =  ==  ==  ==  =  =======  ====  ==  ===  =====  ==
// =  ====  ==  =  ==  ==  ==  =  =======  ====  ==  ====  ====  ==
// =  ===  ===  =  ==  ==  ==  =  =======  ====  ==  ==  =  ===  ==
// =      =====    ==  ==  ===    =======       ===  ===   ====   =
// ================================================================

target "esde-build" {
    context = "."
    dockerfile = "progs/emulators/es-de.dockerfile"
    tags = ["esde-build"]
    contexts = {
        build-base01 = "target:buildbase"
    }
}

target "dolphin-build" {
    context = "."
    dockerfile = "progs/emulators/dolphin.dockerfile"
    tags = ["dolphin-build"]
    contexts = {
        build-base01 = "target:buildbase"
    }
}

target "rpcs3-build" {
    context = "."
    dockerfile = "progs/emulators/rpcs3.dockerfile"
    tags = ["rpcs3-build"]
    contexts = {
        build-base01 = "target:buildbase"
        base-sdl = "target:sdl"
        base-openal = "target:openal"
        // qt-base = "target:qt"
    }
}

target "pcsx2-build" {
    context = "."
    dockerfile = "progs/emulators/pcsx2.dockerfile"
    tags = ["pcsx2-build"]
    contexts = {
        build-base01 = "target:buildbase"
        base-sdl3 = "target:sdl3"
    }
}

target "n64-build" {
    context = "."
    dockerfile = "progs/emulators/n64.dockerfile"
    tags = ["n64-build"]
    contexts = {
    }
}

target "xbox-build" {
    context = "."
    dockerfile = "progs/emulators/xemu.dockerfile"
    tags = ["xbox-build"]
    contexts = {
    }
}

target "flycast-build" {
    context = "."
    dockerfile = "progs/emulators/flycast.dockerfile"
    tags = ["dreamcast-build"]
    contexts = {
    }
}

target "duckstation-build" {
    context = "."
    dockerfile = "progs/emulators/duckstation.dockerfile"
    tags = ["ps1-build"]
    contexts = {
    }
}
// ====================================================
// =       ==================================  ========
// =  ====  =================================  ========
// =  ====  =================================  ========
// =  ====  ===   ===    ====   ===  = ======  ===   ==
// =  ====  ==  =  ==  =  ==  =  ==     ===    ==  =  =
// =  ====  ==     ==  =  ==     ==  =  ==  =  ===  ===
// =  ====  ==  =====    ===  =====  =  ==  =  ====  ==
// =  ====  ==  =  ==  =====  =  ==  =  ==  =  ==  =  =
// =       ====   ===  ======   ===  =  ===    ===   ==
// ====================================================
target "buildbase" {
    context = "."
    dockerfile = "progs/dependencies/buildbase.dockerfile"
    tags = ["build-base01"]
}

target "qt" {
    context = "."
    dockerfile = "progs/dependencies/qt.dockerfile"
    tags = ["qt-base"]
}

target "sdl" {
    context = "."
    dockerfile = "progs/dependencies/sdl.dockerfile"
    tags = ["base-sdl"]
}

target "openal" {
    context = "."
    dockerfile = "progs/dependencies/openal.dockerfile"
    tags = ["base-openal"]
}

target "sdl3" {
    context = "."
    dockerfile = "progs/dependencies/sdl3.dockerfile"
    tags = ["base-sdl3"]
}
