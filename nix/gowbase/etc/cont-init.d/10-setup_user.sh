#!/usr/bin/env bash

set -e

gow_log "**** Configure default user ****"

if [[ "${UNAME}" != "root" ]]; then
    PUID="${PUID:-1000}"
    PGID="${PGID:-1000}"
    UMASK="${UMASK:-000}"

    gow_log "Setting default user uid=${PUID}(${UNAME}) gid=${PGID}(${UNAME})"
    
    # 1. Remove conflicting UID/GID from files if they already exist
    if id -u "${PUID}" &>/dev/null; then
        oldname=$(id -nu "${PUID}")
        gow_log "Removing existing user line for PUID ${PUID} (${oldname})"
        sed -i "/^[^:]*:[^:]*:${PUID}:/d" /etc/passwd
    fi

    if getent group "${PGID}" &>/dev/null; then
        oldgroup=$(getent group "${PGID}" | cut -d: -f1)
        gow_log "Removing existing group line for PGID ${PGID} (${oldgroup})"
        sed -i "/^[^:]*:[^:]*:${PGID}:/d" /etc/group
    fi

    # 2. Append the new Group entry using standard formatting
    # Format -> group_name:password:GID:user_list
    gow_log "Adding group entry manually via sed/echo"
    sed -i "/^${UNAME}:/d" /etc/group # Clean up name collision if any
    echo "${UNAME}:x:${PGID}:" | tee -a /etc/group > /dev/null

    # 3. Append the new User entry using standard formatting
    # Format -> username:password:UID:GID:gecos:home_dir:shell
    gow_log "Adding user entry manually via sed/echo"
    sed -i "/^${UNAME}:/d" /etc/passwd # Clean up name collision if any
    echo "${UNAME}:x:${PUID}:${PGID}:${UNAME},,,:${HOME}:/bin/bash" | tee -a /etc/passwd > /dev/null

    gow_log "Setting umask to ${UMASK}"
    umask "${UMASK}"

    gow_log "Ensure retro home directory is writable"
    chown "${PUID}:${PGID}" "${HOME}"

    gow_log "Ensure XDG_RUNTIME_DIR is writable"
    chown -R "${PUID}:${PGID}" "${XDG_RUNTIME_DIR}"
else
    gow_log "Container running as root. Nothing to do."
fi

gow_log "DONE"
