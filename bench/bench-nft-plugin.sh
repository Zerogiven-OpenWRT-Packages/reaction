#!/bin/sh

SOCK=/run/reaction/reaction.sock

# Block until the reaction daemon has fully exited, then clear any stale control
# socket so the next run's "already running?" precheck passes. 30s cap.
wait_stopped() {
  i=0
  while pidof reaction >/dev/null 2>&1; do
    i=$((i + 1))
    [ "$i" -gt 30 ] && { echo "warning: reaction still running after 30s" >&2; break; }
    sleep 1
  done
  rm -f "$SOCK"   # safe: no daemon is running, so the socket is stale
}

echo ""
echo "=== Without NFT plugin ==="
echo ""

./method-a-trigger.sh ./test-without-plugin.jsonnet 5000 log.dropbear
wait_stopped
./method-b-stream.sh ./bench-inline.jsonnet 20000
wait_stopped

echo ""
echo "=== With NFT plugin ==="
echo ""

./method-a-trigger.sh ./test-with-nftables-plugin.jsonnet 5000 log.dropbear
wait_stopped
./method-b-stream.sh ./bench-plugin.jsonnet 20000
wait_stopped

echo ""
