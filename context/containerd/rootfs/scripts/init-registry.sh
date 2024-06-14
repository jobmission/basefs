#!/bin/bash
# Copyright © 2021 Alibaba Group Holding Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -x
echo "this is init-registry.sh -----------------------------"

# prepare registry storage as directory
# shellcheck disable=SC2046
cd $(dirname "$0")

# shellcheck disable=SC2034
REGISTRY_PORT=${1-5000}
VOLUME=${2-/var/lib/registry}
REGISTRY_DOMAIN=${3-sea.hub}

container=sealer-registry
rootfs=$(dirname "$(pwd)")
config="$rootfs/etc/registry_config.yml"
htpasswd="$rootfs/etc/registry_htpasswd"
certs_dir="$rootfs/certs"
image_dir="$rootfs/images"

echo "VOLUME value : $VOLUME"

mkdir -p "$VOLUME" || true

# shellcheck disable=SC2106
startRegistry() {
    n=1
    while (( n <= 3 ))
    do
        echo "attempt to start registry"
        (ctr task start $container && break) || (( n < 3))
        (( n++ ))
        sleep 3
    done
}

load_images() {
for image in "$image_dir"/*
do
 if [ -f "${image}" ]
 then
  ctr image import "${image}"
 fi
done
}

check_registry() {
    n=1
    while (( n <= 3 ))
    do
        registry_status=$(ctr tasks ls | grep $container | awk '{print $3}')
        if [[ "$registry_status" == "RUNNING" ]]; then
            break
        fi
        if [[ $n -eq 3 ]]; then
           echo "sealer-registry is not running, status: $registry_status"
           exit 1
        fi
        (( n++ ))
        sleep 3
    done
}

load_images

## rm container if exist.
if [ "$(ctr containers list | grep $container)" ]; then
    ctr tasks kill -s SIGKILL $container
    ctr containers delete $container
fi

regArgs="--detach
         --net-host  \
         --mount type=bind,src=$certs_dir,dst=/certs,options=rbind:rw \
         --mount type=bind,src=$VOLUME,dst=/var/lib/registry,options=rbind:rw \
         --env REGISTRY_HTTP_TLS_CERTIFICATE=/certs/$REGISTRY_DOMAIN.crt \
         --env REGISTRY_HTTP_TLS_KEY=/certs/$REGISTRY_DOMAIN.key \
         --env REGISTRY_HTTP_DEBUG_ADDR=0.0.0.0:5002 \
         --env REGISTRY_HTTP_DEBUG_PROMETHEUS_ENABLED=true"

# shellcheck disable=SC2086
if [ -f $config ]; then
    sed -i "s/5000/$1/g" $config
    regArgs="$regArgs \
    --mount type=bind,src=$config,dst=/etc/docker/registry/config.yml,options=rbind:rw"
fi
echo "regArgs: $regArgs"
# shellcheck disable=SC2086
if [ -f $htpasswd ]; then
    ctr run $regArgs \
            -v $htpasswd:/htpasswd \
            -e REGISTRY_AUTH=htpasswd \
            -e REGISTRY_AUTH_HTPASSWD_PATH=/htpasswd \
            -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" docker.io/library/registry:2.7.1 $container || startRegistry
else
    ctr run $regArgs docker.io/library/registry:2.7.1 $container || startRegistry
fi

check_registry