// Test config for reaction on OpenWrt -- WITH the nftables plugin.
//
// Requires the `reaction-plugin-nftables` package, which installs
// /usr/bin/reaction-plugin-nftables. The plugin creates and tears down the
// `inet reaction` nft table itself, so there are NO start/stop/nft commands
// here -- actions just reference the plugin by `type: nftables`.
//
// Run on the router:
//   reaction start -c /root/test-with-nftables-plugin.jsonnet
//
// !! BEFORE RUNNING: review `ignorecidr` below so you never ban your own
//    management network -- a wrong value here can lock you out of the router.

{
  plugins: {
    nftables: {
      path: '/usr/bin/reaction-plugin-nftables',
      // CRITICAL on OpenWrt: there is no systemd, so its `run0` isolation tool
      // is absent. Disable systemd isolation; reaction then spawns the plugin
      // directly as root and it inherits CAP_NET_ADMIN + CAP_PERFMON, which the
      // plugin needs to talk to netfilter. (With the default systemd: true,
      // reaction would try to exec run0 and fail.)
      systemd: false,
      // check_root defaults to true; the packaged plugin binary is root-owned.
    },
  },

  patterns: {
    ip: {
      type: 'ip',
      ignore: ['127.0.0.1', '::1'],
      // Never ban these ranges. ADJUST to match your LAN / management subnet.
      ignorecidr: ['10.0.0.0/8', '192.168.0.0/16', 'fd00::/8'],
      ipv6mask: 64,
    },
  },

  state_directory: '/var/lib/reaction',
  concurrency: 0,

  streams: {
    log: {
      cmd: ['logread', '-f'],
      filters: {
        dropbear: {
          regex: [
            @'dropbear\[\d+\]: Bad password attempt for .* from <ip>:\d+',
            @'dropbear\[\d+\]: Login attempt for nonexistent user (.* )?from <ip>:\d+',
            @'dropbear\[\d+\]: Exit before auth from <<ip>:\d+>',
          ],
          // For a fast test, lower these (e.g. retry: 2, retryperiod: '2m').
          retry: 3,
          retryperiod: '6h',
          actions: {
            ban: {
              type: 'nftables',
              // The plugin auto-creates set `bans` (-> bansv4/bansv6 for the
              // default `ip` version) plus input+forward drop rules.
              // `pattern` defaults to 'ip', matching the pattern declared above.
              options: { set: 'bans', action: 'add' },
            },
            unban: {
              type: 'nftables',
              options: { set: 'bans', action: 'delete' },
              after: '48h',
            },
          },
        },
        luci: {
          regex: [
            @'luci: failed login on .* for .* from <ip>',
          ],
          retry: 5,
          retryperiod: '3h',
          actions: {
            ban: {
              type: 'nftables',
              options: { set: 'bans', action: 'add' },
            },
            unban: {
              type: 'nftables',
              options: { set: 'bans', action: 'delete' },
              after: '12h',
            },
          },
        },
      },
    },
  },
}
