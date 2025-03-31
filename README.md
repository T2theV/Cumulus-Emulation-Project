# ESDE-Docker
A docker image for making a gaming webtop that can be hosted privately

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

Copy udev rules to your host server to enable sunshine hotplugging controllers:

```
cp emu-webtop:/udev/80-sunshine-ins.rules /etc/udev/rules.d/
sudo chown root:root /etcudev/rules.d/80-sumshine-ins.rules
sudo udevadm reload
cp emu-webtop:/udev/docker_tty.sh /usr/local/bin/
```

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

**I NEED YOUR HELP**

I have a good start, but there is much to be done before I would consider the project stable. 

See issues for a list of items to be done to make this better!

**NO RETROARCH**
I'm trying to avoid retroarch as mucha as possible. This project aims to replace the Retroarch framework. Why? Nothing against Retroarch, but 6/7th gen console projects typically don't optimize for Retroarch which is the starting point for this project. I don't have much experience emulating earlier consoles which then I'll consider introducing Retroarch.