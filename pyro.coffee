ribcage = require 'ribcage'
util = require 'util'
fs = require 'fs'
_ = require 'underscore'

ribcage.init { verboseInit: false }, (err,env) ->
    rules = env.settings.rules
    if not rules.forward then rules.forward = []
    if not rules.nat then rules.nat = []
    hosts = env.settings.hosts

    resolveHost = (host) ->
      if resolvedHost = hosts[host]?.ip then return resolvedHost else return host

    resolveHostArray = (host) ->
      if host.constructor is Array
        return _.map(host, resolveHost).join(',')
      else resolveHost(host)

    resolveHosts = (rule) ->
        if rule.from
            rule._fromName = rule.from
            rule.from = resolveHostArray rule.from
        if rule.to
            rule._toName = rule.to
            rule.to = resolveHostArray rule.to

    _.map hosts, (host,hostName) ->
        if host.ports
            _.map host.ports, (port,portName) ->
                rule = _.extend {}, _.pick port, 'proto', 'port'

                rule.to = host.ip
                rule._toName = hostName
                rule.from = port.from

                rule.comment = "#{port.from} --> #{hostName}:#{portName}"

                rules.forward.push rule

        if host.publicPorts
            _.map host.publicPorts, (port,portName) ->
                rule = _.extend {}, _.pick port, 'proto', 'port', 'internalPort'
                rule.to = host.ip
                rule._toName = hostName
                rule.from = port.host
                rule._portName = portName

                rules.nat.push rule


    compileNat = (rule) ->
        rule = _.extend {}, { proto: 'tcp' }, rule
        resolveHosts(rule)

        compiled = [ "iptables -A PREROUTING -t nat -p #{rule.proto} -i eth0" ]

        if rule.port.constructor is Number then compiled.push "--dport #{rule.port}"
        else compiled.push "--match multiport --dports #{rule.port}"

        if rule.from then compiled.push "-d #{rule.from}"
        if rule.from then rule.comment = "#{rule.from}:#{rule.port} --> #{rule._toName}:#{rule.internalPort or rule.port}"
        else rule.comment = "#{rule.port} --> #{rule._toName}:#{rule.internalPort or rule.port}"

        if not rule.internalPort then compiled.push "-j DNAT --to #{rule.to}"
        else compiled.push "-j DNAT --to #{rule.to}:#{rule.internalPort}"

        str = compiled.join (' ')
        if rule.comment then str = "# " + rule.comment + "\n" + str
        str

    compileForward = (rule) ->
        compiled = [ 'iptables -A FORWARD' ]

        if rule.proto then compiled.push "-p #{rule.proto}" else compiled.push "-p tcp"

        resolveHosts(rule)

        if rule.to
            if rule.to.indexOf('-') is -1 then compiled.push "-d #{rule.to}"
            else compiled.push "-m iprange --dst-range #{rule.to}"

        if rule.from
            if rule.from.indexOf('-') is -1 then compiled.push "-s #{rule.from}"
            else compiled.push "-m iprange --src-range #{rule.from}"

        if rule.port
            if rule.port.constructor is Number or rule.port.indexOf(':') is -1 then compiled.push "--dport #{rule.port}"
            else compiled.push "--match multiport --dports #{rule.port}"

        compiled.push "-m state --state NEW,ESTABLISHED,RELATED -j ACCEPT"

        str = compiled.join (' ')
        if rule.comment then str = "# " + rule.comment + "\n" + str
        str


    console.log "# NAT\n"
    _.each rules.nat, (rule) ->
        console.log compileNat rule
        delete rule.from
        if rule.internalPort then rule.port = rule.internalPort
        console.log compileForward rule

    console.log "\n# INTERNAL CONNECTIONS\n"
    _.each rules.forward, (rule) ->
        console.log compileForward rule

    console.log "\n# INTERNAL PINGS\n"

    pings = []
    _.each rules.forward, (rule) ->
        if not rule.from then return
        if not _.find(pings, (entry) -> entry.from is rule.from and entry.to is rule.to)
            pings.push { from: rule.from, to: rule.to, comment: "#{rule._fromName} -- ping -> #{rule._toName}" }

    _.each pings, (rule) ->
        compiled = [ 'iptables -A FORWARD' ]

        resolveHosts(rule)

        if rule.from.indexOf('-') is -1 then compiled.push "-s #{rule.from}"
        else compiled.push "-m iprange --src-range #{rule.from}"

        if rule.to.indexOf('-') is -1 then compiled.push "-d #{rule.to}"
        else compiled.push "-m iprange --dst-range #{rule.to}"

        compiled.push '-p icmp --icmp-type echo-request -j ACCEPT'

        if rule.comment then console.log "# " + rule.comment
        console.log compiled.join(' ')
