#! /bin/bash

set -x

mkdir -p ~/hydra
cp -raf * ~/hydra/

ENV="~/hydra/.hydra_env"

echo "$@" | logger

apt-get -y install curl
curl -sSL https://get.docker.com/ubuntu/ | sed -r 's/^apt-get install -y lxc-docker$/apt-get install -y lxc-docker-1.7.1/g'  | sh

function set_ev {
    local evn=$1
    sed  -i "/$evn=/d" "$ENV"
    echo "export $1=$2" >> "$ENV"
    export $1=$2
}


#Create Swarm Token
SWARM_TOKEN=$(sudo docker run swarm:0.3.0 create)
echo SWARM TOKEN $SWARM_TOKEN | logger
set_ev "SWARM_TOKEN" "$SWARM_TOKEN"


cmd="./admin.sh `echo $@`"
cd ~/hydra && nohup sh -c "eval $cmd | logger &"
