#!/bin/bash

#------------------------------------------------------------------------------------
# Program:
#   1. install containerd/containerd-shim/runc/nerdctl/crictl/ctr/cni ... etc.
#   2. install containerd.service
#   3. install config.toml
# History:
#   2021/06/10  muze.gxc    First release
#   2021/06/28  muze.gxc    bugfix: fix the case that containerd exists
#   2021/07/12  muze.gxc    bugfix: add the cgroup driver choice to the config.toml
#   2022/07/22  DanteCui    move into ack-distro
#------------------------------------------------------------------------------------

# shellcheck disable=SC2046
# shellcheck disable=SC2006
scripts_path=$(cd `dirname "$0"`; pwd)

set -e;set -x
echo "this is containerd.sh -----------------------------"

disable_selinux() {
  if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
  fi
}

# get params
storage=${ContainerDataRoot:-/var/lib/containerd} # containerd default uses /var/lib/containerd
mkdir -p "$storage"

# Begin install containerd
if ! containerd --version; then
  lsb_dist=$(sed -n 's/^ID=//p' /etc/os-release)
  lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
  echo "current system is ${lsb_dist}"

  # containerd bin、crictl bin、ctr bin、nerdctr bin、cni plugin etc
  tar -zxvf "${scripts_path}"/../cri/docker.tar.gz -C /
  chmod a+x /usr/local/bin
  chmod a+x /usr/local/sbin

  case "${lsb_dist}" in
  ubuntu | deepin | debian | raspbian)
    cp -f "${scripts_path}"/../etc/containerd.service /etc/systemd/system/containerd.service
    if [ ! -f /usr/sbin/iptables ];then
      if [ -f /sbin/iptables ];then
        ln -s /sbin/iptables /usr/sbin/iptables
      else
        echo "iptables not found, please check"
        exit 1
      fi
    fi
    ;;
  centos | rhel | anolis | ol | sles | kylin | neokylin)
    RPM_DIR=${scripts_path}/../rpm/
    rpm=libseccomp
    if ! rpm -qa | grep ${rpm};then
      rpm -ivh --force --nodeps "${RPM_DIR}"/${rpm}*.rpm
    fi
    cp -f "${scripts_path}"/../etc/containerd.service /etc/systemd/system/containerd.service
    ;;
  alios)
    docker0=$(ip addr show docker0 | head -1|tr " " "\n"|grep "<"|grep -iwo "UP"|wc -l)
    if [ "$docker0" != "1" ]; then
        ip link add name docker0 type bridge
        ip addr add dev docker0 172.17.0.1/16
    fi
    RPM_DIR=${scripts_path}/../rpm/
    rpm=libseccomp
    if ! rpm -qa | grep ${rpm};then
      rpm -ivh --force --nodeps "${RPM_DIR}"/${rpm}*.rpm
    fi
    cp -f "${scripts_path}"/../etc/containerd.service /etc/systemd/system/containerd.service
    ;;
  *)
    utils_error "unknown system to use /etc/systemd/system/containerd.service"
    cp -f "${scripts_path}"/../etc/containerd.service /etc/systemd/system/containerd.service
    ;;
  esac
fi

echo "install /etc/containerd/config.toml"
mkdir -p /etc/containerd
cp -f "${scripts_path}"/../etc/dump-config.toml /etc/containerd/config.toml

if [ -f "${scripts_path}/../etc/nerdctl.toml" ];then
  mkdir -p /etc/nerdctl
  cp -f "${scripts_path}/../etc/nerdctl.toml" /etc/nerdctl/nerdctl.toml
fi

if command -v crictl >/dev/null 2>&1; then
  crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
fi

# disable_selinux
systemctl daemon-reload
systemctl enable containerd.service
systemctl restart containerd.service