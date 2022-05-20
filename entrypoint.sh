#!/bin/bash
set -e

# required directory and files for enigma2
mkdir -p /dev/input
touch /dev/.udev

# start sshd
/usr/sbin/sshd -D &

# start ftp
start-stop-daemon -S -b -x /usr/sbin/vsftpd -- /etc/vsftpd.conf

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
