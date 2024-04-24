#!/bin/bash

#@ /etc/strongswan/ipsec-vti.sh (Centos) or /etc/strongswan.d/ipsec-vti.sh (Ubuntu)

# AWS VPC Hardware VPN Strongswan updown Script

# Usage Instructions:
# Add "install_routes = no" to /etc/strongswan/strongswan.d/charon.conf or /etc/strongswan.d/charon.conf
# Add "install_virtual_ip = no" to /etc/strongswan/strongswan.d/charon.conf or /etc/strongswan.d/charon.conf
# For Ubuntu: Add "leftupdown=/etc/strongswan.d/ipsec-vti.sh" to /etc/ipsec.conf
# For RHEL/Centos: Add "leftupdown=/etc/strongswan/ipsec-vti.sh" to /etc/strongswan/ipsec.conf
# For RHEL/Centos 6 and below: git clone git://git.kernel.org/pub/scm/linux/kernel/git/shemminger/iproute2.git && cd iproute2 && make && cp ./ip/ip /usr/local/sbin/ip

# Adjust the below according to the Generic Gateway Configuration file provided to you by AWS.
# Sample: http://docs.aws.amazon.com/AmazonVPC/latest/NetworkAdminGuide/GenericConfig.html

IP=$(which ip)
IPTABLES=$(which iptables)

PLUTO_MARK_OUT_ARR=(${PLUTO_MARK_OUT//// })
PLUTO_MARK_IN_ARR=(${PLUTO_MARK_IN//// })
case "$PLUTO_CONNECTION" in
    Tunnel1)
    VTI_INTERFACE=vti1
    VTI_LOCALADDR=CGW_INSIDE_IP_1 # Tunnel1 CGW InsideIpAddress
    VTI_REMOTEADDR=VGW_INSIDE_IP_1 # Tunnel1 VGW InsideIpAddress
    ;;
    Tunnel2)
    VTI_INTERFACE=vti2
    VTI_LOCALADDR=CGW_INSIDE_IP_2 # Tunnel2 CGW InsideIpAddress
    VTI_REMOTEADDR=VGW_INSIDE_IP_2 # Tunnel2 VGW InsideIpAddress
    ;;
esac

case "${PLUTO_VERB}" in
    up-client)
        #$IP tunnel add ${VTI_INTERFACE} mode vti local ${PLUTO_ME} remote ${PLUTO_PEER} okey ${PLUTO_MARK_OUT_ARR[0]} ikey ${PLUTO_MARK_IN_ARR[0]}
        $IP link add ${VTI_INTERFACE} type vti local ${PLUTO_ME} remote ${PLUTO_PEER} okey ${PLUTO_MARK_OUT_ARR[0]} ikey ${PLUTO_MARK_IN_ARR[0]}
        sysctl -w net.ipv4.conf.${VTI_INTERFACE}.disable_policy=1
        sysctl -w net.ipv4.conf.${VTI_INTERFACE}.rp_filter=2 || sysctl -w net.ipv4.conf.${VTI_INTERFACE}.rp_filter=0
        $IP addr add ${VTI_LOCALADDR} remote ${VTI_REMOTEADDR} dev ${VTI_INTERFACE}
        $IP link set ${VTI_INTERFACE} up mtu 1436
            $IPTABLES -t mangle -I FORWARD -o ${VTI_INTERFACE} -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
        $IPTABLES -t mangle -I INPUT -p esp -s ${PLUTO_PEER} -d ${PLUTO_ME} -j MARK --set-xmark ${PLUTO_MARK_IN}
        $IP route flush table 220
        #/etc/init.d/bgpd reload || /etc/init.d/quagga force-reload bgpd
        ;;
    down-client)
        #$IP tunnel del ${VTI_INTERFACE}
        $IP link del ${VTI_INTERFACE}
            $IPTABLES -t mangle -D FORWARD -o ${VTI_INTERFACE} -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
        $IPTABLES -t mangle -D INPUT -p esp -s ${PLUTO_PEER} -d ${PLUTO_ME} -j MARK --set-xmark ${PLUTO_MARK_IN}
        ;;
esac


PHYSICAL_INTERFACE=$(ip route get 8.8.8.8 | awk '{ print $5; exit }')
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.$PHYSICAL_INTERFACE.disable_xfrm=1 #This value disables crypto transformations on the physical interface
sysctl -w net.ipv4.conf.$PHYSICAL_INTERFACE.disable_policy=1 #This value disables IPsec policy (SPD) for the interface
