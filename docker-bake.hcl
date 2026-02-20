target "default" {
    context = "."
    dockerfile = "images/webtop.dockerfile"
    tags = ["emu-webtop:latest"]
    contexts = {
        dolphin-dist = "target:dolphin-build"
        rpcs3-dist = "target:rpcs3-build"
        esde-dist = "target:esde-build"
        pcsx2-dist = "target:pcsx2-build"
        sdl3-dist = "target:sdl3"
        n64-dist = "target:n64-build"
        xbox-dist = "target:xbox-build"
        dreamcast-dist = "target:flycast-build"
        ps1-dist = "target:duckstation-build"
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
