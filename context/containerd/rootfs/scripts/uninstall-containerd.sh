#!/bin/bash

container=sealer-registry
docker rm -f $container

#systemctl stop containerd
# systemctl disable containerd
systemctl daemon-reload

rm -f /etc/containerd/certs.d
rm -f /etc/containerd/config.toml
rm -f /etc/docker/certs.d

#rm -f /usr/bin/conntrack
#rm -f /usr/bin/kubelet-pre-start.sh
##rm -f /usr/bin/containerd
##rm -f /usr/local/bin/containerd
##rm -rf /etc/containerd
#rm -rf /etc/docker/registry
#rm -f /usr/bin/containerd-shim
#rm -f /usr/bin/containerd-shim-runc-v2
#rm -f /usr/bin/crictl
#rm -f /usr/bin/ctr
#
#rm -f /usr/bin/rootlesskit
#rm -f /usr/bin/rootlesskit-docker-proxy
#rm -f /usr/bin/runc
#rm -f /usr/bin/vpnkit
#rm -f /usr/bin/containerd-rootless-setuptool.sh
#rm -f /usr/bin/containerd-rootless.sh
#rm -f /usr/bin/nerdctl
#rm -f /etc/nerdctl
#rm -f /usr/bin/seautil
#
#rm -f /etc/crictl.yaml
#rm -rf /etc/ld.so.conf.d/containerd.conf
##rm -rf /var/lib/containerd
#rm -rf /var/lib/nerdctl
##rm -rf /opt/containerd

