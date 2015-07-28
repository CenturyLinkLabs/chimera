#!/bin/bash

set -e

ENV=".hydra_env"
admin_op=$1

function setEnvVar {
    local evn=`echo "$1" | sed 's/[PMX_]+//g'`
    echo $"`sed  "/$evn=/d" "$ENV"`" > "$ENV"
    echo export $1=$2 >> "$ENV"
    export $1=$2
}

function install_prometheus_agent() {
    eval "$(docker-machine env $1)"

    docker run -d --name PROM_CON_EXP \
        --restart=always \
        -p 9104:9104 \
        -v /sys/fs/cgroup:/cgroup \
        -v /var/run/docker.sock:/var/run/docker.sock \
        prom/container-exporter

    docker run -d --name PROM_NODE_EXP \
        --restart=always \
        -p 9100:9100 \
        --net="host" \
        prom/node-exporter

    eval "$(docker-machine env -u)"
    tmp_ip=$(docker-machine ip $id)
    cur=$(grep targets.*: prometheus.yml)
    new=$(echo $cur | sed s/]/", \'$tmp_ip:9100\', \'$tmp_ip:9104\']"/g)
    sed -i s/"-.*targets:.*]"/"$new"/g prometheus.yml
    sed -i s/"targets:.*\[,"/"targets: ["/g prometheus.yml
}

function deploy_swarm_node() {
    id=$1
    addl_flags=$2
    host_flags=""

    if [[ "$dm_host" == "do" ]]; then
        host_flags=" -d digitalocean --digitalocean-access-token $api_token --digitalocean-private-networking --digitalocean-image=\"ubuntu-14-04-x64\" "
    elif [[ "$dm_host" == "clc" ]]; then
        host_flags="-d centurylinkcloud --centurylinkcloud-group-id=$clc_gid --centurylinkcloud-private-address-only --centurylinkcloud-source-server-id=UBUNTU-14-64-TEMPLATE --centurylinkcloud-password=$clc_pwd --centurylinkcloud-username=$clc_uname "
    fi

    docker-machine --debug create \
        $host_flags \
        --swarm  $addl_flags \
	    --swarm-discovery token://$SWARM_TOKEN \
        $id

    install_prometheus_agent $id
}

function deploy_cluster() {
    apt-get -y -q install wget unzip curl
    touch $ENV

    #Install Docker
    wget -qO- https://get.docker.com/ | sh

    #Install Docker-Machine
    #curl -L https://github.com/docker/machine/releases/download/v0.3.0/docker-machine_linux-amd64 > /usr/local/bin/docker-machine
    #Installing custom docker machine built with clc integration
    cp bin/docker-machine_linux-amd64 /usr/local/bin/docker-machine
    chmod +x /usr/local/bin/docker-machine

    #Install Docker-Compose
    curl -L https://github.com/docker/compose/releases/download/1.3.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    #Cleanup old containers if there are any
    docker rm -f `docker ps -aq`
    docker-machine rm -f `docker-machine ls | awk '{print $1}'`

    #Create Swarm Token
    export SWARM_TOKEN=$(docker run swarm create)
    setEnvVar "SWARM_TOKEN" "$SWARM_TOKEN"

    SWARM_PREFIX="`cat /dev/urandom | tr -dc 'a-z' | fold -w 6 | head -n 1`"
    setEnvVar "SWARM_PREFIX" "$SWARM_PREFIX"
    sw_master="$SWARM_PREFIX-m"
    setEnvVar "SWARM_MASTER" "$sw_master"

    #Create Master
    deploy_swarm_node $sw_master " --swarm-master "

    #Create Swarm Nodes
    for i in $(seq 1 $node_count); do
        deploy_swarm_node "$SWARM_PREFIX-$i"
    done

    #Run Consul, Dray, Prometheus
    sed -i s/ADMIN_HOST_IP_ADDRESS/$admin_host_ip/g docker-compose-hydra.yml
    sed -i s/ADMIN_HOST_IP_ADDRESS/$admin_host_ip/g alertmanager.conf
    docker-compose -f docker-compose-hydra.yml up -d

    #Switch back to admin machine
    eval "$(docker-machine env -u)"

    #Start Hydra
    source $ENV && cd bin && ./hydrago &
}

function add_cluster_nodes() {
    #Create Swarm Nodes
    if [[ "$NODE_COUNT" == "" ]]; then
        NODE_COUNT=0
    fi
    for i in $(seq 1 $node_count); do
        deploy_swarm_node "$SWARM_PREFIX-$(($i+$NODE_COUNT))"
    done
    docker-compose -f docker-compose-hydra.yml up -d
}

if [[ "$admin_op" == "create" ]]; then
    if [[ "$#" == "5" ]]; then
        dm_host="do"
        api_token=$3
        admin_host_ip=$4
        node_count=$5

        deploy_cluster
        setEnvVar "NODE_COUNT" "$node_count"
        setEnvVar "SWARM_MASTER" "$sw_master"
        setEnvVar "APP_BASE_FOLDER" "$(pwd)/apps"
        setEnvVar "HYDRA_PORT" "8888"
        setEnvVar "PROVIDER" "$dm_host"
    elif [[ "$#" == "7" ]]; then
        dm_host="clc"
        clc_uname=$3
        clc_pwd=$4
        clc_gid=$5
        admin_host_ip=$6
        node_count=$7

        deploy_cluster
        setEnvVar "NODE_COUNT" "$node_count"
        setEnvVar "APP_BASE_FOLDER" "$(pwd)/apps"
        setEnvVar "HYDRA_PORT" "8888"
        setEnvVar "PROVIDER" "$dm_host"
    else
        echo -e "You need to run the admin script with \n\t./admin.sh create [--DO <DO api token> | --CLC <clc username> <clc password> <clc data center group ID>]  <admin host ip> <number of nodes>\n"
        exit 1;
    fi
elif [[ "$admin_op" == "add" ]]; then
    if [[ "$#" == "3" ]]; then
        api_token=$2
        node_count=$3
        source $ENV
        add_cluster_nodes
        setEnvVar "NODE_COUNT" "$(($node_count+$NODE_COUNT))"
        eval "$(docker-machine env -u)"
    else
        echo -e "You need to run the admin script with \n\t./admin.sh add [--DO <DO api token> | --CLC <clc username> <clc password> <clc data center group ID>]  <number of nodes>\n"
        exit 1;
    fi
else
    echo -e "You need to run the admin script with \n\t./admin.sh create  [--DO <DO api token> | --CLC <clc username> <clc password> <clc data center group ID>] <admin host ip> <number of nodes> \
                            \n\t OR ./admin.sh add [--DO <DO api token> | --CLC <clc username> <clc password> <clc data center group ID>] <number of nodes>\n"
    exit 1;
fi