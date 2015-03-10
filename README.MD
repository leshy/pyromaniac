this config
    
```
hosts =
    salt:
        ip: '10.10.1.11'
        ports:
            salt1: 
                port: 4505, from: 'all'
            salt2:
                port: 4506, from: 'all'


    git:
        ip: '10.10.1.51'
        ports:
            ssh:
                port: 22
                from: 'all'
        
    all:
        ip: "10.10.1.2-254"


exports.settings =
    hosts: hosts

```
    
will generate

    
```
# all --> salt:salt1
iptables -A FORWARD -p tcp -m iprange --src-range 10.10.1.2-254 --dport 4505 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# all --> salt:salt2
iptables -A FORWARD -p tcp -m iprange --src-range 10.10.1.2-254 --dport 4506 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# all --> git:ssh
iptables -A FORWARD -p tcp -m iprange --src-range 10.10.1.2-254 --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# ping definitions

# all -- ping -> salt
iptables -A FORWARD -m iprange --src-range 10.10.1.2-254 -d 10.10.1.11 -p icmp --icmp-type echo-request -j ACCEPT
# all -- ping -> git
iptables -A FORWARD -m iprange --src-range 10.10.1.2-254 -d 10.10.1.51 -p icmp --icmp-type echo-request -j ACCEPT

```
    