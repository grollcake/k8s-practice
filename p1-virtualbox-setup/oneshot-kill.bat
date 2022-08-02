VBoxManage natnetwork add --netname k8s-natnetwork --network "192.168.0.0/24" --enable --dhcp on
vagrant up