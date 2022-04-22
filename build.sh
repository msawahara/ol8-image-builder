#!/bin/bash

cd "$(dirname "$0")"

if [ "$EUID" -ne 0 ]; then
  echo "please run as root."
  exit 1
fi

docker build -t ol8-image-builder .
docker run --rm --privileged -it -v /dev:/dev -v /sys:/sys -v /proc:/proc --mount type=bind,src="$(pwd)/data",dst=/root/data ol8-image-builder
