
local lib = import '.lib.jsonnet';

{
  streams: {
    ssh: {
      cmd: ['logread', '-f'],
      filters: {
        dropbear_failed: lib.filter_default + {
          regex: [
            @'dropbear\\[.*\\]: Login attempt for nonexistent user from <ip>:',
            @'dropbear\\[.*\\]: Bad password attempt for .* from <ip>',
          ],
          retry: 5,
          retryperiod: '6h',
          actions: lib.banFor('48h'),
        },
      },
    },

    luci: {
      cmd: ['logread', '-f'],
      filters: {
        luci_failed: lib.filter_default + {
          regex: [
            @'luci: failed login on .* for .* from <ip>',
          ],
          retry: 5,
          retryperiod: '3h',
          actions: lib.banFor('12h'),
        },
      },
    },
  },
}
