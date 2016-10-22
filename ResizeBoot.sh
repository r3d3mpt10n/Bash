#!/bin/bash

## Backup important things
function backup(){
	cp /etc/fstab /root/backup-fstab
	tar -cjvf /root/boot.tar.bz2 /boot
	if [ $? = 0 ]; then
		goldenFix
	else
		exit 3
		echo "Script failed with code $?" >> /root/ResizeBoot.log
	fi
}

## Function says it all.
function goldenFix(){
	OLDUUID=blkid | grep `mount | grep "/boot " | awk '{ print $1}'` | awk '{ print $2 }'
	mkdir /boot-new
	cp /boot/* /boot-new
	if [ -d /boot-new ]; then
		echo -e "o\nn\np\n1\n\n+500M\nw" | fdisk /dev/vdb
		partprobe
		sleep 10
		mkfs.ext4 /dev/vdb1
		umount /boot
	else
		exit 1
		echo "Script failed with code $?" >> /root/ResizeBoot.log
	fi
	if [ ! -e /boot/grub2/grub.cfg ]; then
		mount /dev/vdb1 /boot
		cp -r -a /boot-new/* /boot
		DEVUUID=`blkid | grep /dev/vdb1 | awk '{ print$2 }'`
		echo "$DEVUUID  /boot     ext4    defaults   0 0" >> /etc/fstab
		sed -i '/$OLDUUID/s/^/#/g' /etc/fstab
		checkIt
	else
		exit 2
		echo "Script failed with code $?" >> /root/ResizeBoot.log
	fi
}

## Few check safes before rebooting
function checkIt(){
	mount -a 2>/root/ResizeBoot-fstab.log
	if [ $? -eq 0 ]; then
		grub2-mkconfig -o /boot/grub2/grub.cfg
		echo "Nailed it! This server should be ok to be rebooted."
		
	else
		echo "Well, didn't quite nail it. Check fstab. If not, nuke and pave, it's the only way! (It's not. You broke fstab.)"
		exit 4
		echo "Script failed with code $?" >> /root/ResizeBoot.log
	fi
		
}

backup
