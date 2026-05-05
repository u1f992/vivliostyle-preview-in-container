#!/usr/bin/env bash

set -eEuo pipefail
shopt -s inherit_errexit
trap 'echo "Error on line $LINENO: $BASH_COMMAND (exit $?)" >&2' ERR

# Align the vivliostyle user with the mounted workdir's owner so files we
# create are owned by the host user, and so vivliostyle can write to /workdir
# regardless of the host user's UID. Without this the script fails on hosts
# whose user is not UID 1000 (e.g. GitHub Actions' runner is UID 1001).
HOST_UID=$(stat --format='%u' /workdir)
HOST_GID=$(stat --format='%g' /workdir)
if [ "$HOST_UID" -ne 0 ] && [ "$HOST_UID" -ne "$(id -u vivliostyle)" ]; then
  groupmod --non-unique --gid "$HOST_GID" vivliostyle
  usermod --non-unique --uid "$HOST_UID" --gid "$HOST_GID" vivliostyle
  chown --recursive "$HOST_UID:$HOST_GID" /home/vivliostyle /opt/puppeteer
fi

exec runuser -u vivliostyle -- env npm_config_update_notifier=false bash -c 'cd /workdir && npm --silent ci && exec npm exec vivliostyle build'
