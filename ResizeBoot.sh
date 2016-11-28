#!/bin/bash

echo "Enter the location of the new drive (eg sdb,sdc,sdd):"
read NEWDRIVE

## Backup important things
function backup(){
	cp /etc/fstab /root/backup-fstab
	tar -cvf /root/boot.tar.bz2 /boot
	if [ $? = 0 ]; then
		goldenFix
		echo $?
	else
   		echo "Script failed with code $?" >> /root/ResizeBoot.log
		exit
	fi
}

## Function says it all.
function goldenFix(){
	OLDUUID=$(blkid | grep `mount | grep "/boot " | awk '{ print $1}'` | awk '{ print $2 }')
	sed -i '/boot/s/^/#/g' /etc/fstab
	mkdir /boot-new
	cp -r -a /boot/* /boot-new
	if [ -d /boot-new ]; then
		echo -e "o\nn\np\n1\n\n+500M\nw" | fdisk /dev/$NEWDRIVE
		partprobe
		sleep 30
		mkfs.ext4 /dev/`echo $NEWDRIVE`1
		umount /boot
	else
		echo "Script failed with code $?" >> /root/ResizeBoot.log
		exit
	fi
	if [ ! -e /boot/grub2/grub.cfg ]; then
		mount /dev/`echo $NEWDRIVE`1 /boot
		cp -r -a /boot-new/* /boot
		DEVUUID=`blkid | grep /dev/`echo $NEWDRIVE`1 | awk '{ print $2 }'`
		echo "$DEVUUID  /boot     ext4    defaults   0 0" >> /etc/fstab
		#sed -i "/^`echo $OLDUUID`/d" /etc/fstab
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
		#grub2-mkconfig -o /boot/grub2/grub.cfg
		echo "Nailed it! This server should be ok to be rebooted." 
		
	else
		echo "Script failed with code $?" >> /root/ResizeBoot.log
		exit
	fi
		
}

if [ $NEWDRIVE == sd[a-z] ]; then
	backup
else
	echo "Please enter the drive in the format sd*. So sdb, sdd, sdc, etc"
	exit
fi
