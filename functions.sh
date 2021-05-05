#!/bin/bash

init() {
source ./install.env
}

hostSetup() {
echo "***** Host Setup *****"
# swap off
sudo swapoff -a
# make it permanent remove entry from fstab
# sudo vim /etc/fstab
sudo sed -i '$d' /etc/fstab
sudo rm /swap.img
echo "***** Host Setup Complete *****"
}

configIpTables() {
echo "***** Config IP Tables *****"
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
echo "***** Config IP Tables Complete *****"
}

installDocker() {
echo "***** Install Docker *****"
sudo apt-get update -y -q
sudo apt-get install -y -q \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y -q && sudo apt-get install -y -q \
  containerd.io=${CONTAINERD_VERSION} \
  docker-ce=${DOCKER_VERSION}-$(lsb_release -cs) \
  docker-ce-cli=${DOCKER_VERSION}-$(lsb_release -cs)

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo docker run hello-world
echo "***** Install Docker Complete *****"
}

kubeInstall() {
echo "***** Install Kube *****"
sudo apt-get update -q -y
sudo apt-get install -q -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -q -y
curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages | grep Version | awk '{print $2}'
sudo apt-get install -qy kubelet=${KUBE_VERSION} kubectl=${KUBE_VERSION} kubeadm=${KUBE_VERSION}
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet
echo "***** Install Kube Complete *****"
}

kubeInit() {
echo "***** Kube Init *****"
sudo kubeadm init --node-name ${KUBE_NAME} --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint="${CONTROL_PLANE_ENDPOINT}"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# we're running a single node cluster
kubectl taint nodes --all node-role.kubernetes.io/master-
echo "***** Kube Init Complete *****"
}