{
  patterns: {
    ip: {
      type: 'ip',
      ignore: ['127.0.0.1', '::1'],
      ignorecidr: ['10.0.0.0/8', '192.168.0.0/16'],
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
        }
        set bans6 {
          # interval (a /64 prefix per the ipv6mask above needs it); a hash set
          # like `bans` can only hold exact addresses. IPv4 single IPs use a
          # plain hash set so inserts stay O(1) as the banlist grows -- interval
          # sets cost O(set size) per insert (O(N^2) over a full banlist).
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

  stop: [
    ['nft', 'delete', 'table', 'inet', 'reaction'],
  ],
}
