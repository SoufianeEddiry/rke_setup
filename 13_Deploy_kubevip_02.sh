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