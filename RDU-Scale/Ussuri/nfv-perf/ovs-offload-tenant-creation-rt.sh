#!/bin/bash

file=/tmp/osp-env-create.txt
>$file

echofun() {
  echo -e "\n\n$1" | tee -a $file
}

run_cmd() {
  source /home/stack/overcloudrc ;
  echofun "[stack@`hostname`~]$ $1 "
  eval "$1" | tee -a $file
  if [[ $? -eq 0 ]]; then
        echo -e "\n........ TASK COMPLETED" | tee -a $file
  else
        echo -e "\n........ TASK NOT COMPLETED" | tee -a $file
        exit 1;
  fi
  sleep 2;
}

delete_tenant() {
  	source /home/stack/overcloudrc ;

	for i in `openstack server list -c ID -f value`; 
		do run_cmd "openstack server delete $i --wait"; done
		run_cmd "openstack server list --long";

	run_cmd "openstack floating ip list";
	for i in `openstack floating ip list -c ID -f value`; 
		do run_cmd "openstack floating ip delete $i"; done
	for i in `openstack router list -c ID -f value`;
	do
	    run_cmd "neutron router-gateway-clear $i";
	    r_subnetid=$(openstack router show $i -c interfaces_info -f json | jq '.interfaces_info[].subnet_id' | sed 's/"//g')
	    run_cmd "openstack router remove subnet $i $r_subnetid";
	    run_cmd "openstack router delete $i";
	done; run_cmd "openstack router list"
	
	for i in `openstack port list -c ID -f value`; 
		do run_cmd "openstack port delete $i";done
		run_cmd "openstack port list";

        for i in `openstack network list -c ID -f value`;
                do run_cmd "openstack network delete $i"; done
                run_cmd "openstack network list";

	for i in `openstack image list -c ID -f value`; 
		do run_cmd "openstack image delete $i"; done

	for i in `openstack flavor list -c ID -f value`; 
		do run_cmd "openstack flavor delete $i"; done


	for i in `openstack security group list -c ID -f value`;
		do run_cmd "openstack security group delete $i"; done
		run_cmd "openstack security group list";

	for i in `openstack keypair list -c Name -f value`;
		do run_cmd "openstack keypair delete $i"; done
	aggregate=`openstack aggregate list -c Name -f value`;
	for i in `openstack hypervisor list -c "Hypervisor Hostname" -f value`;
		do run_cmd "openstack aggregate remove host $aggregate $i";
		done
		run_cmd "openstack aggregate delete $aggregate";
		run_cmd "openstack aggregate list"

	run_cmd "ls -l /home/stack/*.pem";
	run_cmd "rm -rf /home/stack/*.pem";
}

nfv_az () {	
	run_cmd "openstack aggregate create --zone=nfvprovider nfvprovider";
	for i in `openstack hypervisor list -c "Hypervisor Hostname" -f value`;
		do run_cmd "openstack aggregate add host nfvprovider $i"; done
	}

nfv_flavor () {
	run_cmd "openstack flavor list";
	run_cmd "openstack flavor create nfv-large --id auto --ram 20480 --disk 30 --vcpus 8 --property hw:cpu_realtime=yes --property hw:cpu_realtime_mask=^0-1 --property hw:numa_nodes=1 --property hw:cpu_policy='dedicated' --property hw:mem_page_size='1GB' --property hw:emulator_threads_policy='isolate' --property hw:isolated_metadata='true' --property hw:pmu='false'";
	run_cmd "openstack flavor create test --id auto --ram 4096 --disk 20 --vcpus 4";
	run_cmd "openstack flavor list --long";
	}

nfv_image () {
	run_cmd "openstack image list";
	run_cmd "openstack image create --container-format bare --disk-format qcow2 --file /home/stack/cirros-0.3.5-x86_64-disk.img cirros";
	run_cmd "openstack image create --container-format bare --disk-format qcow2 --file /home/stack/guest_image/rhel-guest-image-8.2-290.x86_64.qcow2 rhel8.2";
	run_cmd "openstack image list --long";
	}

nfv_tenant_nw () {
	run_cmd "openstack network create --share --mtu 1500 --external --provider-physical-network external --provider-network-type flat external";
	run_cmd "openstack subnet create --network external --dns-nameserver 192.168.176.1 --dns-nameserver 8.8.8.8 --dns-nameserver 10.19.42.41 --dns-nameserver 10.11.5.19 --dns-nameserver 10.5.30.160  --gateway 192.168.24.51 --subnet-range 192.168.24.0/24 --no-dhcp --allocation-pool start=192.168.24.55,end=192.168.24.70 external-subnet";
	run_cmd "openstack network create internal1";
	run_cmd "openstack subnet create --network internal1 --subnet-range 192.168.1.0/24 internal-subnet";
	run_cmd "openstack router create router1";
	run_cmd "openstack router add subnet router1 internal-subnet";
	run_cmd "neutron router-gateway-set router1 external"
}

nfv_provider_nw () {	
	run_cmd "openstack network create --share --mtu 1500 --provider-physical-network management --provider-network-type flat managament";
	run_cmd "openstack subnet create --network managament --dns-nameserver 192.168.176.1 --dns-nameserver 8.8.8.8 --dns-nameserver 10.19.42.41 --dns-nameserver 10.11.5.19 --dns-nameserver 10.5.30.160  --gateway 192.168.176.1 --subnet-range 192.168.176.0/24 managament-subnet";

	run_cmd "openstack network create --share --mtu 1500 --provider-physical-network external --provider-network-type flat external";
	run_cmd "openstack subnet create --no-dhcp --network external --gateway 10.16.31.254 --subnet-range 10.16.28.0/22 external-subnet";

	run_cmd "openstack network create --share --provider-physical-network offload1 --provider-network-type vlan --provider-segment 178 provider-1";
	run_cmd "openstack subnet create --no-dhcp --network provider-1 --gateway 192.168.177.1 --subnet-range 192.168.178.0/24 provider-subnet-1";
	run_cmd "openstack network create --share --provider-physical-network offload2 --provider-network-type vlan --provider-segment 177 provider-2";
	run_cmd "openstack subnet create --no-dhcp --network provider-2 --gateway 192.168.178.1 --subnet-range 192.168.177.0/24 provider-subnet-2";
	}	

nfv_sec () {
	run_cmd "openstack security group create secgroup1";
	run_cmd "openstack security group rule create secgroup1 --protocol icmp --prefix 0.0.0.0/0 --ingress";
	run_cmd "openstack security group rule create secgroup1 --protocol icmp --prefix 0.0.0.0/0 --egress";
	run_cmd "openstack security group rule create secgroup1 --protocol tcp --prefix 0.0.0.0/0 --ingress";
	run_cmd "openstack security group rule create secgroup1 --protocol udp --prefix 0.0.0.0/0 --ingress";
	run_cmd "openstack security group rule create secgroup1 --protocol tcp --prefix 0.0.0.0/0 --egress";
	run_cmd "openstack security group rule create secgroup1 --protocol udp --prefix 0.0.0.0/0 --egress";
	security=`openstack security group list -c Name -f value | grep secgroup1`
	}

sec_fun () {
	security=`openstack security group list -c Name -f value | grep secgroup1`
}	

nfv_keypair () {
	run_cmd "openstack keypair create key1 > key.pem";
	run_cmd "chmod 600 key.pem";
	}

nfv_ports () {
	sec_fun;
	openstack port create --network provider-1 --vnic-type direct --no-security-group --disable-port-security --binding-profile '{"capabilities": ["switchdev"]}' provider1-port1;
	openstack port create --network provider-2 --vnic-type direct --no-security-group --disable-port-security --binding-profile '{"capabilities": ["switchdev"]}' provider2-port1;
	run_cmd "openstack port create --network managament --security-group $security --fixed-ip ip-address=192.168.176.50 managament-port1"
	run_cmd "openstack port create --network external --no-security-group --disable-port-security external-port1"
}

nfv_instance () {
	provider1_port1=`openstack port list | grep provider1-port1 | awk '{print $2}'`
	provider2_port1=`openstack port list | grep provider2-port1 | awk '{print $2}'`
	managament_port1=`openstack port list | grep managament-port1 | awk '{print $2}'`
	external_port1=`openstack port list | grep external-port1 | awk '{print $2}'`
	sec_fun;
	run_cmd "openstack quota set --cores 50 --ram 200000 admin";
	run_cmd "openstack server create --flavor nfv-large --security-group $security --nic port-id=$managament_port1 --nic port-id=$external_port1 --nic port-id=$provider1_port1 --nic port-id=$provider2_port1 --key-name key1 --image rhel8.2 --availability-zone nfvprovider TestPMD --wait";
	}

delete_tenant;
nfv_az;
nfv_flavor;
nfv_image;
#nfv_tenant_nw;
nfv_provider_nw;
nfv_sec;
nfv_keypair;
nfv_ports;
nfv_instance;

