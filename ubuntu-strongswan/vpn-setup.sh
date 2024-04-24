#!/bin/bash

BGP_ASN="65000"
CGW_CIDR="192.168.0.0/16"
CGW_PRIVATE_IP="192.168.0.1"

CGW_PUBLIC_IP="1.1.1.1"
VGW_PUBLIC_IP_1="2.2.2.2"
VGW_PUBLIC_IP_2="3.3.3.3"

CGW_INSIDE_IP_1="169.254.1.34"
VGW_INSIDE_IP_1="169.254.1.33"
CGW_INSIDE_IP_2="169.254.2.18"
VGW_INSIDE_IP_2="169.254.2.17"

PRE_SHARED_KEY_1=""
PRE_SHARED_KEY_2=""

if [ $CGW_PUBLIC_IP == "1.1.1.1" ]
then
    echo PLEASE PROVIDE YOUR OWN CONFIG VALUE
    exit 1
else
    sed -i.bak "s@CGW_PUBLIC_IP@$CGW_PUBLIC_IP@g" ipsec/ipsec.conf ipsec/ipsec.secrets
    sed -i.bak "s@VGW_PUBLIC_IP_1@$VGW_PUBLIC_IP_1@g" ipsec/ipsec.conf ipsec/ipsec.secrets
    sed -i.bak "s@VGW_PUBLIC_IP_2@$VGW_PUBLIC_IP_2@g" ipsec/ipsec.conf ipsec/ipsec.secrets
    sed -i.bak "s@PRE_SHARED_KEY_1@$PRE_SHARED_KEY_1@g" ipsec/ipsec.secrets
    sed -i.bak "s@PRE_SHARED_KEY_2@$PRE_SHARED_KEY_2@g" ipsec/ipsec.secrets

    sed -i.bak "s@CGW_INSIDE_IP_1@$CGW_INSIDE_IP_1@g" strongswan/ipsec-vti.sh
    sed -i.bak "s@CGW_INSIDE_IP_2@$CGW_INSIDE_IP_2@g" strongswan/ipsec-vti.sh
    sed -i.bak "s@VGW_INSIDE_IP_1@$VGW_INSIDE_IP_1@g" quagga/bgpd.conf strongswan/ipsec-vti.sh
    sed -i.bak "s@VGW_INSIDE_IP_2@$VGW_INSIDE_IP_2@g" quagga/bgpd.conf strongswan/ipsec-vti.sh

    sed -i.bak "s@BGP_ASN@$BGP_ASN@g" quagga/bgpd.conf
    sed -i.bak "s@CGW_PRIVATE_IP@$CGW_PRIVATE_IP@g" quagga/bgpd.conf quagga/zebra.conf
    sed -i.bak "s@CGW_CIDR@$CGW_CIDR@g" quagga/bgpd.conf
fi

# Install StrongSwan and Quagga
apt update
apt install -y strongswan quagga


# Create .bak in case of overwriting existing configuration.
cp /etc/strongswan.d/charon.conf /etc/strongswan.d/charon.conf.bak || echo
cp /etc/strongswan.d/ipsec-vti.sh /etc/strongswan.d/ipsec-vti.sh.bak || echo
cp /etc/ipsec.conf /etc/ipsec.conf.bak || echo
cp /etc/ipsec.secrets /etc/ipsec.secrets.bak || echo
cp /etc/quagga/bgpd.conf /etc/quagga/bgpd.conf.bak || echo
cp /etc/quagga/vtysh.conf /etc/quagga/vtysh.conf.bak || echo
cp /etc/quagga/zebra.conf /etc/quagga/zebra.conf.bak || echo


# StrongSwan setup
echo Copying charon.conf
chmod 644 strongswan/charon.conf
cp stongswan/charon.conf /etc/strongswan.d/charon.conf

echo Copying ipsec-vti.sh
chmod 700 strongswan/ipsec-vti.sh
cp strongswan/ipsec-vti.sh /etc/strongswan.d/ipsec-vti.sh


# ipsec setup
echo Copying ipsec.conf, ipsec.secrets
chmod 600 ipsec/ipsec.*
cp ipsec/ipsec.* /etc/


# BGP setup
echo Copying bgpd.conf, vtysh.conf, zebra.conf
chmod 600 quagga/*.conf
chown quagga:quagga quagga/*.conf
chown quagga:quaggavty quagga/vtysh.conf
cp quagga/*.conf /etc/quagga/


# BGP log setup
echo Creating log directory at /var/log/quagga/
mkdir -p /var/log/quagga
touch /var/log/quagga/bgpd.log /var/log/quagga/zebra.log

chmod 600 /var/log/quagga/*.log
chown quagga:quagga /var/log/quagga/*.log

echo Starting daemons
systemctl enable --now ipsec bgpd zebra
systemctl restart ipsec
systemctl is-active ipsec bgpd zebra
echo Finished to setup VPN
