#!/bin/sh
# Sweep Method B across several N to answer the key question: is the plugin's
# per-ban cost CONSTANT (flat ms/ban as N grows -> per-op plumbing: remoc/JSON/
# ctx) or does it RISE with N (-> libnftables cache re-reading the growing set,
# i.e. superlinear)?
#
# Usage:  ./sweep-n.sh <bench-config.jsonnet> [N1 N2 ...]
#   e.g.  ./sweep-n.sh ./bench-plugin.jsonnet
#         ./sweep-n.sh ./bench-inline.jsonnet 1000 5000 20000
#         RANDOM_IPS=1 ./sweep-n.sh ./bench-inline.jsonnet   # realistic IPs
#
# RANDOM_IPS=1 feeds scattered IPs (passed through to method-b) that an interval
# set can't auto-merge -- use it to compare interval vs hash sets honestly; the
# default sequential IPs let auto-merge collapse the set and flatter intervals.
#
# Run it for both backends and compare the shapes. CPU/1k (CPU jiffies per 1000
# bans) is the cleanest signal -- it normalises out N and HZ.
# Stop the service first:  /etc/init.d/reaction stop

set -u
export LC_ALL=C   # consistent '.' decimals regardless of host locale

DIR=$(dirname "$0")
CONFIG="${1:?usage: $0 <bench-config.jsonnet> [N ...]}"
shift
NS="${*:-1000 2000 5000 10000 20000}"
SOCK=/run/reaction/reaction.sock
OUT=/tmp/reaction-sweep.out

[ -f "$CONFIG" ] || { echo "config not found: $CONFIG" >&2; exit 1; }

# wait until the reaction daemon has fully exited, then clear any stale socket
wait_stopped() {
  i=0
  while pidof reaction >/dev/null 2>&1; do
    i=$((i + 1)); [ "$i" -gt 30 ] && break; sleep 1
  done
  rm -f "$SOCK"
}

echo "sweep $CONFIG over N = $NS"
echo
printf '%-8s %-9s %-9s %-9s %-8s\n' N wall_s ms/ban CPU_adj CPU/1k
printf '%-8s %-9s %-9s %-9s %-8s\n' -------- --------- --------- --------- --------
for N in $NS; do
  wait_stopped
  if ! "$DIR/method-b-stream.sh" "$CONFIG" "$N" > "$OUT" 2>&1; then
    echo "  N=$N: run failed, see $OUT" >&2
    continue
  fi
  wall=$(awk '/^wall time/{print $4}' "$OUT")
  msban=$(awk -F'[()]' '/ms\/ban/{split($2,a," "); print a[1]}' "$OUT")
  cpu=$(awk '/minus baseline/{for(i=1;i<=NF;i++) if($i=="/") print $(i+1)}' "$OUT")
  cpu1k=$(awk -v c="$cpu" -v n="$N" 'BEGIN{printf "%.1f", 1000*c/n}')
  printf '%-8s %-9s %-9s %-9s %-8s\n' "$N" "$wall" "$msban" "$cpu" "$cpu1k"
done
wait_stopped

echo
echo "Flat ms/ban & CPU/1k across N  -> constant per-op overhead (remoc / JSON / ctx)."
echo "Rising with N                  -> cache re-reading the growing set (superlinear)."
