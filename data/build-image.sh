#!/bin/bash

IMAGE_FILE="os.img"
IMAGE_SIZE=8G
ROOT_PASSWD=${ROOT_PASSWD:-"password"}

cd "$(dirname "$0")"

LOOPDEV=$(losetup -f)

if [ ! -e ${IMAGE_FILE} ]; then
  truncate -s ${IMAGE_SIZE} "${IMAGE_FILE}"
  echo "o n p 1 _ _ w" | tr -d "_" | tr " " "\n" | fdisk "${IMAGE_FILE}"
  losetup --partscan ${LOOPDEV} "${IMAGE_FILE}"
  mkfs.ext4 -L sysroot ${LOOPDEV}p1
else
  losetup --partscan ${LOOPDEV} "${IMAGE_FILE}"
fi

mount ${LOOPDEV}p1 /mnt

mkdir -p /mnt/proc
mount -o bind /proc /mnt/proc

# install packages
dnf --installroot=/mnt -y groupinstall "Minimal Install"
dnf --installroot=/mnt -y install kernel-uek iscsi-initiator-utils

# enable ramdisk
chroot /mnt systemctl enable tmp.mount

# install tmpfs-overlay module
mkdir -p /mnt/ramdisk
mkdir -p /mnt/usr/lib/dracut/modules.d/92tmpfs-overlay
cp tmpfs-overlay/{module-setup.sh,tmpfs-overlay.sh} /mnt/usr/lib/dracut/modules.d/92tmpfs-overlay
chmod 755 /mnt/usr/lib/dracut/modules.d/92tmpfs-overlay/{module-setup.sh,tmpfs-overlay.sh}

# generate boot files
KERNEL_VER=$(dnf --installroot /mnt list --installed kernel-uek | grep "^kernel-uek\." | sed -E 's/\s+/\t/g' | cut -f 2)
KERNEL_ARCH=$(dnf --installroot /mnt list --installed kernel-uek | grep "^kernel-uek\." | sed -E 's/\s+/\t/g' | cut -f 1 | cut -d. -f 2)

chroot /mnt dracut --force --no-hostonly --add "network iscsi nfs" --add-driver "igb nfs nfsv4" /boot/initramfs-pxeboot.img ${KERNEL_VER}.${KERNEL_ARCH}
(cd /mnt/boot; ln -sf vmlinuz-${KERNEL_VER}.${KERNEL_ARCH} vmlinuz)

cp /mnt/boot/initramfs-pxeboot.img .
cp /mnt/boot/vmlinuz .

# set passwd
echo "${ROOT_PASSWD}" | chroot /mnt passwd --stdin root

# misc setup
sed -i -e 's/^SELINUX=.*$/SELINUX=disabled/g' /mnt/etc/selinux/config

# check
df -h /mnt

# finish
umount /mnt/proc
umount -R /mnt
losetup -d ${LOOPDEV}
