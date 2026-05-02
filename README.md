# Using Tailscale with Apple's containerization stack

Apple's macOS containerization stack uses the Virtualization framework to spin
up a minimal Linux host VM for each container instance. Since neither the macOS
host kernel nor the specialized Linux guest VM kernel includes a native
WireGuard kernel module, the container must run Tailscale in userspace
networking mode instead of attaching to a standard kernel TUN device.

The container example in this repo starts `tailscaled` with
`--tun=userspace-networking`, authenticates the node using a Tailscale auth key
and then enables Tailscale SSH. Once the container joins your tailnet, you can
use Tailscale MagicDNS for naming and then connect to the container over
Tailscale SSH without exposing any ports on the host or configuring a separate
SSH server inside the container.

This example also demonstrates a macOS-specific method of storing the Tailscale
auth key in Apple Keychain.

## Modify access controls

### Create a tag

[Access controls > Tags](https://login.tailscale.com/admin/acls/visual/tags)

- Tag name: `myservers`
- Tag owner: `person1@gmail.com`
- Note: `server containers: myserver1, myserver2, ...`

### Modify the Tailscale SSH access controls

[Access controls > Tailscale SSH](https://login.tailscale.com/admin/acls/visual/tailscale-ssh/)

- add the new tag to the *Destination* array: `"myservers",`
- add Linux container usernames to the *Destination users* array:
  `"player1", "player2",`
- change the `"action":` value from `"check",` to `"accept",`
- *(optional)*: remove `"root",` from the `users:` array.

## Create a Tailscale auth key

1. Generate an auth key using the
   [Keys](https://login.tailscale.com/admin/settings/keys)
   tab with the following flags enabled:

   * Reusable
   * Pre-authorized
   * newly generated tag

2. Copy the new auth key to the macOS clipboard.

3. Store the new auth key in Apple Keychain using `store-ts-key-keychain.sh`.

## Build the image

```
./build.sh
```

## Run the container

```
./run.sh
```

## Connect to the container

- `tailscale ssh player1@alpine-ts-server`

- `container exec -it alpine-ts-instance /bin/sh`

## Files

`Containerfile` and `tini-start.sh` should work on other OCI‑compatible
container platforms. However, those platforms typically provide a kernel TUN
device, so this userspace networking technique is mainly a macOS‑specific
workaround rather than a general best practice.

Additional helper scripts provide macOS‑specific integration with Apple's
`container` CLI:

- `build.sh`: Builds the container image.
- `run.sh`: Launches a container instance and retrieves the Tailscale auth key
  from Apple Keychain. It also demonstrates how to mount a local folder into
  a container using the `--volume` command-line option.
- `cleanup.sh`: Removes the container from your tailnet, removes the container
  instance and deletes the container image.
- `store-ts-key-keychain.sh`: Copies the Tailscale auth key from the system
  clipboard to Apple Keychain for later use by `run.sh`.
