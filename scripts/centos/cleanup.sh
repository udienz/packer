#!/bin/sh

yum -y remove kernel-headers kernel-devel gcc
yum -y clean all

# Remove Virtualbox specific files
rm -rf /usr/src/vboxguest* /usr/src/virtualbox-ose-guest*
rm -rf *.iso *.iso.? /tmp/vbox /home/vagrant/.vbox_version

# Cleanup log files
find /var/log -type f | while read f; do echo -ne '' > $f; done;

if grep -q -i "release 6" /etc/redhat-release ; then
    rm -f /etc/udev/rules.d/70-persistent-net.rules
    mkdir /etc/udev/rules.d/70-persistent-net.rules
    rm /lib/udev/rules.d/75-persistent-net-generator.rules
fi
rm -rf /dev/.udev/
if [ -f /etc/sysconfig/network-scripts/ifcfg-eth0 ] ; then
    sed -i "/^HWADDR/d" /etc/sysconfig/network-scripts/ifcfg-eth0
    sed -i "/^UUID/d" /etc/sysconfig/network-scripts/ifcfg-eth0
fi

# new-style network device naming for centos7
if grep -q -i "release 7" /etc/redhat-release ; then
  # radio off & remove all interface configration
  nmcli radio all off
  /bin/systemctl stop NetworkManager.service
  for ifcfg in `ls /etc/sysconfig/network-scripts/ifcfg-* |grep -v ifcfg-lo` ; do
    rm -f $ifcfg
  done
  rm -rf /var/lib/NetworkManager/*

  echo "==> Setup /etc/rc.d/rc.local for CentOS7"
  cat <<_EOF_ | cat >> /etc/rc.d/rc.local

#BOXCUTTER-BEGIN
LANG=C


# add gateway interface connection.
gwdev=\`nmcli dev | grep ethernet | egrep -v 'unmanaged' | head -n 1 | awk '{print \$1}'\`
if [ "\$gwdev" != "" ]; then
  nmcli c add type eth ifname \$gwdev con-name \$gwdev
fi

sed -i -e "/^#BOXCUTTER-BEGIN/,/^#BOXCUTTER-END/{s/^/# /}" /etc/rc.d/rc.local
chmod -x /etc/rc.d/rc.local
#BOXCUTTER-END
_EOF_
  chmod +x /etc/rc.d/rc.local
fi

echo "==> Cleaning up yum cache of metadata and packages to save space"
yum -y clean all

echo "==> Removing temporary files used to build box"
rm -rf /tmp/*
