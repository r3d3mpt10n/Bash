#!/bin/bash

## This script is to automate regular server backups. Eventually this backup will point to a software RAID group. For now, copies may need to be kept online. Also need to add Web Directory backups!!


readonly MYVAR=$('Echo MyVar')
readonly DATE=$(date +"%d-%m-%Y-%T")
readonly BDIR="/media/Storage/Server.Backup/home_backups"
#readonly BDIR="/home/shep/Documents/backups/"
#readonly TDIR="/home/shep/Documents/Coding/"
readonly DIR="/home/shep"
readonly BFILE="$BDIR/Home.backup.$DATE.tar.bz2"

readonly webDir="/var/www/*"
EXISTS=0


checkOS(){
if [ $(uname) == "Darwin" ]; then
    home="Users"
else
    home="home"
fi
checkDir
}

# Check the Backup directory is mounted and available.
checkDir(){
if [ -d $DIR ] && [ -d $BDIR ]; then
    EXISTS=true
    backup
else
    EXISTS=false
    echo $EXISTS
exit
fi
}

# Begin Backup.
backup(){
    echo "Creating a backup. But you still haven't added your web directory!"
    tar -jcvf $BFILE $DIR
removeOld
}

# Remove old backups.
removeOld(){
    find $BDIR -type f -mtime +30 \
    -exec sh -c 'test $(date +%a -r "$1") = Mon || echo rm "$1"' -- {} \;
    
}

checkOS
