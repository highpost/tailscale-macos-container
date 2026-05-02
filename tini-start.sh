#!/bin/sh

# init script

# set the hostname with a passed-in environment variable
if [ ! -z "$HOSTNAME" ]; then
    hostname "$HOSTNAME"
    echo "$HOSTNAME" > /etc/hostname
fi

# start the Tailscale daemon in userspace networking mode
# (not with a kernel extension) and then run it in the background
# https://tailscale.com/kb/1278/tailscaled
/usr/sbin/tailscaled                             \
    --tun=userspace-networking                   \
    --port=0                                     \
    --state=/var/lib/tailscale/tailscaled.state  \
    --socket=/var/run/tailscale/tailscaled.sock  &

# save the PID for later use
TS_PID=$!

# wait for the socket
sleep 5

# authenticate and enable the Tailscale-native SSH server
# https://tailscale.com/kb/1241/tailscale-up
tailscale up                        \
    --authkey=${TS_AUTHKEY}         \
    --advertise-tags=tag:myservers  \
    --hostname=${HOSTNAME}          \
    --reset                         \
    --ssh                           \
  || { echo "Tailscale up failed"; kill $TS_PID; exit 1; }

# keep the connection alive
while kill -0 $TS_PID 2>/dev/null; do
    if ! tailscale status --peers=false > /dev/null 2>&1; then
        echo "Tailscale connection lost (likely Mac sleep). Re-authenticating..."
        tailscale up --ssh --reset
    fi
    sleep 30
done
