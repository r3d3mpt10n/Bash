#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "Must be run as root" 
   exit 1
fi

install_packages(){
	yum install net-snmp net-snmp-utils net-snmp-libs net-snmp-devel -y
}

config_snmp_user(){
	#echo 'createUser svc_snmp MD5 "password" DES "password"' >> /var/net-snmp/snmpd.conf
	echo 'createUser svc_snmp MD5 "password" DES "password"' >> /var/lib/net-snmp/snmpd.conf
	echo 'rouser svc_snmp' >> /etc/snmp/snmpd.conf
}

enable_snmpd(){
	service snmpd start
}

snmp_firewall(){
	if [ -f /etc/sysconfig/iptables ]; then
	sed -i '/REJECT/i\
		A INPUT -p tcp -m tcp --dport 161 -j ACCEPT\
		A INPUT -p udp -m udp --dport 161 -j ACCEPT' /etc/sysconfig/iptables
	else
		firewall-cmd --add-service=snmp --permanent 
		firewall-cmd --reload
	fi
}


main(){
	echo "Installing packages" 
	install_packages
	echo "Configuring user"
	config_snmp_user
	echo "ensure snmpd starts on boot"
	enable_snmpd
	echo "Create firewall Rules"
	snmp_firewall
}

main
