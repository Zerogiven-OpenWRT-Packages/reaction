// Bench config for Method B -- INLINE nft backend.
// No `retry`: every matching line fires the ban action, so feeding N lines
// produces N bans. Stream reads the FIFO that method-b-stream.sh writes to.
{
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
      }
    |||],
  ],

  stop: [
    ['nft', 'delete', 'table', 'inet', 'reaction'],
  ],

  streams: {
    bench: {
      cmd: ['cat', '/tmp/reaction-bench.fifo'],
      filters: {
        ban: {
          regex: [@'fail <ip>'],
          // no retry / no `after`: measure the add (ban) path only
          actions: {
            ban4: {
              cmd: ['nft', 'add', 'element', 'inet', 'reaction', 'bans', '{', '<ip>', '}'],
              ipv4only: true,
            },
            ban6: {
              cmd: ['nft', 'add', 'element', 'inet', 'reaction', 'bans6', '{', '<ip>', '}'],
              ipv6only: true,
            },
          },
        },
      },
    },
  },
}
