#!/usr/bin/env bash
set -eo pipefail

TEST_DIR="/tmp/snap_speed_test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "=== Testing 'snap download snap-store' speed ==="
echo "Timestamp: $(date -u)"

# Ensure snapd service is active
systemctl start snapd.socket snapd.service || true
sleep 1

START=$(date +%s%N)
# Run snap download snap-store with 30s timeout
set +e
timeout 30 snap download snap-store > download_output.log 2>&1
EXIT_CODE=$?
set -e
END=$(date +%s%N)

# Calculate duration in seconds (floating point)
ELAPSED_NS=$((END - START))
DURATION=$(awk -v ns="$ELAPSED_NS" 'BEGIN { printf "%.3f", ns / 1000000000 }')

# Find downloaded files/partials
BYTES=$(find "$TEST_DIR" -type f \( -name "*.snap*" -o -name "*.assert*" \) -exec stat -c %s {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')

echo "Exit code: $EXIT_CODE"
echo "Elapsed time: ${DURATION}s"
echo "Bytes downloaded: $BYTES bytes ($((BYTES / 1024)) KB, $(awk -v b="$BYTES" 'BEGIN { printf "%.2f", b / (1024*1024) }') MB)"

SPEED_MBPS=$(awk -v b="$BYTES" -v d="$DURATION" 'BEGIN { if (d > 0) printf "%.3f", (b / (1024*1024)) / d; else print "0" }')
SPEED_KBPS=$(awk -v b="$BYTES" -v d="$DURATION" 'BEGIN { if (d > 0) printf "%.1f", (b / 1024) / d; else print "0" }')

echo "Calculated Average Speed: ${SPEED_MBPS} MB/s (${SPEED_KBPS} KB/s)"
echo "--- Download Log Output ---"
cat download_output.log
echo "--- Directory Contents ---"
ls -lh "$TEST_DIR"
