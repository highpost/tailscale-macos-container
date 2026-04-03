#!/bin/zsh

# container launch script

# Fetch the Tailscale auth key from Apple Keychain
# and store it in a local variable.
TS_KEY_VAL="$(
  security find-generic-password  \
    -a "$USER"                    \
    -s "tailscale-auth-key"       \
    -w
)"

# error checking
if [ -z "$TS_KEY_VAL" ]; then
    echo "Error: Could not retrieve Tailscale auth key from Keychain."
    exit 1
fi

# prepare arguments for "container run"
run_args=(
  --detach                            # run in the background
  --name alpine-ts-instance           # container instance name
  #--accept-dns=false                  # don't use MagicDNS for outbound lookups,
  #                                    # but still use MagicDNS for inbound SSH
  --env HOSTNAME=alpine-ts-server     # hostname
  --env TS_AUTHKEY                    # Tailscale auth key
  --volume "$(pwd)":/app              # mount runtime directory as /app
)

# launch the container
# NB: TS_KEY_VAL is passed implicitly to avoid key exposure.
TS_AUTHKEY="$TS_KEY_VAL" container run "${run_args[@]}" alpine-ts-image

# health check
echo -n "Waiting for Tailscale to initialize..."

COUNT=0
MAX_RETRIES=15
TAILSCALE_CLI=/Applications/Tailscale.app/Contents/MacOS/Tailscale

while [ $COUNT -lt $MAX_RETRIES ]; do
    if container exec alpine-ts-instance tailscale status >/dev/null 2>&1; then
        echo "\n✅ Container is online and authenticated."
        break
    fi
    
    echo -n "."
    sleep 2
    ((COUNT++))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "\n❌ Timeout: Tailscale failed to come online."
    exit 1
fi

# check whether the node has joined the Tailnet
echo "\nVerifying connectivity from host..."
sleep 2 # Give the control plane a moment to update

if $TAILSCALE_CLI status | grep -q "alpine-ts-server"; then
    echo "✅ $HOSTNAME is online."
else
    echo "⚠️ Container is running, but is not yet visible on the Tailnet."
fi

# cleanup
unset TS_KEY_VAL
