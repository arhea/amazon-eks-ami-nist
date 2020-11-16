#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

tmpfs_and_mount() {
  FOLDER_PATH=$1

  mkdir -p ${FOLDER_PATH}
  echo "tmpfs ${FOLDER_PATH} tmpfs mode=1777,strictatime,noexec,nodev,nosuid 0 0" >> /etc/fstab
  mount -a
}

unload_module() {
  local fsname=$1

  if rmmod ${fsname}; then
    mkdir -p /etc/modprobe.d/
    echo "install ${fsname} /bin/true" > /etc/modprobe.d/${fsname}.conf
  fi
}

echo "1.1.1.1 - ensure mounting of cramfs filesystems is disabled"
unload_module cramfs

echo "1.1.1.2 - ensure mounting of hfs filesystems is disabled"
unload_module hfs

echo "1.1.1.3 - ensure mounting of hfsplus filesystems is disabled"
unload_module hfsplus

echo "1.1.1.4 - ensure mounting of squashfs filesystems is disabled"
unload_module squashfs

echo "1.1.1.5 - ensure mounting of udf filesystems is disabled"
unload_module udf

echo "1.1.2 - 1.1.5 - ensure /tmp is configured nodev,nosuid,noexec options set on  /tmp partition"
systemctl unmask tmp.mount && systemctl enable tmp.mount

cat > /etc/systemd/system/local-fs.target.wants/tmp.mount <<EOF
[Unit]
Description=Temporary Directory
Documentation=man:hier(7)
Documentation=http://www.freedesktop.org/wiki/Software/systemd/APIFileSystems
ConditionPathIsSymbolicLink=!/tmp
DefaultDependencies=no
Conflicts=umount.target
Before=local-fs.target umount.target

[Mount]
What=tmpfs
Where=/tmp
Type=tmpfs
Options=mode=1777,strictatime,noexec,nodev,nosuid

# Make 'systemctl enable tmp.mount' work:
[Install]
WantedBy=local-fs.target
EOF

systemctl daemon-reload && systemctl restart tmp.mount

echo "1.1.6 - ensure separate partition exists for /var"

echo "1.1.7 - 1.1.10 - ensure separate partition exists for /var/tmp nodev, nosuid, noexec option set"
tmpfs_and_mount /var/tmp

echo "1.1.11 - ensure separate partition exists for /var/log"

echo "1.1.12 - ensure separate partition exists for /var/log/audit"

echo "1.1.13 - ensure separate partition exists for /home"

echo "1.1.15 - ensure nodev,nosuid,noexec option set on /dev/shm"
echo "tmpfs  /dev/shm  tmpfs  defaults,nodev,nosuid,noexec  0 0" >> /etc/fstab
mount -a

echo "1.1.19 - disable automounting"
if systemctl is-enabled autofs; then
  systemctl disable autofs
fi

echo "1.2.1 - ensure package manager repositories are configured"
yum repolist

echo "1.2.2 - ensure GPG keys are configured"
rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n'

echo "1.2.3 - ensure gpgcheck is globally activated"
grep ^gpgcheck /etc/yum.conf
grep ^gpgcheck /etc/yum.repos.d/*

echo "1.3.1 - ensure AIDE is installed"
yum install -y aide
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

echo "1.3.2 - ensure filesystem integrity is regularly checked"
echo "0 5 * * * /usr/sbin/aide --check" > /etc/cron.d/aide

echo "1.4.1 - ensure permissions on bootloader config are configured"
chown root:root /boot/grub2/grub.cfg
chmod og-rwx /boot/grub2/grub.cfg

echo "1.4.2 - ensure authentication required for single user mode"
cat > /usr/lib/systemd/system/rescue.service <<EOF
[Unit]
Description=Rescue Shell
Documentation=man:sulogin(8)
DefaultDependencies=no
Conflicts=shutdown.target
After=sysinit.target plymouth-start.service
Before=shutdown.target

[Service]
Environment=HOME=/root
WorkingDirectory=/root
ExecStartPre=-/bin/plymouth quit
ExecStartPre=-/bin/echo -e 'Welcome to emergency mode! After logging in, type "journalctl -xb" to view\\nsystem logs, "systemctl reboot" to reboot, "systemctl default" or ^D to\\nboot into default mode.'
ExecStart=-/bin/sh -c "/usr/sbin/sulogin; /usr/bin/systemctl --fail --no-block default"
Type=idle
StandardInput=tty-force
StandardOutput=inherit
StandardError=inherit
KillMode=process
IgnoreSIGPIPE=no
SendSIGHUP=yes
EOF

cat > /usr/lib/systemd/system/emergency.service <<EOF
[Unit]
Description=Emergency Shell
Documentation=man:sulogin(8)
DefaultDependencies=no
Conflicts=shutdown.target
Conflicts=rescue.service
Before=shutdown.target

[Service]
Environment=HOME=/root
WorkingDirectory=/root
ExecStartPre=-/bin/plymouth quit
ExecStartPre=-/bin/echo -e 'Welcome to emergency mode! After logging in, type "journalctl -xb" to view\\nsystem logs, "systemctl reboot" to reboot, "systemctl default" or ^D to\\ntry again to boot into default mode.'
ExecStart=-/bin/sh -c "/usr/sbin/sulogin; /usr/bin/systemctl --fail --no-block default"
Type=idle
StandardInput=tty-force
StandardOutput=inherit
StandardError=inherit
KillMode=process
IgnoreSIGPIPE=no
SendSIGHUP=yes
EOF

systemctl daemon-reload

echo "1.5.1 - ensure core dumps are restricted"
echo "* hard core 0" > /etc/security/limits.d/cis.conf
echo "fs.suid_dumpable = 0" >> /etc/sysctl.d/cis.conf

echo "1.5.2 - ensure address space layout randomization (ASLR) is enabled"
echo "kernel.randomize_va_space = 2" >> /etc/sysctl.d/cis.conf

echo "1.5.3 - ensure prelink is disabled"
if rpm -q prelink; then
  prelink -ua && yum remove -y prelink
fi

echo "1.7.1.1 - ensure message of the day is configured properly"
rm -f /etc/cron.d/update-motd
cat > /etc/motd <<EOF
You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.

By using this IS (which includes any device attached to this IS), you consent to the following conditions:
-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.
-At any time, the USG may inspect and seize data stored on this IS.
-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.
-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.
-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.
EOF

echo "1.7.1.2 - ensure local login warning banner is configured properly"
cat > /etc/issue <<EOF
You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.

By using this IS (which includes any device attached to this IS), you consent to the following conditions:
-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.
-At any time, the USG may inspect and seize data stored on this IS.
-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.
-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.
-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.
EOF

echo "1.7.1.3 - ensure remote login warning banner is configured properly"
cat > /etc/issue.net <<EOF
You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.

By using this IS (which includes any device attached to this IS), you consent to the following conditions:
-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.
-At any time, the USG may inspect and seize data stored on this IS.
-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.
-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.
-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.
EOF

echo "1.7.1.4 - ensure permissions on /etc/motd are configured"
chown root:root /etc/motd
chmod 644 /etc/motd

echo "1.7.1.5 - ensure permissions on /etc/issue are configured"
chown root:root /etc/issue
chmod 644 /etc/issue

echo "1.7.1.6 - ensure permissions on /etc/issue.net are configured"
chown root:root /etc/issue.net
chmod 644 /etc/issue.net

echo "1.8 - ensure updates, patches, and additional security software are installed"
yum update -y

echo "2.1.2 - ensure X Window System is not installed"
if rpm -q xorg-x11*; then
  yum remove -y xorg-x11*
fi

echo "2.1.3 - ensure Avahi Server is not enabled"
if systemctl is-enabled avahi-daemon; then
  systemctl disable avahi-daemon
fi

echo "2.1.4 - ensure CUPS is not enabled"
if systemctl is-enabled cups; then
  systemctl disable cups
fi

echo "2.1.5 - ensure DHCP Server is not enabled"
if systemctl is-enabled dhcpd; then
  systemctl disable dhcpd
fi

echo "2.1.6 - ensure LDAP Server is not enabled"
if systemctl is-enabled slapd; then
  systemctl disable slapd
fi

echo "2.1.7 - ensure NFS and RPC are not enabled"
if systemctl is-enabled nfs; then
  systemctl disable nfs
fi

if systemctl is-enabled nfs-server; then
  systemctl disable nfs-server
fi

if systemctl is-enabled rpcbind; then
  systemctl disable rpcbind
fi

echo "2.1.8 - ensure DNS Server is not enabled"
if systemctl is-enabled named; then
  systemctl disable named
fi

echo "2.1.9 - ensure FTP Server is not enabled"
if systemctl is-enabled vsftpd; then
  systemctl disable vsftpd
fi

echo "2.1.10 - ensure HTTP Server is not enabled"
if systemctl is-enabled httpd; then
  systemctl disable httpd
fi

echo "2.1.11 - ensure IMAP and POP3 Server is not enabled"
if systemctl is-enabled dovecot; then
  systemctl disable dovecot
fi

echo "2.1.12 - ensure Samba is not enabled"
if systemctl is-enabled smb; then
  systemctl disable smb
fi

echo "2.1.13 - ensure HTTP Proxy Server is not enabled"
if systemctl is-enabled squid; then
  systemctl disable squid
fi

echo "2.1.14 - ensure SNMP Server is not enabled"
if systemctl is-enabled snmpd; then
  systemctl disable snmpd
fi

echo "2.1.15 - ensure mail transfer agent is configured for local-only mode"
netstat -an | grep LIST | grep ":25[[:space:]]"

echo "2.1.16 - ensure NIS Server is not enabled"
if systemctl is-enabled ypserv; then
  systemctl disable ypserv
fi

echo "2.1.17 - ensure rsh Server is not enabled"
if systemctl is-enabled rsh.socket; then
  systemctl disable rsh.socket
fi

if systemctl is-enabled rlogin.socket; then
  systemctl disable rlogin.socket
fi

if systemctl is-enabled rexec.socket; then
  systemctl disable rexec.socket
fi

echo "2.1.18 - ensure telnet Server is not enabled"
if systemctl is-enabled telnet.socket; then
  systemctl disable telnet.socket
fi

echo "2.1.19 - ensure tftp Server is not enabled"
if systemctl is-enabled tftp.socket; then
  systemctl disable tftp.socket
fi

echo "2.1.20 - ensure rsync service is not enabled"
if systemctl is-enabled rsyncd; then
  systemctl disable rsyncd
fi

echo "2.1.21 - ensure talk service is not enabled"
if systemctl is-enabled ntalk; then
  systemctl disable ntalk
fi

echo "2.2.1 - ensure NIS Client is not installed"
if rpm -q ypbind; then
  yum remove -y ypbind
fi

echo "2.2.2 - ensure rsh client is not installed"
if rpm -q rsh; then
  yum remove -y rsh
fi

echo "2.2.3 - ensure talk client is not installed"
if rpm -q talk; then
  yum remove -y talk
fi

echo "2.2.3 - ensure telnet client is not installed"
if rpm -q telnet; then
  yum remove -y telnet
fi

echo "2.2.4 - ensure LDAP client is not installed"
if rpm -q openldap-clients; then
  yum remove -y openldap-clients
fi

echo "3.1.1 - ensure IP forwarding is disabled"
echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.d/cis.conf
echo "net.ipv6.conf.all.forwarding = 0" >> /etc/sysctl.d/cis.conf

echo "3.1.2 - ensure packet redirect sending is disabled"
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.d/cis.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.d/cis.conf

echo "3.3.1 - ensure TCP Wrappers is installed"
yum install -y tcp_wrappers

echo "3.4.1 - ensure DCCP is disabled"
unload_module dccp

echo "3.4.2 - ensure SCTP is disabled"
unload_module sctp

echo "3.4.3 - ensure RDS is disabled"
unload_module rds

echo "3.4.4 - ensure TIPC is disabled"
unload_module tipc
