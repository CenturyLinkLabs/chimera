#!/bin/bash
set -x

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

#Create Swarm Token
export SWARM_TOKEN=$(docker run swarm create)
echo "SWARM_TOKEN=$SWARM_TOKEN" > .hydra_env

prefix="`cat /dev/urandom | tr -dc 'a-z' | fold -w 6 | head -n 1`"
echo "SWARM_PREFIX=$prefix" >> .hydra_env
sw_master="$prefix-m"

function install_prometheus_agent() {
    eval "$(docker-machine env $1)"

    docker run -d --name PROM_CON_EXP \
        --restart=always \
        -p 9104:9104 \
        -v /sys/fs/cgroup:/cgroup \
        -v /var/run/docker.sock:/var/run/docker.sock \
        prom/container-exporter

    docker run -d --name PROM_NODE_EXP \
        --resart=always \
        -p 9100:9100 \
        --net="host" \
        prom/node-exporter

    eval "$(docker-machine env -u)"
}

#Create Master
docker-machine --debug create \
  --driver digitalocean \
  --digitalocean-access-token $api_token \
  --digitalocean-private-networking \
  --digitalocean-image="ubuntu-14-10-x64" \
  --swarm \
  --swarm-master \
  --swarm-discovery token://$SWARM_TOKEN \
  $sw_master

install_prometheus_agent $sw_master
machine_ips="'$(docker-machine ip $sw_master):9104', '$(docker-machine ip $sw_master):9100  '"

#Create Swarm Nodes
for i in $(seq 1 $node_count); do
    id="$prefix-$i"
    docker-machine --debug create \
        -d digitalocean \
        --digitalocean-access-token $api_token \
        --digitalocean-private-networking \
        --digitalocean-image="ubuntu-14-10-x64" \
        --swarm \
	    --swarm-discovery token://$SWARM_TOKEN \
        $id

    install_prometheus_agent $id
    machine_ips="$machine_ips, '$(docker-machine ip $id):9104', '$(docker-machine ip $id):9100'"
done

#Switch back to admin machine
eval "$(docker-machine env -u)"

#Run Consul, Dray, Prometheus
sed -i s/ADMIN_HOST_IP_ADDRESS/$admin_host_ip/g docker-compose-hydra.yml
sed -i s/TARGET_HOST_IP_ADDRESSES/"$machine_ips"/g prometheus.yml
docker-compose -f docker-compose-hydra.yml up -d






