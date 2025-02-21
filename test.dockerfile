FROM lscr.io/linuxserver/webtop:ubuntu-mate
COPY tim.run /etc/s6-overlay/s6-rc.d/svc-kasmvnc/run

RUN sudo apt update && sudo apt install -y miniupnpd
COPY sunshine.deb .
# RUN sudo dpkg -i ./sunshine.deb

# root -AcceptSetDesktopSize false