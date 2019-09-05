{ date; time openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /home/stack/docker_registry.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/disable-telemetry.yaml -e /home/stack/templates/deploy.yaml -e /home/stack/templates/neutron.yaml -e /home/stack/templates/remove.yaml -r /home/stack/templates/roles_data.yaml --ntp-server clock1.rdu2.redhat.com,clock.redhat.com,clock2.redhat.com --timeout 120 2>&1; date; } | tee -a deploy_log.txt