{
  patterns: {
    ip: {
      type: 'ip',
      ignore: ['127.0.0.1', '::1', '192.168.1.1'],
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
}
