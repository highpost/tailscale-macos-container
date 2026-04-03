# Using Tailscale with Apple's containerization stack

Apple’s containerization stack uses the Virtualization framework to spin up a
minimal Linux host for each container instance. Since neither the macOS host
kernel nor this specialized Linux guest kernel includes a native WireGuard
kernel module, the container must run Tailscale in userspace networking mode
(using netstack) instead of attaching to a standard kernel TUN device.

The container example in this repo starts `tailscaled` with
`--tun=userspace-networking`, authenticates the node using a Tailscale auth key
and then enables Tailscale SSH. Once the container joins your tailnet, you can
connect to it over Tailscale SSH and use Tailscale MagicDNS for naming, without
exposing any ports on the host or configuring a separate SSH server inside the
container.

## Auth key

1. Generate an auth key using the
   [Keys](https://login.tailscale.com/admin/settings/keys)
   tab with the following flags enabled:

   * Reusable
   * Ephemeral
   * Pre-authorized
   * relevant tags

2. Copy the new auth key to the macOS clipboard.

3. Store the new auth key in Apple Keychain using `store-ts-key-keychain.sh`.

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
- `store-ts-key-keychain.sh`: Copy the Tailscale auth key from the system
  clipboard to Apple Keychain for later use by `run.sh`.
