ribcage = require 'ribcage'
util = require 'util'
fs = require 'fs'
_ = require 'underscore'

ribcage.init {}, (err,env) ->
    rules = env.settings.rules
    hosts = env.settings.hosts
    
    _.map hosts, (host,hostName) ->
        if host.ports
            _.map host.ports, (port,portName) ->
                rule = _.extend {}, _.pick port, 'proto', 'port'
                
                rule.to = host.ip
                rule.from = port.from

                rule.comment = "#{port.from} --> #{hostName}:#{portName}"

                rule._toName = hostName
                rule._fromName = port.from

                rules.forward.push rule
        

        
    
    _.each rules.forward, (rule) ->
        compiled = [ 'iptables -A FORWARD' ]
        
        if rule.proto then compiled.push "-p #{rule.proto}" else compiled.push "-p tcp"

        if hosts[rule.from] then rule.from = hosts[rule.from].ip
        if hosts[rule.to] then rule.to = hosts[rule.to].ip
            
        if rule.from.indexOf('-') is -1 then compiled.push "-s #{rule.from}"
        else compiled.push "-m iprange --src-range #{rule.from}"

        if rule.port
            if rule.port.constructor is Number or rule.port.indexOf('-') is -1 then compiled.push "--dport #{rule.port}"
            else compiled.push "--match multiport --dports #{rule.port}"

        compiled.push "-m state --state NEW,ESTABLISHED,RELATED -j ACCEPT"

        if rule.comment then console.log "# " + rule.comment
        console.log compiled.join(' ')
        
    pings = []
    _.each env.settings.rules.forward, (rule) ->
        if not _.find(pings, (entry) -> entry.from is rule.from and entry.to is rule.to)
            pings.push { from: rule.from, to: rule.to, comment: "#{rule._fromName} -- ping -> #{rule._toName}" }

    console.log "\n# ping definitions\n"

    _.each pings, (rule) ->
        compiled = [ 'iptables -A FORWARD' ]

        if rule.from.indexOf('-') is -1 then compiled.push "-s #{rule.from}"
        else compiled.push "-m iprange --src-range #{rule.from}"

        if rule.to.indexOf('-') is -1 then compiled.push "-d #{rule.to}"
        else compiled.push "-m iprange --dst-range #{rule.to}"
        
        compiled.push '-p icmp --icmp-type echo-request -j ACCEPT'
        
        if rule.comment then console.log "# " + rule.comment        
        console.log compiled.join(' ')


