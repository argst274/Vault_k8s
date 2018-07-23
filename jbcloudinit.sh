#!/bin/bash
set -exuo pipefail
sudo apt update -y
cd /home/ubuntu
git clone https://github.com/kubernetes-incubator/kubespray.git
cd /home/ubuntu/kubespray
sudo apt install -y python-pip
sudo pip install -r requirements.txt
cp -rfp /home/ubuntu/kubespray/inventory/sample /home/ubuntu/kubespray/inventory/mycluster
cp /home/ubuntu/hosts.ini /home/ubuntu/kubespray/inventory/mycluster/hosts.ini
chmod 600 /home/ubuntu/.ssh/anisble_POC_key
ansible-playbook -e --ssh-extra-args='-o StrictHostKeyChecking=no' -i inventory/mycluster/hosts.ini --private-key=/home/ubuntu/.ssh/anisble_POC_key -u ubuntu cluster.yml -b