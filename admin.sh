#!/bin/bash

echo $#
if [[ "$#" != "3" ]]; then
  echo "You need to run the script with ./admin.sh <DO api token> <admin host ip> <number of nodes>"
  exit 1;
fi

api_token=$1
admin_host_ip=$2
node_count=$3

apt-get -y -q install wget unzip curl

#Install Docker
wget -qO- https://get.docker.com/ | sh

#Install Docker-Machine
curl -L https://github.com/docker/machine/releases/download/v0.3.0/docker-machine_linux-amd64 > /usr/local/bin/docker-machine
chmod +x /usr/local/bin/docker-machine

#Install Docker-Compose
curl -L https://github.com/docker/compose/releases/download/1.3.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#Cleanup old containers if there are any
docker rm -f `docker ps -aq`
docker-machine rm -f `docker-machine ls | awk '{print $1}'`

#Run Consul, Dray, Prometheus
docker-compose up -d docker-compose-hydra.yml

#Create Swarm Token
export SWARM_TOKEN=$(docker run swarm create)
echo "SWARM_TOKEN=$SWARM_TOKEN" > .hydra_env

sw_master="`cat /dev/urandom | tr -dc 'A-Z' | fold -w 6 | head -n 1`"

#Create Master
docker-machine --debug create \
  --driver digitalocean \
  --digitalocean-access-token $api_token \
  --digitalocean-private-networking \
  --digitalocean-image="ubuntu-14-10-x64" \
  --swarm \
  --swarm-master \
  --swarm-discovery token://$SWARM_TOKEN \
  --engine-opt="kv-store=consul:$admin_host_ip:8500" \
  $sw_master

#Create Swarm Nodes
prefix="`cat /dev/urandom | tr -dc 'a-z' | fold -w 6 | head -n 1`"
for i in $(seq 1 $node_count); do
    id=$prefix-$i
    docker-machine --debug create \
        -d digitalocean \
        --digitalocean-access-token $api_token \
        --digitalocean-private-networking \
        --digitalocean-image="ubuntu-14-10-x64" \
        --swarm \
	    --swarm-discovery token://$SWARM_TOKEN \
        --engine-opt="kv-store=consul:$admin_host_ip:8500" \
        $id
done

#Switch to Swarm-master
eval "$(docker-machine env --swarm $sw_master)"

