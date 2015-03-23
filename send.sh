coffee pyro.coffee | tee forward.sh | ccze && rscp forward.sh uw:.; ssh uw 'bash -c "sudo bash /root/fw.sh"'
