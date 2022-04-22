#!/bin/bash

NEWROOT="/sysroot"

function init_overlay () {
  MODULE_NAME="overlay"

  lsmod | cut -d' ' -f1 | grep "^${MODULE_NAME}\$" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    modprobe ${MODULE_NAME}
  fi

  mount -t tmpfs tmpfs ${NEWROOT}/ramdisk
}

function do_overlay () {
  DIR=$1
  TMPDIR=${NEWROOT}/ramdisk/overlay
  mkdir -p ${TMPDIR}${DIR}/{upper,work}
  mount -t overlay -o lowerdir=${DIR},upperdir=${TMPDIR}${DIR}/upper,workdir=${TMPDIR}${DIR}/work overlay ${DIR}
}

init_overlay
do_overlay ${NEWROOT}/etc
do_overlay ${NEWROOT}/var
