**Use uci config to create .jsonnet files**

**Plugin config: set `systemd: false` on every declared plugin**
- reaction's plugin launcher (`src/concepts/plugin.rs`) uses systemd's `run0` for
  containerization when running as root with `systemd: true` (the default).
- `run0` is systemd-only and does not exist on OpenWrt, so that path fails to spawn.
- With `systemd: false`, reaction spawns the plugin directly as a child and it
  inherits reaction's (root) capabilities — including CAP_NET_ADMIN + CAP_PERFMON
  needed by the nftables/ipset plugins. No procd capabilities/seccomp setup required.
- Validate the `plugins:` config block + action wiring on a live system before
  committing example configs to the repo.
