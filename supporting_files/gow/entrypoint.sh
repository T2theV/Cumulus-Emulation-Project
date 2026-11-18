#!/usr/bin/env bash

set -e

# Ensure /tmp exists and is world-writable before any cont-init script runs.
# The image builder strips the store mode (the baked /tmp comes up root:755),
# and scripts that run as users (e.g. ps3 firmware install as 'retro') need
# write access from the very first init script.
mkdir -p /tmp
chmod 1777 /tmp

# The nix-built OpenSSL in this image ships CA certs at
# /etc/ssl/certs/ca-bundle.crt, but the runtime's default trust path is
# broken, so every HTTPS client (curl, Godot HTTPRequest) fails with
# "unable to get local issuer certificate". Point OpenSSL at the bundle
# explicitly; export so the whole process tree (cartouche, foot, ...) sees it.
export SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt

# Source functions from GOW utils
source /opt/gow/bash-lib/utils.sh

# Execute all container init scripts. Only run this if the container is started as the root user
if [ "$(id -u)" = "0" ]; then
    for init_script in /etc/cont-init.d/*.sh ; do
        gow_log
        gow_log "[ ${init_script}: executing... ]"
        #sed -i 's/\r$//' "${init_script}" # Remove Windows line endings
        # shellcheck source=/dev/null
        source "${init_script}"
    done
fi

# If a command was passed, run that instead of the usual init startup script
# shellcheck disable=SC2198
if [ -n "${@:-}" ]; then
    /bin/bash -c "$@"
    exit $?
fi
source /opt/gow/fix-gpu-renderer.sh
# Launch startup script as 'UNAME' user (some services will run as root)
gow_log "Launching the container's startup script as user '${UNAME}'"
chmod +x /opt/gow/startup.sh
exec gosu "${UNAME}" /opt/gow/startup.sh
