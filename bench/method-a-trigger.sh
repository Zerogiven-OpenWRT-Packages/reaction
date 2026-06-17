#!/bin/sh
# Method A -- trigger-based benchmark for reaction's ban backend.
#
# Drives N bans via `reaction trigger` (which bypasses the retry counter, so one
# call == one immediate ban) and measures wall time + system CPU. Run it once
# per config and compare the numbers:
#
#   ./method-a-trigger.sh /root/test-without-plugin.jsonnet      5000 log.dropbear
#   ./method-a-trigger.sh /root/test-with-nftables-plugin.jsonnet 5000 log.dropbear
#
# Each `reaction trigger` is itself a process spawn paid equally by both modes,
# so it adds constant noise. If the two runs come out close, use Method B.
#
# Stop the service first:  /etc/init.d/reaction stop
# Uses the RFC-2544 benchmark range 198.18.0.0/15 (non-routable, safe).

set -u

CONFIG="${1:?usage: $0 <config.jsonnet> [N] [stream.filter]}"
N="${2:-5000}"
TARGET="${3:-log.dropbear}"
SOCK=/run/reaction/reaction.sock

[ -f "$CONFIG" ] || { echo "config not found: $CONFIG" >&2; exit 1; }
if [ -S "$SOCK" ] || pidof reaction >/dev/null 2>&1; then
  echo "reaction already running -- stop it first: /etc/init.d/reaction stop" >&2
  exit 1
fi

RPID=""
cleanup() {
  reaction stop >/dev/null 2>&1 || true
  sleep 1
  [ -n "$RPID" ] && kill "$RPID" >/dev/null 2>&1 || true
  nft delete table inet reaction >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# system busy jiffies (USER_HZ) from /proc/stat: user + nice + system
busy() { read -r _ u n s _ < /proc/stat; echo $((u + n + s)); }
now()  { cut -d' ' -f1 /proc/uptime; }
ipfor() { echo "198.$((18 + $1 / 65536)).$((($1 / 256) % 256)).$(($1 % 256))"; }
rss()  { awk '/VmRSS/{print $2" "$3}' "/proc/$1/status" 2>/dev/null || echo "?"; }
plugin_pid() {
  for p in /proc/[0-9]*; do
    [ -r "$p/cmdline" ] || continue
    tr '\0' ' ' < "$p/cmdline" 2>/dev/null | grep -q reaction-plugin-nftables && { basename "$p"; return; }
  done 2>/dev/null
}

# baseline: background busy jiffies over 1s, used to flag "drained"
b0=$(busy); sleep 1; b1=$(busy)
BASE=$((b1 - b0))
THRESH=$((BASE + 5))

reaction start -c "$CONFIG" >/tmp/reaction-bench.log 2>&1 &
RPID=$!
i=0; while [ ! -S "$SOCK" ]; do sleep 1; i=$((i + 1)); [ "$i" -gt 15 ] && { echo "reaction failed to start; see /tmp/reaction-bench.log" >&2; exit 1; }; done

BUSY_START=$(busy); T0=$(now)
i=0
while [ "$i" -lt "$N" ]; do
  reaction trigger "$TARGET" "ip=$(ipfor "$i")" >/dev/null 2>&1 || true
  i=$((i + 1))
done

# wait for the ban actions to drain (1s windows near baseline; 120s cap)
g=0
while [ "$g" -lt 120 ]; do
  a=$(busy); sleep 1; b=$(busy); g=$((g + 1))
  [ $((b - a)) -le "$THRESH" ] && break
done
T1=$(now); BUSY_END=$(busy)

WALL=$(awk -v a="$T0" -v b="$T1" 'BEGIN{printf "%.2f", b - a}')
CPU=$((BUSY_END - BUSY_START))
CPU_ADJ=$(awk -v c="$CPU" -v base="$BASE" -v w="$WALL" 'BEGIN{v=c-base*w; printf "%.0f", v<0?0:v}')
PP=$(plugin_pid)

echo
echo "==== Method A :: $CONFIG ===="
printf 'bans            : %s\n' "$N"
printf 'wall time       : %s s  (%s ms/ban)\n' "$WALL" "$(awk -v w="$WALL" -v n="$N" 'BEGIN{printf "%.2f", 1000*w/n}')"
printf 'system CPU      : %s jiffies raw  /  %s jiffies minus baseline\n' "$CPU" "$CPU_ADJ"
printf 'baseline busy   : %s jiffies/s\n' "$BASE"
printf 'reaction RSS    : %s\n' "$(rss "$RPID")"
if [ -n "$PP" ]; then printf 'plugin RSS      : %s\n' "$(rss "$PP")"; else printf 'plugin RSS      : (none)\n'; fi
echo "(lower wall time + lower CPU = faster backend on this hardware)"
