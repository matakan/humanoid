#!/bin/bash

# Path to your rclone log file
LOG_FILE="/tmp/rclone.log"

# Check if bucket name is provided
if [ -z "$1" ]; then
    echo "Error: Bucket name required. Usage: $0 <bucket_name>" >&2
    exit 1
fi

BUCKET_NAME="$1"

# Simple search pattern focusing on the bucket name
SEARCH_PATTERN="S3 bucket ${BUCKET_NAME}"

# Number of consecutive matches needed to confirm stability
REQUIRED_STABLE_COUNT=5

# Sleep briefly to allow rclone to start logging
sleep 5

echo "Monitoring rclone log for pattern: '${SEARCH_PATTERN}' and waiting for stable conditions ('in use 0', 'to upload 0', 'uploading 0')..."

STABLE_COUNT=0

# Keep reading the log file
tail -n 0 -F "$LOG_FILE" | while read -r line; do
    # Check if the line contains the pattern identifying the bucket
    if echo "$line" | grep -q "${SEARCH_PATTERN}"; then
        # Check if the line ALSO contains all three stability conditions
        if echo "$line" | grep -q "in use 0" && \
           echo "$line" | grep -q "to upload 0" && \
           echo "$line" | grep -q "uploading 0"; then
            STABLE_COUNT=$((STABLE_COUNT + 1))
            echo "Stable conditions met ($STABLE_COUNT/$REQUIRED_STABLE_COUNT) for bucket '${BUCKET_NAME}'. Log: $line"
            if [ $STABLE_COUNT -ge $REQUIRED_STABLE_COUNT ]; then
                echo "Mount related to bucket '${BUCKET_NAME}' appears stable. Exiting wait script."
                # Kill tail to exit the loop/script
                kill $! 2>/dev/null || true
                break
            fi
        else
            # Reset counter if conditions are not met on a relevant log line for this bucket
            if [ $STABLE_COUNT -gt 0 ]; then
                 echo "Conditions no longer met for bucket '${BUCKET_NAME}', resetting stability counter. Log: $line"
            fi
            STABLE_COUNT=0
        fi
    fi
done

echo "Wait script finished for bucket '${BUCKET_NAME}'"
