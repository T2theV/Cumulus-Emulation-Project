# Cumulus Emulation Project
The Quest to be the perfect Emulation Gaming Container.
Run your favorites On your own hardware!

Every Emulator has enough testing making it safe for rolling release usag. No more waiting for next quarter to get the latest features. Get the latest improvements already optimized for 1080p, No tinkering with backends, It just works!

Included Emulators:

| Emulator | Executable | Rom Folder |
| --- |--- | --- |
| Eden | eden --platform xcb | switch, switch-updates |
| Dolphin | dolphin-emu | gc, wii |
| Flycast | flycast | dreamcast |
| PCSX2 | pcsx2-qt | ps2 |
| RMG | RMG | n64 |
| RPCS3 | rpcs3 -platform xcb | ps3 |
| Xemu | xemu | xbox |
| Xenia Edge | xenia-edge | xbox360 |

## Running the Image

Currently, an Application for Games On Whales is the only supported route. Add the code below to your wolf/cfg/wolf.cfg file:
```
    [[profiles.apps]]
    icon_png_path = 'https://raw.githubusercontent.com/T2theV/Cumulus-Emulation-Project/icon/icons/Cumulus_Scaled.png'
    title = 'Cumulus'

        [profiles.apps.runner]
        base_create_json = '''{
  "HostConfig": {
    "IpcMode": "host",
    "Privileged": false,
    "Ulimits": [{"Name":"memlock", "Hard":-1, "Soft":-1}],
    "SecurityOpt": ["seccomp=unconfined", "apparmor=unconfined"],
    "CapAdd": ["SYS_ADMIN", "SYS_NICE", "SYS_PTRACE", "NET_RAW", "MKNOD", "NET_ADMIN"],
    "DeviceCgroupRules": ["c 13:* rmw", "c 244:* rmw"]
  }
}
'''
        devices = []
        env = [ 'RUN_GAMESCOPE=1', 'GOW_REQUIRED_DEVICES=/dev/input/event* /dev/dri/* /dev/nvidia*' ]
        image = 'ghcr.io/t2thev/cumulus-emulation-project:latest'
        mounts = [ '</path/to/your/roms>:/ROMs' ]
        name = 'cumulusEP'
        ports = []
        type = 'docker'
```
## Prepping your Library
Use skyscraper to create the Pegasus Metadata file. Modify it to utilize your library. Pegasus searches for metadata files in ```/ROMS/<console code>```
## TODO Sample

## Building
```
cd emulators/
./localbuild.sh
cd ..
NIXPKGS_ALLOW_UNFREE=1 nix-build gowbase.nix
```                                         
### Build in docker
From the checkout root:
```
docker run --rm -v ./:/work nixos/nix nix-shel -p jq curl bash --command ' cd /work/wmulators && ./localbuild.sh && cd .. && NIXPKGS_ALLOW_UNFREE=1 nix-build gowimage.nix && cp $(nix-store --query ./result) ./CEP.tar.gz'
```
Then load into your docer instance

```docker load -i CEP.tar.gz```

## How it works
Nix is used to build up-to-date versions of the Emulators. 
Overlays are applied to pull in the new Revisions and changes against current unstable Nix branch of packages. Nurl is used to get the new hashes for the source and save as JSON files. With all data in place, the build takes place.

## Contributing
**I NEED YOUR HELP!!!**

I have a good start, but there is much to be done before I would consider the project stable. 

**NO RETROARCH**

I'm trying to avoid retroarch as mucha as possible. This project aims to replace the Retroarch framework. Why? Nothing against Retroarch, but 6/7th gen console projects typically don't optimize for Retroarch which is the starting point for this project. I don't have much experience emulating earlier consoles.