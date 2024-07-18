#!/bin/bash

# Get the IP addresses from Terraform output
MASTER_IP=$(terraform output -json k8s_node_ips | jq -r '.[0]')
WORKER_IPS=$(terraform output -json k8s_node_ips | jq -r '.[1,2]')

# Set up the master node
ssh ubuntu@$MASTER_IP <<EOF
sudo /usr/local/bin/k3s-install.sh
EOF

# Get the K3s token
K3S_TOKEN=$(ssh ubuntu@$MASTER_IP "sudo cat /var/lib/rancher/k3s/server/node-token")

# Join worker nodes to the cluster
for WORKER_IP in $WORKER_IPS; do
  ssh ubuntu@$WORKER_IP <<EOF
sudo K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN /usr/local/bin/k3s-install.sh
EOF
done

echo "K3s cluster setup completed. Master node IP: $MASTER_IP"
