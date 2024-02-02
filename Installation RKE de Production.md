### 1. Ajout des entrées DNS dans /etc/hosts:

```properties
echo '10.30.20.20 production-master-01
10.30.20.21 production-master-02
10.30.20.22 production-master-03
10.30.20.23 production-worker-01
10.30.20.24 production-worker-02
10.30.20.25 production-worker-03' >> /etc/hosts
```

### 2. Installation Docker :

```properties
curl https://releases.rancher.com/install-docker/20.10.sh | sudo sh" 
```

### 3. Désactivation SWAP :

```properties
swapoff -a; sed -i '/swap/d' /etc/fstab
```

### 4. Création du User "rke" ayant le password "pass123" & membre du groupe docker:

```properties
useradd rke -m -G docker;echo rke:pass123 | chpasswd
```

### 5. Configuration sysctl du kernel pour kubernetes :

```properties
cat >/etc/sysctl.d/kubernetes.conf<<EOF 
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
```

### 6. Génération d'une paire de clé SSH avec PassPhrase :

```properties
ssh-keygen -q -C "RKE cluster Boostraping" -t ed25519 -f rke
```

### 7. Copie de la clé publique dans /home/rke/.ssh/authorized_keys vers tous les noeuds:

```properties
for i in `seq 1 3`;do sshpass -p 'pass123' ssh-copy-id -i rke.pub -o StrictHostKeyChecking=no rke@production-master-0"$i";done
for i in `seq 1 3`;do sshpass -p 'pass123' ssh-copy-id -i rke.pub -o StrictHostKeyChecking=no rke@production-worker-0"$i";done
```

### 8. Création du répertoire des manifests des pods statiques de kube-vip on 3 master nodes:

```properties
mkdir -p /etc/kubernetes/manifest/"  
```


### 9. Création du fichier de boostraping rke "cluster.yml" :

```yaml
nodes:
- address: 10.30.20.20
  port: "22"
  role:
  - controlplane
  - etcd
  hostname_override: production-master-01
  user: rke
  docker_socket: /var/run/docker.sock
- address: 10.30.20.21
  port: "22"
  role:
  - controlplane
  - etcd
  hostname_override: production-master-02
  user: rke
  docker_socket: /var/run/docker.sock
- address: 10.30.20.22
  port: "22"
  role:
  - controlplane
  - etcd
  hostname_override: production-master-03
  user: rke
  docker_socket: /var/run/docker.sock
- address: 10.30.20.23
  port: "22"
  role:
  - worker
  hostname_override: production-worker-01
  user: rke
  docker_socket: /var/run/docker.sock
- address: 10.30.20.24
  port: "22"
  role:
  - worker
  hostname_override: production-worker-02
  user: rke
  docker_socket: /var/run/docker.sock
- address: 10.30.20.25
  port: "22"
  role:
  - worker
  hostname_override: production-worker-03
  user: rke
  docker_socket: /var/run/docker.sock      
services:
  kube-api:
    service_cluster_ip_range: 10.43.0.0/16
    pod_security_policy: false
    always_pull_images: false
  kube-controller:
    cluster_cidr: 10.42.0.0/16
    service_cluster_ip_range: 10.43.0.0/16
  kubelet:
    cluster_domain: dtr.lan
    cluster_dns_server: 10.43.0.10
    fail_swap_on: false
    generate_serving_certificate: false
  # Les pods statiques pour kube-vip
    extra_args:
      pod-manifest-path: /etc/kubernetes/manifest/ 
network:
  plugin: calico
  mtu: 0
# Ajouter la VIP dans le SANS
authentication:
  strategy: x509
  sans:
    - "10.30.20.33"
system_images:
  etcd: rancher/mirrored-coreos-etcd:v3.5.6
  alpine: rancher/rke-tools:v0.1.90
  nginx_proxy: rancher/rke-tools:v0.1.90
  cert_downloader: rancher/rke-tools:v0.1.90
  kubernetes_services_sidecar: rancher/rke-tools:v0.1.90
  kubedns: rancher/mirrored-k8s-dns-kube-dns:1.22.20
  dnsmasq: rancher/mirrored-k8s-dns-dnsmasq-nanny:1.22.20
  kubedns_sidecar: rancher/mirrored-k8s-dns-sidecar:1.22.20
  kubedns_autoscaler: rancher/mirrored-cluster-proportional-autoscaler:1.8.6
  coredns: rancher/mirrored-coredns-coredns:1.9.4
  coredns_autoscaler: rancher/mirrored-cluster-proportional-autoscaler:1.8.6
  nodelocal: rancher/mirrored-k8s-dns-node-cache:1.22.20
  kubernetes: rancher/hyperkube:v1.26.8-rancher1
  flannel: rancher/mirrored-flannel-flannel:v0.21.4
  flannel_cni: rancher/flannel-cni:v0.3.0-rancher8
  calico_node: rancher/mirrored-calico-node:v3.25.0
  calico_cni: rancher/calico-cni:v3.25.0-rancher1
  calico_controllers: rancher/mirrored-calico-kube-controllers:v3.25.0
  calico_ctl: rancher/mirrored-calico-ctl:v3.25.0
  calico_flexvol: rancher/mirrored-calico-pod2daemon-flexvol:v3.25.0
  canal_node: rancher/mirrored-calico-node:v3.25.0
  canal_cni: rancher/calico-cni:v3.25.0-rancher1
  canal_controllers: rancher/mirrored-calico-kube-controllers:v3.25.0
  canal_flannel: rancher/mirrored-flannel-flannel:v0.21.4
  canal_flexvol: rancher/mirrored-calico-pod2daemon-flexvol:v3.25.0
  weave_node: weaveworks/weave-kube:2.8.1
  weave_cni: weaveworks/weave-npc:2.8.1
  pod_infra_container: rancher/mirrored-pause:3.7
  ingress: rancher/nginx-ingress-controller:nginx-1.7.0-rancher1
  ingress_backend: rancher/mirrored-nginx-ingress-controller-defaultbackend:1.5-rancher1
  ingress_webhook: rancher/mirrored-ingress-nginx-kube-webhook-certgen:v20230312-helm-chart-4.5.2-28-g66a760794
  metrics_server: rancher/mirrored-metrics-server:v0.6.3
  windows_pod_infra_container: rancher/mirrored-pause:3.7
  aci_cni_deploy_container: noiro/cnideploy:6.0.3.1.81c2369
  aci_host_container: noiro/aci-containers-host:6.0.3.1.81c2369
  aci_opflex_container: noiro/opflex:6.0.3.1.81c2369
  aci_mcast_container: noiro/opflex:6.0.3.1.81c2369
  aci_ovs_container: noiro/openvswitch:6.0.3.1.81c2369
  aci_controller_container: noiro/aci-containers-controller:6.0.3.1.81c2369
  aci_gbp_server_container: ""
  aci_opflex_server_container: ""
# Pour l'utilisation du SSH agent
ssh_agent_auth: true
authorization:
  mode: rbac
# Enable dockerd CRI  
enable_cri_dockerd: true
kubernetes_version: "v1.26.8-rancher1-1"
cluster_name: "production-cluster"
```

### 10. Installation du binaire RKE:

```properties
wget https://github.com/rancher/rke/releases/download/v1.3.15/rke_linux-amd64
sudo mv rke_linux-amd64 /usr/local/bin/rke
sudo chmod +x usr/local/bin/rke
```
### 11. Installation du binaire kubectl

```properties
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s
https://storage.googleapis.com/kubernetesrelease/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

### 12. Bootstrapping du Cluster RKE :

``` properties
eval $(ssh-agent -s)
ssh-add rke
rke --debug up --ssh-agent-auth
```
### 13. Déploiement kube-vip 

```properties
for i in `seq 1 3`;do scp -o StrictHostKeyChecking=no "${PWD}"/kube_config_cluster.yml sagiruser@production-master-0"$i":/home/sagiruser/admin.conf;done
```

** il faut changer manuellement admin.conf pour mettre l'@IP adéquate.**

```properties
export INTERFACE=ens3
export VIP=10.30.20.33
export IMAGE='ghcr.io/kube-vip/kube-vip:v0.3.8'
cat > /etc/kubernetes/manifest/kube-vip.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: kube-vip
  namespace: kube-system
spec:
  containers:
  - args:
    - manager
    env:
    - name: vip_arp
      value: "true"
    - name: vip_interface
      value: ${INTERFACE}
    - name: port
      value: "6443"
    - name: vip_cidr
      value: "32"
    - name: cp_enable
      value: "true"
    - name: cp_namespace
      value: kube-system
    - name: vip_ddns
      value: "false"
    - name: svc_enable
      value: "true"
    - name: vip_leaderelection
      value: "true"
    - name: vip_leaseduration
      value: "5"
    - name: vip_renewdeadline
      value: "3"
    - name: vip_retryperiod
      value: "1"
    - name: vip_address
      value: "${VIP}"
    image: "${IMAGE}"
    imagePullPolicy: Always
    name: kube-vip
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_RAW
        - SYS_TIME
    volumeMounts:
    - mountPath: /etc/kubernetes/admin.conf
      name: kubeconfig
    - mountPath: /etc/hosts
      name: hosts
      readOnly: true
  hostNetwork: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/admin.conf
    name: kubeconfig
  - name: hosts
    hostPath:
      path: /etc/hosts
      type: File
EOF
```










