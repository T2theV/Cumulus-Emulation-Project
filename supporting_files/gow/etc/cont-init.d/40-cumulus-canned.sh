#!/usr/bin/env bash
#
# 40-cumulus-canned.sh — "canned init": seed first-boot emulator default configs.
#
# Runs as root during container init (sourced by /entrypoint.sh), AFTER
# 10-setup_user.sh has created the retro user and $HOME. It invokes the canned
# seeder, which copies the bundled defaults from /etc/cumulus-emu/{config,local}
# into $HOME/.config and $HOME/.local/share — but ONLY creates files that do not
# already exist, so a returning user's own configs are never overwritten.
#
# Failure is nonfatal: seeding is a first-boot convenience and must never block
# the GOW/desktop startup.

if [ -f /etc/cumulus-emu/overall.sh ]; then
    bash /etc/cumulus-emu/overall.sh || gow_log "[40-cumulus-canned] canned seeding failed (nonfatal)"
fi
