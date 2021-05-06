# kubeadm-bake

Hand crafting kubeadm on ubuntu one script at a time.  A crude runbook for creating mini k8s clusters for homelab'ing and such.

* Prerequisites
  * A Ubuntu machine for kubeadm
  * Ubuntu machine(s) for kubernetes workers
  * unzip installed

Typically what I do is provision Ubuntu VMs on vSphere or locally with VMware Fusion, any Ubuntu VM should work.

## On all machines (master and workers)

* SSH into your machine
* Get scripts from github

```bash
curl -L -O https://github.com/corbtastik/kubeadm-bake/archive/refs/heads/main.zip
unzip main.zip
cd kubeadm-bake-main
```

* Edit `install.env` to your liking.  `CONTROL_PLANE_ENDPOINT` is the name in DNS or IP for the kubeadm/master machine.

```bash
CONTAINERD_VERSION=1.2.13-2
DOCKER_VERSION=5:19.03.11~3-0~ubuntu
KUBE_VERSION=1.19.8-00
KUBE_NAME=kubeadm
CONTROL_PLANE_ENDPOINT=kubeadm.retro.io
```
## On master machine

* Edit `install.env` to your liking
* Run `install_master.sh` to provision kubeadm and k8s master

## On worker machines

* Edit `install.env` to your liking
* Run `install_worker.sh` to provision a worker node

## References

* [Install Kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm)
