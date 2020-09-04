#!/bin/bash

source /home/stack/stackrc

#openstack stack delete overcloud -y --wait; openstack overcloud delete overcloud -y; sleep 2m;

TEMPLATE_DIR=/home/stack/nfv_16_rt_offload

set -ux

time openstack overcloud deploy \
--templates /usr/share/openstack-tripleo-heat-templates \
-n ${TEMPLATE_DIR}/network_data.yaml \
-r ${TEMPLATE_DIR}/roles_data.yaml \
--stack overcloud \
--libvirt-type kvm \
--ntp-server 192.168.24.1 \
-e ${TEMPLATE_DIR}/network/network-environment-sriov.yaml \
-e ${TEMPLATE_DIR}/hostnames.yml \
-e ${TEMPLATE_DIR}/debug.yaml \
-e ${TEMPLATE_DIR}/nodes_data.yaml \
-e ${TEMPLATE_DIR}/network/sriov-rt-environment.yaml \
-e ${TEMPLATE_DIR}/post-config-rt.yaml \
-e ${TEMPLATE_DIR}/network/servicenet_mapping.yaml \
-e ${TEMPLATE_DIR}/api-policies.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovs.yaml \
-e /home/stack/containers-prepare-parameter.yaml \
-e ${TEMPLATE_DIR}/api-policies.yaml \
--validation-warnings-fatal --timeout 300 \
--log-file overcloud_install.log &> /home/stack/overcloud_install.log

