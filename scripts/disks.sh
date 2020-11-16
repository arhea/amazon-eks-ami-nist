#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

migrate_and_mount_disk() {
  DISK_NAME=$1
  FOLDER_PATH=$2

  TEMP_PATH="/mnt${FOLDER_PATH}"
  OLD_PATH="${FOLDER_PATH}.old"

  echo "making temporary mount point for ${TEMP_PATH}"
  mkdir -p ${TEMP_PATH}

  echo "applying ext4 filesystem to ${DISK_NAME}"
  mkfs -t ext4 ${DISK_NAME}

  echo "mounting ${DISK_NAME} to ${TEMP_PATH}"
  mount ${DISK_NAME} ${TEMP_PATH}

  echo "migrating existing content to the temp location"
  cp -Rax ${FOLDER_PATH}/* ${TEMP_PATH}

  echo "migrate existing folder to old location"
  mv ${FOLDER_PATH} ${OLD_PATH}

  echo "unmounting ${DISK_NAME}"
  umount ${DISK_NAME}

  echo "recreate ${FOLDER_PATH}"
  mkdir -p ${FOLDER_PATH}

  echo "updating /etc/fstab with UUID of ${DISK_NAME} and ${FOLDER_PATH}"
  echo "UUID=$(blkid -s UUID -o value ${DISK_NAME}) ${FOLDER_PATH} ext4 defaults,nofail 0 1" >> /etc/fstab

  echo "mounting disk to system"
  mount -a
}

echo "ensure secondary disk is partitioned"
yum install -y parted
parted -a optimal -s /dev/nvme2n1 \
  mklabel gpt \
  mkpart var ext4 0% 20% \
  mkpart varlog ext4 20% 40% \
  mkpart varlogaudit ext4 40% 60% \
  mkpart home ext4 60% 70% \
  mkpart varlibdocker ext4 70% 100%

echo "ensure secondary disk is mounted to proper locations"
migrate_and_mount_disk /dev/nvme2n1p1 /var
migrate_and_mount_disk /dev/nvme2n1p2 /var/log
migrate_and_mount_disk /dev/nvme2n1p3 /var/log/audit
migrate_and_mount_disk /dev/nvme2n1p4 /home
migrate_and_mount_disk /dev/nvme2n1p5 /var/lib/docker
