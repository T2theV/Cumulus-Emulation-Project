# ESDE-Docker
A docker image for making a gaming webtop that I can host privately


Looking around at emulator things, everything is compile-distributed on the AUR. Also, Debian might have low kernels.
Let's support an Arch host and an Arch image.
Compile dependencies and copy resulting binaries to folder as a ESDE portable installation.
Use a webtop from linuxserver.io

## Update 4/30
kasm gamepad control runs from Kasm server. 
it is also able to pass through Android controllers to the image. tested on retroarch image. 

Flatpak not supported in containers. tested with a jammy webtop
So, still a question on how to build. no Kasm arch image. 

Need to keep executables in image. Wondering about doing ES-DE portable and copying files over. 