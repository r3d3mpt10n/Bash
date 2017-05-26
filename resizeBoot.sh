#!/bin/bash

## Backup important things
function backup(){
	cp /etc/fstab /root/backup-fstab
	tar -cvf /root/boot.tar.bz2 /boot
	if [ $? = 0 ]; then
		echo "Backup of FSTAB All Good" >> /root/ResizeBoot.log
		goldenFix
		echo $?
	else
   		echo "Script failed with to make a Backup of fstab" >> /root/ResizeBoot.log
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
		mkfs.ext3 /dev/`echo $NEWDRIVE`1
		umount /boot
	else
		echo "Script failed with code $?" >> /root/ResizeBoot.log
		exit
	fi
	if [ ! -e /boot/grub2/grub.cfg ]; then
		mount /dev/`echo $NEWDRIVE`1 /boot
		cp -r -a /boot-new/* /boot
		DEVUUID=$(blkid | grep /dev/`echo $NEWDRIVE`1 | awk '{ print $2 }')
		echo "$DEVUUID  /boot     ext3    defaults   0 0" >> /etc/fstab
		echo "New /boot has been added to fstab - proceeding" >> /root/ResizeBoot.log
		#sed -i "/^`echo $OLDUUID`/d" /etc/fstab
		checkIt
	else
		exit 2
		echo "Script failed with to update fstab" >> /root/ResizeBoot.log
	fi
}

## Few check safes before rebooting
function checkIt(){
	mount -a 2>/root/ResizeBoot-fstab.log
	if [ $? -eq 0 ]; then
		if cat /boot/grub2/grub.cfg 2>/dev/null | grep -q "`cat /proc/cmdline | awk '{ print $1 }' | cut -f 2 -d =`"; then
			  ## GRUB 1 stuff goes here
				grub-install --recheck /dev/sda
		    if grub-install /dev/sda; then
					echo "Nailed it! This legacy server should be ok to be rebooted." >> /root/ResizeBoot.log
				 else
					echo "Script failed to update legacy GRUB - eww" >> /root/ResizeBoot.log
					exit
				 fi
		else
			if grub2-mkconfig -o /boot/grub2/grub.cfg; then
			 echo "Nailed it! This server should be ok to be rebooted." >> /root/ResizeBoot.log
	    else
		   echo "Script failed to upldate GRUB 2" >> /root/ResizeBoot.log
		   exit
		  fi
		fi
	fi

}
## This could be replaced by searching for the new unpartitioned drive.
echo "Enter the location of the new drive (eg sdb,sdc,sdd):"
read NEWDRIVE

if [ $NEWDRIVE == sd[a-z] ]; then
    backup
else
		echo "Enter the drive as sda, sdb, sdc"
		exit
fi
