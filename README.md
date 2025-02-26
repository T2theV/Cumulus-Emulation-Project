# ESDE-Docker
A docker image for making a gaming webtop that can be host privately

Targets for infastructure are:
- Linuxserver.io base
- kasmweb-base
- Games-on-Whales base (sunshine)

Intent of this project is to be an Emulation Enthusiast platfrom be easilly updating the "Latest" versions of the emulators and being able to be easily depoyed via Docker. To achieve this, the platform is a docker build/bake project where emulators are build on bases containers, and the final container software stack is assembled. 

First image is the webtop emulation target. To build, run:

`docker buildx bake` 

After this runs, there will be an image named emu-webtop. 
To run the image:

`docker run --network host emu-webtop:latest`

Open your browser and go to "http://localhost:3000" You'll see your emulation-ready desktop.


This is a compose file to run the image with more features.
```
services:
  emu:
    image: emu-webtop:latest
    volumes:
      - /path/to/config:/config
      - /run/udev:/run/udev:rw
    device_cgroup_rules:
      - 'c 13:* rmw'
    devices:
      - /dev/dri/renderD128
      - /dev/uinput
    network_mode: host
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    security_opt:
      - seccomp:unconfined
```
See issues for a list of items to be done to make this better!