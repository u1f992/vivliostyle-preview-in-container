#!/usr/bin/env bash

set -eEuo pipefail
shopt -s inherit_errexit
trap 'echo "Error on line $LINENO: $BASH_COMMAND (exit $?)" >&2' ERR

# Align the vivliostyle user with the mounted workdir's owner so files we
# create are owned by the host user, and so vivliostyle can write to /workdir
# regardless of the host user's UID. Without this the script fails on hosts
# whose user is not UID 1000.
HOST_UID=$(stat --format='%u' /workdir)
HOST_GID=$(stat --format='%g' /workdir)
if [ "$HOST_UID" -ne 0 ] && [ "$HOST_UID" -ne "$(id -u vivliostyle)" ]; then
  groupmod --non-unique --gid "$HOST_GID" vivliostyle
  usermod --non-unique --uid "$HOST_UID" --gid "$HOST_GID" vivliostyle
  chown --recursive "$HOST_UID:$HOST_GID" /home/vivliostyle /opt/puppeteer
fi

# Xtigervnc + noVNC for browser-based preview without X11 forwarding
#
# why-not:
# Xpra ships its own web client over an X11-forwarding protocol; no VNC
# involved. Clipboard sharing works better than noVNC's, and we wouldn't
# need the supervisord glue or the startup-wait shims below. We dropped
# it anyway:
# - Install is awkward; upstream actively warns against the distro packages
#   (https://github.com/Xpra-org/xpra/wiki/Distribution-Packages/36c6b4f4f2d86cc019ec22140fb262c7705f0402).
# - The default X server has a DPI bug that turns the mouse cursor
#   huge. Pulling in Xpra's patched dummy driver (one more dep) helps
#   but doesn't fully fix it; only pinning XCURSOR_SIZE=24 does.
# - The patched driver triggers another bug: browser resizes stop
#   propagating to the X root
#   (https://github.com/Xpra-org/xpra-html5/issues/424).
# - With the same setup as noVNC, clicks and selection were visibly
#   laggy. The lag came and went across browser reloads and we couldn't
#   pin down a cause.
DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -qq --yes --no-install-recommends \
  matchbox-window-manager=1.2.2+git20200512-2 \
  novnc=1:1.6.0-2 \
  supervisor=4.2.5-3 \
  tigervnc-standalone-server=1.15.0+dfsg-2 \
  >/dev/null

# Run npm ci as the vivliostyle user so the cache and node_modules
# end up owned by the same user that will run the preview server.
runuser -u vivliostyle -- env npm_config_update_notifier=false bash -c 'cd /workdir && npm --silent ci'

# Keep supervisord itself as root: the --tty pty (/dev/pts/*) is owned by root,
# so only root can open stdout_logfile=/dev/fd/1 to forward child output to the
# foreground terminal. Each [program:*] uses user=vivliostyle to drop privileges
# in the forked child, which inherits the already-open fd without a permission recheck.
cat >/tmp/supervisord.conf <<'EOF'
[supervisord]
nodaemon=true
silent=true
logfile=/tmp/supervisord.log
pidfile=/tmp/supervisord.pid
loglevel=info

[unix_http_server]
file=/tmp/supervisor.sock

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory=supervisor.rpcinterface:make_main_rpcinterface

[program:xtigervnc]
# -SendPrimary=0 stops every mouse-only selection from being pushed to the
# noVNC clipboard textarea (Linux's PRIMARY-selection-as-clipboard semantics
# do not match what the textarea is meant to represent). With this off only
# explicit CLIPBOARD updates (Ctrl+C in the in-X Chrome) are forwarded.
command=Xtigervnc :0 -geometry 1920x1080 -depth 24 -SecurityTypes None -AlwaysShared -AcceptSetDesktopSize -SendPrimary=0
user=vivliostyle
environment=HOME="/home/vivliostyle",SHELL="/bin/bash",USER="vivliostyle",LOGNAME="vivliostyle"
autorestart=true
priority=10
stdout_logfile=/tmp/xtigervnc.log
stderr_logfile=/tmp/xtigervnc.err.log

# matchbox-window-manager fails immediately if it can't connect to DISPLAY=:0,
# so wait until Xtigervnc creates /tmp/.X11-unix/X0
[program:matchbox]
command=/bin/sh -c "while [ ! -e /tmp/.X11-unix/X0 ]; do sleep 0.1; done; exec matchbox-window-manager"
user=vivliostyle
environment=DISPLAY=":0",HOME="/home/vivliostyle",SHELL="/bin/bash",USER="vivliostyle",LOGNAME="vivliostyle"
autorestart=true
priority=20
stdout_logfile=/tmp/matchbox.log
stderr_logfile=/tmp/matchbox.err.log

[program:websockify]
command=websockify --web /usr/share/novnc 14500 localhost:5900
user=vivliostyle
environment=HOME="/home/vivliostyle",SHELL="/bin/bash",USER="vivliostyle",LOGNAME="vivliostyle"
autorestart=true
priority=30
stdout_logfile=/tmp/websockify.log
stderr_logfile=/tmp/websockify.err.log

# vivliostyle preview launches Chrome via puppeteer; it needs DISPLAY=:0
# to be reachable, so wait for Xtigervnc to bring up the X socket first.
[program:vivliostyle]
command=/bin/sh -c "while [ ! -e /tmp/.X11-unix/X0 ]; do sleep 0.1; done; exec npm exec vivliostyle preview"
user=vivliostyle
# $ man runuser | grep -A 1 "if the target user is"
#        For backward compatibility, runuser defaults to not changing the current directory and to setting only the environment variables HOME and SHELL (plus USER and LOGNAME if the target user is not
#        root). This version of runuser uses PAM for session management.
environment=DISPLAY=":0",HOME="/home/vivliostyle",SHELL="/bin/bash",USER="vivliostyle",LOGNAME="vivliostyle"
directory=/workdir
autorestart=true
priority=40
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF

exec supervisord -c /tmp/supervisord.conf
