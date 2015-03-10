this config
    
```
hosts =
    vpn:
        ip: '10.1.1.70'

    salt:
        ip: '10.1.1.11'
        ports:
            salt1: 
                port: 4505, from: 'all'
            salt2:
                port: 4506, from: 'all'

        publicPorts:
            http:
                port: 80

    git:
        ip: '10.1.1.51'
        ports:
            ssh:
                port: 22
                from: 'all'
        
    all:
        ip: "10.1.1.2-254"


exports.settings =
    rules:
        forward: [
            { from: 'vpn', to: 'all', comment: 'vpn to everyone TCP'}
            { from: 'vpn', to: 'all', proto: 'udp', comment: 'vpn to everyone UDP' }
        ]

    hosts: hosts

```
    
will generate

    
```
# vpn to everyone TCP 
iptables -A FORWARD -p tcp -s 10.1.1.70 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 
# vpn to everyone UDP 
iptables -A FORWARD -p udp -s 10.1.1.70 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 
# all --> salt:salt1 
iptables -A FORWARD -p tcp -m iprange --src-range 10.1.1.2-254 --dport 4505 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 
# all --> salt:salt2 
iptables -A FORWARD -p tcp -m iprange --src-range 10.1.1.2-254 --dport 4506 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 
# all --> git:ssh 
iptables -A FORWARD -p tcp -m iprange --src-range 10.1.1.2-254 --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 

# ping definitions 

# vpn -- ping -> all 
iptables -A FORWARD -s 10.1.1.70 -m iprange --dst-range 10.1.1.2-254 -p icmp --icmp-type echo-request -j ACCEPT 
# all -- ping -> 10.1.1.11 
iptables -A FORWARD -m iprange --src-range 10.1.1.2-254 -d 10.1.1.11 -p icmp --icmp-type echo-request -j ACCEPT 
# all -- ping -> 10.1.1.51 
iptables -A FORWARD -m iprange --src-range 10.1.1.2-254 -d 10.1.1.51 -p icmp --icmp-type echo-request -j ACCEPT 

```

reads hosts definitions and builds forward rules

    
reads forward rules and compiles ICMP forward rules

    
reads forward rules and compiles them

    