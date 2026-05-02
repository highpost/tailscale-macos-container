#!/bin/zsh

# copy the Tailscale auth key from the system clipboard to Apple Keychain
# https://login.tailscale.com/admin/settings/keys
#
# NB: The Tailscale auth key will not appear in the Passwords app.
#     Use show-ts-key-info-keychain.sh or Keychain Access.app instead.

echo -n "paste the Tailscale auth key: " && read -rs TEMP_KEY

security add-generic-password   \
  -a "$USER"                    \
  -s "tailscale-auth-key"       \
  -w "$TEMP_KEY"                \
  -U

unset TEMP_KEY
