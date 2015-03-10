ribcage = require 'ribcage'
util = require 'util'
fs = require 'fs'
_ = require 'underscore'

ribcage.init {}, (err,env) ->

   
    _.each env.settings.rules.forward, (rule) ->        
        compiled = [ ]
        match = {}
        
        if rule.proto then compiled.push "-p #{rule.proto}" else compiled.push "-p tcp"

        if rule.from.indexOf('-') is -1 then compiled.push "-s #{rule.from}"
        else
            match['iprange'] = true
            compiled.push "--src-range #{rule.from}"


        if rule.port
            if rule.port.constructor is Number or rule.port.indexOf('-') is -1 then compiled.push "--dport #{rule.port}"
            else
                match['multiport'] = true
                compiled.push "--dports #{rule.port}"

        match['state'] = true
        
        compiled.push "--state NEW,ESTABLISHED,RELATED -j ACCEPT"

        if _.keys(match).length then compiled.unshift '-m ' + _.keys(match).join(' ')
        compiled.unshift['iptables -A FORWARD' ]
        console.log compiled.join(' ')
        
    pings = []
    _.each env.settings.rules.forward, (rule) ->
            pings.push { to: rule.from, from: rule.to }
            pings.push { from: rule.from, to: rule.to }

    _.each pings, (rule) ->
        compiled = [ 'iptables -A FORWARD ' ]
        modules = {}
        
        if rule.from.indexOf('-') is -1 then compiled.push "-s #{rule.from}"
        else compiled.push "-m iprange --src-range #{rule.from}"

                
        
        compiled.push '-p icmp --icmp-type echo-request -m conntrack --ctstate NEW -m limit --limit 10/s -j ACCEPT'

