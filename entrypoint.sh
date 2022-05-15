#!/bin/bash
set -e

# required directory and files for enigma2
mkdir -p /dev/input
touch /dev/.udev

[ -f /usr/lib32/libc.so.6 ] && ln -snf /usr/lib32/libc.so.6 /usr/lib/libc.so.6

[ -f /usr/lib/aarch64-linux-gnu/libc.so.6 ] && ln -snf /usr/lib/aarch64-linux-gnu/libc.so.6 /usr/lib/libc.so.6

# start web server
service nginx start

echo "start Xvfb"
test -z "$RESOLUTION" && RESOLUTION="1280x720x16"
Xvfb "$DISPLAY" -ac -screen 0 "$RESOLUTION" &
xvfb_pid=$!
echo "exec command $@"
exec "$@"
echo "terminate"
kill ${xvfb_pid}
