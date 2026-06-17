#!/bin/sh

echo ""
echo "=== Without NFT plugin ==="
echo ""

echo "./method-a-trigger.sh ./test-without-plugin.jsonnet 5000 log.dropbear ..."
./method-a-trigger.sh ./test-without-plugin.jsonnet 5000 log.dropbear

echo ""
sleep 5

echo "./method-b-stream.sh ./bench-inline.jsonnet 20000 ..."
./method-b-stream.sh ./bench-inline.jsonnet 20000

echo "=== With NFT plugin ==="

./method-a-trigger.sh ./test-with-nftables-plugin.jsonnet 5000 log.dropbear
./method-b-stream.sh ./bench-plugin.jsonnet 20000
