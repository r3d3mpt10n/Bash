#!/usr/bin/env bash


if [[ $EUID -ne 0 ]]; then
  echo 'Must be run as root' 1>&2
  exit 1
fi


outWithTheOld(){
  mkdir /tmp/rhn_backup
  mv /etc/sysconfig/rhn /tmp/rhn_backup
}

inWithTheNew(){
  checkVersion
  echo subscription-manager clean
  echo subscription-manager unregister
  echo subscription-manager register --activation-key=$AK
}

checkVersion(){
  if grep '6' /etc/redhat-release;
  then VER=6
  elif grep '7' /etc/redhat-release;
  then VER=7
  fi
  pickYourKey
}

prepare(){
 echo yum install subscription-manager -y
 echo '172.29.7.39    bsgpp1cap01.bsg.local  bsgpp1cap01' >> /etc/hosts
 echo yum install http://bsgpp1cap01/pub/katello-ca-consumer-latest.noarch.rpm
 if [[ $? == 0 ]]; then
  echo 'Checks out, lets roll'
  inWithTheNew
 else
  echo 'Something went wrong. Exiting'
  exit
 fi
}

pickYourKey(){

if [[ $VER -eq 6 ]]; then AK=AK_INT_RHEL6;
elif [[ $VER -eq 7 ]]; then AK=AK_INT_RHEL7;
fi

}

main(){
  echo 'Creating Backup of RHN config'
  outWithTheOld
  echo 'Registering your system with RHSM'
  prepare
}

main
