#!/bin/bash

check() {
  return 0
}

depends() {
  return
}

installkernel() {
  hostonly='' instmods overlay
}

install() {
  inst_multiple grep cut lsmod modprobe

  inst_hook cleanup 99 "$moddir/tmpfs-overlay.sh"
}
