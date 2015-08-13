#! /bin/bash

set -x

mkdir -p ~/hydra
cp -raf * ~/hydra/

#Install Docker
add-apt-repository -y "deb https://get.docker.com/ubuntu docker main"
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
apt-get update -y -qq
apt-get install -y lxc-docker-1.7.1 curl

#Create Swarm Token
docker run swarm:0.3.0 create > /tmp/swarm_token


echo "$@" | logger

cmd="./admin.sh `echo $@`"
cd ~/hydra && nohup sh -c "eval $cmd | logger &"
