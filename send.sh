#!/bin/bash
source /usr/share/bash/init.sh
shopt -s expand_aliases

coffee pyro.coffee | tee forward.sh | ccze
shw_err sending
rscp forward.sh uw:.; ssh uw 'bash -c "sudo bash /root/fw.sh"'
