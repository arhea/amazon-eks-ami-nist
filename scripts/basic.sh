#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

# wait for cloud-init to finish
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 5; done

# upgrade the operating system
yum update -y && yum autoremove -y

# enable the epel release
amazon-linux-extras install epel -y

reboot
