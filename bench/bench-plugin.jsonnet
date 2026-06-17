// Bench config for Method B -- nftables PLUGIN backend.
// No `retry`: every matching line fires the ban action, so feeding N lines
// produces N bans. The plugin creates/owns the `inet reaction` table itself,
// so there are no start/stop nft commands here.
{
  plugins: {
    nftables: {
      path: '/usr/bin/reaction-plugin-nftables',
      // Required on OpenWrt: no systemd/run0, so the plugin runs directly as
      // root and inherits CAP_NET_ADMIN + CAP_PERFMON.
      systemd: false,
    },
  },

  patterns: {
    ip: {
      type: 'ip',
      ignore: ['127.0.0.1', '::1'],
      // 198.18.0.0/15 is intentionally NOT ignored so the bench IPs get banned.
      ipv6mask: 64,
    },
  },

  state_directory: '/var/lib/reaction',
  concurrency: 0,

  streams: {
    bench: {
      cmd: ['cat', '/tmp/reaction-bench.fifo'],
      filters: {
        ban: {
          regex: [@'fail <ip>'],
          // no retry / no `after`: measure the add (ban) path only
          actions: {
            ban: {
              type: 'nftables',
              options: { set: 'bans', action: 'add' },
            },
          },
        },
      },
    },
  },
}
