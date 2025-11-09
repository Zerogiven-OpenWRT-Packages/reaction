local ipBanNft4 = ['nft', 'add', 'element', 'inet', 'reaction', 'bans', '{', '<ip>', '}'];
local ipUnbanNft4 = ['nft', 'delete', 'element', 'inet', 'reaction', 'bans', '{', '<ip>', '}'];

local ipBanNft6 = ['nft', 'add', 'element', 'inet', 'reaction', 'bans6', '{', '<ip>', '}'];
local ipUnbanNft6 = ['nft', 'delete', 'element', 'inet', 'reaction', 'bans6', '{', '<ip>', '}'];

local banFor(time) = {
  ban4: {
    cmd: ipBanNft4,
    ipv4only: true,
  },
  ban6: {
    cmd: ipBanNft6,
    ipv6only: true,
  },
  unban4: {
    cmd: ipUnbanNft4,
    after: time,
    ipv4only: true,
  },
  unban6: {
    cmd: ipUnbanNft6,
    after: time,
    ipv6only: true,
  },
};

local logAction(text) = {
  log: {
    cmd: ['logger', '-t', 'reaction', text],
  },
};

local filter_default = {
  retry: 3,
  retryperiod: '3h',
  actions: banFor('24h'),
};

{
  banFor: banFor,
  logAction: logAction,
  filter_default: filter_default,
}
