target "default" {
    context = "."
    dockerfile = "images/webtop.dockerfile"
    tags = ["emu-webtop:latest"]
    contexts = {
        dolphin-dist = "target:dolphin-build"
        rpcs3-dist = "target:rpcs3-build"
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
        qt-base = "target:qt"
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