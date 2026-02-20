# Introduction

## What is it?
The Cumulus Emulation Project is a System Emulation package that focuses 
on a beautiful interface to play old console games on any device via streaming
direcly from container using a supported app, or via web browser. Unlike
retroarch, batocera, Games-on-Whales, or other projects; the underlying
engines are always the latest by being pulled on develop rather than waiting
for release builds. This means for the end user no delay in waiting for a
"stable" release since most of the emulator projects are rolling improvments
anyways.

# Status
I've been running a build for a few months now. I've played a few games on
dolphin, RPCS3, and flycast and have had a great time. I'm also glad of the
progress that has been made. I've learned alot about Docker, the ideas around
runing multiple prgrams in a portable image, and how a controller input get's
from hardware to programs under linux. That being said, it hasn't gotten to a
point where I could advertize it.

I've also wanted to structure the project by targeting multible dockerbased
services: Kasm, GamesOnWhales, and LinuxServer.io. Right now, the only
implementation that works is a Linuxserver.io based image that takes some input
commands that GoW uses to get the contoller app input working.

# Project Requirements
## Why/What needs to happen
So at the core, what I care about, or what I see the issue is in the current
emulation ecosystem is a compormise between getting an easy-to-use program
and a programs that can run every game accurately. Retroarch is the best 
analouge to how I vision this project, however, it's becoming clearer as the 
gaming community ages, the demands for the 6th generation consoles to become 
integrated is increasing. The developers already have an argeous task of
emulating complex closed source hardare via reverse engineering and then being
asked to now form that into RetroArch's ecosystem as a core. I don't see the
communites actively keeping both cores and targets updated, especially
compared to batocera that utilizes an OS approach.

## Deployment
The 6th Generation Consoles also have a hard time running on mobile devices. I
believe that it's better to have a good streaming expierience that can run on
commodity hardware rather than having a solution that requires a significant
investment that is physically more difficult to use. 

My ideal solution is a docker container that can be deployed on any hardware.
Any computer can run a container and users can set up their seperate devices
to have a uniform experience across devices.

## Learning
This project combines for me a love of gaming with learning about modern computing strategies. Docker has become a DeFacto standard for software
distribution. Linux is in a hot package manager war. Consoles have faultered to
straming services and mobile computing. There are a couple things that I have
learned about modern software deployment strategies I need to adjust to address some flaws.

The biggest issue currently is the package war. Different emulation projects
develop on different linux distribuitons. This means they typically have
different dependencies that often conflict. Emulation projects haven't agreed
on a common package format making is difficult.

The second issue is Docker. It is a great software for packaging software and
distributing programs/systems to different loactaions and machiens. It falls
way short, however, on some of it's core components. The first problem being
the default images. Having an Ubuntu, Arch, Alpine, Debian, machines instantly
is great for adoption, however the images are not customized to docker platform
specifically creating the side effect of bloat when setting up the
enviornment. Apt is usually configured to download manpages and other things 
that are just not needed. This is compounded by the fact that docker doesn't effectively use it's layered filesystem effectively. Of analyzing each step
to see if that command affects subsequent layers, that is automatically
assumed so higher layers can only be midigated so much before you need to
make lower layers.

The last issue is that Dockerfiles are just glorified shell scripts. There's
nothing worng with shell languages, especially since they are needed to
perform building processes. Docker doesn't have a good way to import steps from
other files meaning that build files get long and complicated. There are other 
ways to manage layers and steps, but that involves using yet another language
and still doesn't address the issues with the tree philosophy.

# Roadmap
I'm switching the project from dockerfiles to nix files. I want to really
target distributing binaries of the built projects and minimizing waste space
in docker images. After much consideration and reading up about Nix, I have
decided it's better to learn about Nix rather than try to recreate a
Linuxserver or GOW image. I believe nix has the best path to make a controlled
runtime enviornment by fine handling the dependencies as well as making images
with only the needed files.

I'm also going to focus on one base image from the Selkies VDI package. I
previously used kasm-vnc (again based off of Linuxserver.io). Selkies has the 
appropriate aim of what I am trying to accomplish.

Last projects are just a couple glue programs that need to be done. First is
the startup files. I have a system currently that will copy emulator config
files on staretup if not present. It's mainly bash scripts called via s6
overlay. That may need to change. Thers also a system to manage the individual 
configurations of the different emulators. That may or may not need to be
added.
