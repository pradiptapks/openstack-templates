#!/bin/bash

source /home/stack/stackrc

for i in `openstack baremetal node list | grep dell-r740 | awk '{print $2}'`; 
do 
	openstack baremetal node set --property capabilities='profile:ComputeOvsDpdkSriov,boot_option:local' $i; 
done
for i in `openstack baremetal node list | grep controller | awk '{print $2}'`; 
do 
	openstack baremetal node set --property capabilities='profile:Controller,boot_option:local' $i; 
done
openstack overcloud profiles list;
openstack flavor list -c ID -f value | xargs -I {} openstack flavor delete {};
openstack flavor create compute --id auto --ram 60000 --disk 200 --vcpus 16 --property capabilities:boot_option='local' --property capabilities:profile='ComputeOvsDpdkSriov' --property cpu_arch='x86_64';
openstack flavor create controller --id auto --ram 8000 --disk 30 --vcpus 6 --property capabilities:boot_option='local' --property capabilities:profile='Controller' --property cpu_arch='x86_64';
openstack flavor list;
