# Cumulus Emulation Project
Latest Emulatiors In the Cloud. 

## Building
```
cd nix/
docker buildx build -t <your-tag> .
```

## Running the Image

To run the image:

`docker run -v path-to-roms:/ROMs -v path-to-config:/config -p 3001:3001 -e RUN_EMU <supported emultor> cumulus-ep:latest`

Supported Emulators:

| Emulator | RUN_RMU |
| --- | --- |
| Eden | eden |
| Dolphin | dolphin-emu |
| Flycast | flycast |
| PCSX2 | pcsx2-qt |
| RPCS3 | rpcs3 |
| Xenia Canary | xenia_canary |


Open your browser and go to "http://localhost:3001" You'll see your emulation-ready desktop.

This is a compose file to run the image with more features.

```yaml
services:
  emulation:
    image: ghcr.io/t2thev/cumulus-ep:latest
    volumes:
      - /path/to/config:/config
    devices:
      - /dev/dri/renderD128
    ports: 
      - 3001:3001
    restart: unless-stopped
    security_opt:
      - seccomp:unconfined
```

## How it works
Based on a custom Linuxserver image, the base  project used selkies. This
image is meant to run one supported emulator on the 3001 port. 

Nix is used to build up-to-date versions of the Emulators. With nix though,
that does make the emulators somewhat cutsom. for example, when compatible,
there is no OpenGL support.

## Contributing
**I NEED YOUR HELP!!!**

I have a good start, but there is much to be done before I would consider the project stable. 

**NO RETROARCH**

I'm trying to avoid retroarch as mucha as possible. This project aims to replace the Retroarch framework. Why? Nothing against Retroarch, but 6/7th gen console projects typically don't optimize for Retroarch which is the starting point for this project. I don't have much experience emulating earlier consoles.