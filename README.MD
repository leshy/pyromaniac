this config
    
```
hosts =
    vpn:
        ip: '10.66.1.70'
        publicPorts:
            vpn:
                port: 443
                
    salt:
        ip: '10.66.1.11'
        ports:
            salt1: 
                port: 4505, from: 'all'
            salt2:
                port: 4506, from: 'all'

    git:
        ip: '10.66.1.51'
        ports:
            ssh:
                port: 22
                from: 'all'
        
    all:
        ip: "10.66.1.2-254"


exports.settings =
    rules:
        forward: [
            { from: 'vpn', to: 'all', comment: 'vpn to everyone TCP' }
            { from: 'vpn', to: 'all', proto: 'udp', comment: 'vpn to everyone UDP' }
        ]

    hosts: hosts

```
    
will generate

    
```
# NAT

# 443 --> vpn:443
iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 443 -j DNAT --to-destination 10.66.1.70:443
iptables -A FORWARD -p tcp -d 10.66.1.70 --dport 443 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# INTERNAL

# vpn to everyone TCP
iptables -A FORWARD -p tcp -m iprange --dst-range 10.66.1.2-254 -s 10.66.1.70 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# vpn to everyone UDP
iptables -A FORWARD -p udp -m iprange --dst-range 10.66.1.2-254 -s 10.66.1.70 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# all --> salt:salt1
iptables -A FORWARD -p tcp -d 10.66.1.11 -m iprange --src-range 10.66.1.2-254 --dport 4505 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# all --> salt:salt2
iptables -A FORWARD -p tcp -d 10.66.1.11 -m iprange --src-range 10.66.1.2-254 --dport 4506 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# all --> git:ssh
iptables -A FORWARD -p tcp -d 10.66.1.51 -m iprange --src-range 10.66.1.2-254 --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# INTERNAL PINGS

# vpn -- ping -> all
iptables -A FORWARD -s 10.66.1.70 -m iprange --dst-range 10.66.1.2-254 -p icmp --icmp-type echo-request -j ACCEPT
# all -- ping -> undefined
iptables -A FORWARD -m iprange --src-range 10.66.1.2-254 -d 10.66.1.11 -p icmp --icmp-type echo-request -j ACCEPT
# all -- ping -> undefined
iptables -A FORWARD -m iprange --src-range 10.66.1.2-254 -d 10.66.1.51 -p icmp --icmp-type echo-request -j ACCEPT
```

reads hosts definitions and builds forward rules

    
reads forward rules and compiles ICMP forward rules

    
reads forward rules and compiles them

    