# Ubuntu StrongSwan

## Instructions

1. Create EC2 instance like below
  - Ubuntu 20.04 LTS
  - Security group
    - Outbound UDP 500
    - Outbound UDP 4500 (NAT-T)
    - In/Outbound for local network
    - https://docs.aws.amazon.com/vpn/latest/s2svpn/your-cgw.html#FirewallRules
2. Disable source/destination check for the instance
3. Create Site-to-Site VPN connection
4. Substitute variables in [vpn-setup.sh](vpn-setup.sh) and run the script


## Reference

https://github.com/aws-samples/vpn-gateway-strongswan
