
local lib = import '.lib.jsonnet';

{
  streams: {
    ssh: {
      cmd: ['logread', '-f'],
      filters: {
        dropbear_failed: lib.filter_default + {
          regex: [
            @'dropbear\[\d+\]: Exit before auth from <<ip>:',
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
          retry: 10,
          retryperiod: '3h',
          actions: lib.banFor('12h'),
        },
      },
    },
  },
}
