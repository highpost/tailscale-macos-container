#!/bin/zsh

# remove the container from your tailnet
# https://login.tailscale.com/admin/machines

# revoke the Tailscale node's identity
container exec alpine-ts-instance tailscale logout

# cleanup the specific container instance
container stop -f alpine-ts-instance  2>/dev/null
container rm   -f alpine-ts-instance  2>/dev/null

# cleanup the builder container
container builder stop                2>/dev/null
echo "y" | container builder delete   2>/dev/null

# clean up the storage layers
echo "y" | container prune            2>/dev/null
echo "y" | container image prune      2>/dev/null

# remove the container images
container image rm alpine-ts-image    2>/dev/null
container image rm alpine             2>/dev/null
