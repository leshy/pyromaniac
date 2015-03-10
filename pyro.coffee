ribcage = require 'ribcage'
util = require 'util'
fs = require 'fs'
_ = require 'underscore'

ribcage.init {}, (err,env) ->
    _.each env.settings.rules.forward, (rule) ->        
        compiled = [ 'iptables -A FORWARD' ]
        
        if rule.proto then compiled.push "-p #{rule.proto}" else compiled.push "-p tcp"

        if rule.from.indexOf('-') is -1 then compiled.push "-s #{rule.from}"
        else compiled.push "-m iprange --src-range #{rule.from}"

        if not rule.port then throw "no port " + rule
            
        if rule.port.constructor is Number or rule.port.indexOf('-') is -1 then compiled.push "--dport #{rule.port}"
        else compiled.push "--match multiport --dports #{rule.port}"

        compiled.push "-m state --state NEW,ESTABLISHED,RELATED -j ACCEPT"

        console.log compiled.join(' ')
        