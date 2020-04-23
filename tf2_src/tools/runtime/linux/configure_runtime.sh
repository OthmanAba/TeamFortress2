#! /bin/bash

echo "Unpacking the Steam Runtime for your build environment"

DIRNAME="$( dirname $( readlink -f "$0" ) )"

if [[ $# != 3 ]]; then
    echo "Usage: $0 chroot_name chroot_tarball personality (linux32|linux)"
    exit 1
fi

if [ $EUID -ne 0 ]; then
    echo "$0 must be running as root"
    exit 1
fi

cd $DIRNAME
CHROOT_NAME=$1
TARBALL=$2
PERSONALITY=$3

echo Unmounting existing chroot...
while $( mount | grep schroot/mount | grep -q $CHROOT_NAME ); do
	mount | grep schroot/mount | grep $CHROOT_NAME | awk '{print $3}' | xargs umount
done

echo Unpacking runtime $2...
tar xaf $2.tar.xz
touch $2/timestamp

echo Configuring schroot at $DIRNAME/$TARBALL
cat << EOF > /etc/schroot/chroot.d/$CHROOT_NAME.conf
[$CHROOT_NAME]
description=Steam Runtime
directory=$DIRNAME/$TARBALL
personality=$PERSONALITY
groups=sudo
root-groups=sudo
preserve-environment=true
type=directory
setup.fstab=mount$CHROOT_NAME
EOF

cat << EOF > /etc/schroot/mount$CHROOT_NAME
# fstab: static file system information for chroots.
# Note that the mount point will be prefixed by the chroot path
# (CHROOT_PATH)
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
proc           /proc           none    rw,bind         0       0
sys            /sys            none    rw,bind         0       0
dev            /dev            none    rw,bind         0       0
dev/pts        /dev/pts        none    rw,bind         0       0
home           /home           none    rw,bind         0       0
tmp            /tmp            none    rw,bind         0       0
# For PulseAudio and other desktop-related things
var/lib/dbus   /var/lib/dbus   none    rw,bind         0       0
run/shm        /run/shm        none    rw,bind         0       0
EOF

if [ -d /data ]; then
cat << EOF >> /etc/schroot/mount$CHROOT_NAME
data           /data           none    rw,bind         0       0
EOF
fi
