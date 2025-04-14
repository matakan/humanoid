#!/bin/bash

s3=$(echo "$1" | cut -d"|" -f1)
mount_point=$(echo "$1" | cut -d"|" -f2)
bucket_name=$(echo "$s3" | cut -d"/" -f3)
bucket_path=$(echo "$s3" | cut -d":" -f2 | sed '/^\/\// s///')

REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
echo $REGION

cat <<- EOF >> ~/.config/rclone/rclone.conf
[$bucket_name]
type = s3
provider = AWS
env_auth = true
region = $REGION

EOF

if [ ! -f "${mount_point}" ]; then
    mkdir -p ${mount_point}
fi

rclone mount "${bucket_name}":"${bucket_path}" "${mount_point}" \
          --vfs-cache-mode full \
          --cache-dir /tmp/cache \
          --vfs-cache-max-size 2.5T \
          --vfs-cache-min-free-space 1.1T \
          --vfs-cache-max-age 10m \
          --vfs-write-back 2s \
          --vfs-cache-poll-interval 2s \
          --daemon \
          --bwlimit 1G \
          --s3-chunk-size 500M \
          --s3-no-check-bucket \
          --rc \
          --rc-addr :0 \
          --rc-no-auth \
          --log-file /tmp/rclone.log \
          --log-level DEBUG \
          --allow-other \
          --allow-non-empty
