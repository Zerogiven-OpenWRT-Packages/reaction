// Test config for reaction on OpenWrt -- WITHOUT the nftables plugin.
//
// Bans by shelling out to `nft` directly. Needs only the base `reaction`
// package (no reaction-plugin-nftables). This mirrors the approach used by the
// installed files/etc/reaction/{config,streams,.lib}.jsonnet, but bundled into
// a single self-contained file for quick testing.
//
// Run on the router:
//   reaction start -c /root/test-without-plugin.jsonnet
// Stop with Ctrl-C; the `stop` commands remove the nft table.
//
// !! BEFORE RUNNING: review `ignorecidr` below so you never ban your own
//    management network -- a wrong value here can lock you out of the router.

// Add/remove the offending IP to/from the nft sets, unbanning after `time`.
local banFor(time) = {
  ban4: {
    cmd: ['nft', 'add', 'element', 'inet', 'reaction', 'bans', '{', '<ip>', '}'],
    ipv4only: true,
  },
  ban6: {
    cmd: ['nft', 'add', 'element', 'inet', 'reaction', 'bans6', '{', '<ip>', '}'],
    ipv6only: true,
  },
  unban4: {
    cmd: ['nft', 'delete', 'element', 'inet', 'reaction', 'bans', '{', '<ip>', '}'],
    after: time,
    ipv4only: true,
  },
  unban6: {
    cmd: ['nft', 'delete', 'element', 'inet', 'reaction', 'bans6', '{', '<ip>', '}'],
    after: time,
    ipv6only: true,
  },
};

{
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

  // Build our own nft table/sets/chains at startup.
  start: [
    ['nft', |||
      table inet reaction {
        set bans {
          type ipv4_addr
          flags interval
          auto-merge
        }
        set bans6 {
          type ipv6_addr
          flags interval
          auto-merge
        }
        chain input {
          type filter hook input priority 0
          policy accept
          ip saddr @bans drop
          ip6 saddr @bans6 drop
        }
        chain forward {
          type filter hook forward priority 0
          policy accept
          ip saddr @bans drop
          ip6 saddr @bans6 drop
        }
      }
    |||],
  ],

  // Tear the table down at shutdown.
  stop: [
    ['nft', 'delete', 'table', 'inet', 'reaction'],
  ],

  streams: {
    // One stream reading the system log; dropbear (SSH) and LuCI both log here.
    log: {
      cmd: ['logread', '-f'],
      filters: {
        dropbear: {
          regex: [
            @'dropbear\[\d+\]: Bad password attempt for .* from <ip>:\d+',
            @'dropbear\[\d+\]: Login attempt for nonexistent user (.* )?from <ip>:\d+',
            @'dropbear\[\d+\]: Exit before auth from <<ip>:\d+>',
          ],
          // Ban after `retry` matches within `retryperiod`.
          // For a fast test, lower these (e.g. retry: 2, retryperiod: '2m').
          retry: 3,
          retryperiod: '6h',
          actions: banFor('48h'),
        },
        luci: {
          regex: [
            @'luci: failed login on .* for .* from <ip>',
          ],
          retry: 5,
          retryperiod: '3h',
          actions: banFor('12h'),
        },
      },
    },
  },
}
