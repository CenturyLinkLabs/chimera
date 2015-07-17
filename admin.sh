#!/bin/bash

echo $#
if [[ "$#" != "3" ]]; then
  echo "You need to run the script with ./admin.sh <do api token> <admin host ip> <number of nodes>"
  exit 1;
fi

api_token=$1
admin_host_ip=$2
node_count=$3

apt-get -y -q install wget unzip curl

#Install Experiemental Docker
wget -qO- https://experimental.docker.com/ | sh

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
mv docker-compose-hydra.yml docker-compose.yml
docker-compose up -d
mv docker-compose.yml docker-compose-hydra.yml

#Create Swarm Token
export SWARM_TOKEN=$(docker run swarm create)
echo "SWARM_TOKEN=$SWARM_TOKEN" > .hydra_env

function join_swarm() {    
    #Join Cluster
    docker $(docker-machine config swarm-0) run -d \
        --restart="always" \
        --net="bridge" \
        swarm:latest join \
            --addr "$(docker-machine ip $1):2376" \
            "token://$SWARM_TOKEN"
}

sw_master="`cat /dev/urandom | tr -dc 'A-Z' | fold -w 6 | head -n 1`"
#Create Master
docker-machine --debug create \
    -d digitalocean \
    --digitalocean-access-token $api_token \
    --digitalocean-private-networking \
    --digitalocean-image="ubuntu-14-10-x64" \
    --engine-install-url="https://experimental.docker.com" \
    --engine-opt="kv-store=consul:$admin_host_ip:8500" \
    --engine-label="com.docker.network.driver.overlay.bind_interface=eth0" \
    $sw_master

join_swarm $sw_master

docker $(docker-machine config $sw_master) run -d \
    --restart="always" \
    --net="bridge" \
    -p "3376:3376" \
    -v "/etc/docker:/etc/docker" \
    swarm:latest manage \
        --tlsverify \
        --tlscacert="/etc/docker/ca.pem" \
        --tlscert="/etc/docker/server.pem" \
        --tlskey="/etc/docker/server-key.pem" \
        -H "tcp://0.0.0.0:3376" \
        --strategy spread \
        "token://$SWARM_TOKEN"
    
    
#Create Swarm Nodes and configure
prefix="`cat /dev/urandom | tr -dc 'a-z' | fold -w 6 | head -n 1`"
for i in $(seq 1 $node_count); do
    id=swarm-$i
    docker-machine --debug create \
        -d digitalocean \
        --digitalocean-access-token $api_token \
        --digitalocean-private-networking \
        --digitalocean-image="ubuntu-14-10-x64" \
        --engine-install-url="https://experimental.docker.com" \
        --engine-opt="kv-store=consul:$(docker-machine ip consul):8500" \
        --engine-label="com.docker.network.driver.overlay.bind_interface=eth0" \
        --engine-label="com.docker.network.driver.overlay.neighbor_ip=$(docker-machine ip $sw_master)" \
        $id

    join_swarm $id
done

#Switch to Swarm-master
eval "$(docker-machine env --swarm $sw_master)"

