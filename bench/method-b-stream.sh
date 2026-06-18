#!/bin/sh
# Method B -- stream-fed microbenchmark for reaction's ban backend.
#
# Feeds N synthetic log lines through a FIFO so reaction fires bans *internally*
# (no per-ban CLI process), isolating the ban backend. Run it once per backend
# using the matching bench config and compare:
#
#   ./method-b-stream.sh ./bench-inline.jsonnet  20000
#   ./method-b-stream.sh ./bench-plugin.jsonnet  20000
#
# The bench configs declare a no-`retry` filter (every matching line bans) whose
# stream reads this FIFO. Stop the service first:  /etc/init.d/reaction stop
# Uses the RFC-2544 benchmark range 198.18.0.0/15 (non-routable, safe).

set -u

CONFIG="${1:?usage: $0 <bench-config.jsonnet> [N]}"
N="${2:-20000}"
FIFO=/tmp/reaction-bench.fifo
SOCK=/run/reaction/reaction.sock

[ -f "$CONFIG" ] || { echo "config not found: $CONFIG" >&2; exit 1; }
if [ -S "$SOCK" ] || pidof reaction >/dev/null 2>&1; then
  echo "reaction already running -- stop it first: /etc/init.d/reaction stop" >&2
  exit 1
fi

RPID=""
cleanup() {
  exec 7>&- 2>/dev/null || true
  reaction stop >/dev/null 2>&1 || true
  sleep 1
  [ -n "$RPID" ] && kill "$RPID" >/dev/null 2>&1 || true
  nft delete table inet reaction >/dev/null 2>&1 || true
  rm -f "$FIFO"
}
trap cleanup EXIT INT TERM

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

# the FIFO must exist before reaction starts so the stream's `cat` can open it
rm -f "$FIFO"; mkfifo "$FIFO"

b0=$(busy); sleep 1; b1=$(busy)
BASE=$((b1 - b0))
THRESH=$((BASE + 5))

reaction start -c "$CONFIG" >/tmp/reaction-bench.log 2>&1 &
RPID=$!
i=0; while [ ! -S "$SOCK" ]; do sleep 1; i=$((i + 1)); [ "$i" -gt 15 ] && { echo "reaction failed to start; see /tmp/reaction-bench.log" >&2; exit 1; }; done

# open the FIFO for writing (the stream's cat is the reader, already blocked on it)
exec 7>"$FIFO"

BUSY_START=$(busy); T0=$(now)
i=0
while [ "$i" -lt "$N" ]; do
  printf 'fail %s\n' "$(ipfor "$i")" >&7
  i=$((i + 1))
done

# wait for the ban actions to drain (1s windows near baseline). DRAIN_CAP guards
# against a hang; if it's hit the run didn't finish and the result is truncated.
g=0; drained=0
while [ "$g" -lt "${DRAIN_CAP:-600}" ]; do
  a=$(busy); sleep 1; b=$(busy); g=$((g + 1))
  [ $((b - a)) -le "$THRESH" ] && { drained=1; break; }
done
[ "$drained" -eq 0 ] && echo "WARNING: drain hit ${g}s cap -- result TRUNCATED, use a smaller N" >&2
T1=$(now); BUSY_END=$(busy)

WALL=$(awk -v a="$T0" -v b="$T1" 'BEGIN{printf "%.2f", b - a}')
CPU=$((BUSY_END - BUSY_START))
CPU_ADJ=$(awk -v c="$CPU" -v base="$BASE" -v w="$WALL" 'BEGIN{v=c-base*w; printf "%.0f", v<0?0:v}')
PP=$(plugin_pid)

echo
echo "==== Method B :: $CONFIG ===="
printf 'bans fed        : %s\n' "$N"
printf 'wall time       : %s s  (%s ms/ban)\n' "$WALL" "$(awk -v w="$WALL" -v n="$N" 'BEGIN{printf "%.3f", 1000*w/n}')"
printf 'system CPU      : %s jiffies raw  /  %s jiffies minus baseline\n' "$CPU" "$CPU_ADJ"
printf 'baseline busy   : %s jiffies/s\n' "$BASE"
printf 'reaction RSS    : %s\n' "$(rss "$RPID")"
if [ -n "$PP" ]; then printf 'plugin RSS      : %s\n' "$(rss "$PP")"; else printf 'plugin RSS      : (none)\n'; fi
echo "(lower wall time + lower CPU = faster backend on this hardware)"
