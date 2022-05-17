#!/bin/sh

set -e

KERNEL_SRC=$(echo /usr/src/linux-*)
LATEST_KERNEL=${KERNEL_SRC##*-}
RUNNING_KERNEL=$(uname -r)

SLACKBUILD_DIR="/home/justin/Projects/slackbuilds"

check() {
    if [ "$RUNNING_KERNEL" != "$LATEST_KERNEL" ]; then
	echo "$RUNNING_KERNEL doesn't match $LATEST_KERNEL"
	return 1
    else
	echo "$RUNNING_KERNEL matches $LATEST_KERNEL"
	return 0
    fi
}

update_init() {
    if [ -x /usr/share/mkinitrd/mkinitrd_command_generator.sh ]; then
	/usr/share/mkinitrd/mkinitrd_command_generator.sh -k "$LATEST_KERNEL" | bash
    else
	echo "Error: cannot runt mkinitrd_command_generator.sh"
	exit 1
    fi
}

update_grub() {
    if [ -x /usr/sbin/grub-mkconfig ]; then
	/usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg
    else
	echo "Error: cannot source /usr/sbin/grub-mkconfig"
	exit 1
    fi
}

update_nvidia() {
    if [ -x "$SLACKBUILD_DIR/nvidia-kernel/nvidia-kernel.SlackBuild" ]; then
	cd $SLACKBUILD_DIR/nvidia-kernel

	source $PWD/nvidia-kernel.info
	if [ ! -e $PWD/NVIDIA-Linux-x86_64-$VERSION.run ]; then
	    wget $DOWNLOAD_x86_64
	fi

	rm -rf $PWD/build
	mkdir -p $PWD/build

	export OUTPUT="$PWD/build"
	export KERNEL="$LATEST_KERNEL"
	./nvidia-kernel.SlackBuild

	upgradepkg --install-new \
	    $PWD/build/nvidia-kernel-$VERSION_$KERNEL_x86_64-1_SBo.tgz
    else
	echo "Error: Cannot find nvidia.SlackBuild"
	exit 1
    fi
}

if check; then
    exit 0
else
    update_init && update_grub && update_nvidia
fi
exit 0
