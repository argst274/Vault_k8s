# Kubernetes "K8S" Terraform Deployment
Maintained and created by Alan Groves

## Requirements

Before proceeding please ensure you have all the requirements below

>1. OpenStack command-line client. [how-to...](https://docs.openstack.org/newton/user-guide/common/cli-install-openstack-command-line-clients.html)
>2. Authenticated to OpenStack API endpoints
>test example:
```
$ openstack server list --minimal
+--------------------------------------+----------------------------+
| ID                                   | Name                       |
+--------------------------------------+----------------------------+
| fac1dfcb-4ce6-45df-8614-5d996dd102d8 | dev-instance               |
+--------------------------------------+----------------------------+
```
>3. Terraform Installed [how-to...](https://www.terraform.io/intro/getting-started/install.html)

## Insutructions

>1. Update the variables file
>2. Ensure you have allowed internet traffic from the jump-box and 192.168.207.0/24 subnet
>3. Ensure there is a host route on the DMZ subnet eg: destination='192.168.207.0/24', gateway='172.31.255.207'
>4. Ensure you have the same static route on the firewall 
>5. Ensure you have allowed SSH access to the jump-box eg: 172.16.0.207
>6. If you add addional worker nodes be sure to update the hosts.ini file

## Test

Fetch the nodes and services in the namespace

`$ kubectl -n kube-system get nodes`
`$ kubectl -n kube-system get services`

Note: The config file can be found on the first master node in the following dir `/root/.kube/config`

## Architecture
```mermaid
graph TD
subgraph Existing DMZ Network
C[k8s-jump] 
end
subgraph 
C--Router DMZ Interface 172.16.0.207--> D((Router))
end
subgraph k8s_POC_network 192.168.207.0/24
subgraph Master Nodes + etcd
D -- Router Interface 192.168.207.1 --> F[k8s-master-node-1]
H[k8s-master-node-2]
I[k8s-master-node-3]
end
subgraph Worker Nodes
F-->J(k8s-worker-node-1)
F-->K(k8s-worker-node-2)
F-->L(k8s-worker-node-3)
end
end
```

## Dashboard

If you want to use the dashboard follow these instructions
>1. SSH to the master node
>2. Run the following command `vi kube-dashboard-access.yaml` 
>3. Copy/Paste the following into the file (edit the file by pressing 'i')

```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
 ```
 
 >4. Save and close the file ('ctrl + [' then ':qw')
 >5. Run the following command `kubectl create -f kube-dashboard-access.yaml`
 >6. Dashboard is now published on the master node 
 ```
 https://<first_master>:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login
 ```