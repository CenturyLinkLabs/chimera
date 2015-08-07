#!/bin/bash

ENV=".hydra_env"
admin_op=$1
create_prompt="./admin.sh create [--CLC <clc username> <clc password> <clc data center group ID> <clc network id>| --DO <DO API token> ] <admin private IP> <number of minions>"
add_prompt="./admin.sh add [--CLC <clc username> <clc password> <clc data center group ID> | --DO <DO API token> ] <number of minions>"

function set_ev {
    local evn=$1
    sed  -i "/$evn=/d" "$ENV"
    echo "export $1=$2" >> "$ENV"
    export $1=$2
}

function cleanup_old_install() {
    if [[ "$(docker ps -aq)" != "" ]]; then
        docker rm -f `docker ps -aq`
    fi
    if [[ "$(docker-machine ls -q)" != "" ]]; then
        docker-machine rm -f `docker-machine ls -q`
    fi
    pkill hydrago
}

function install_prom_agent() {
    eval "$(docker-machine env $1)"
    nt="$2"

    docker run -d --name PROM_CON_EXP \
        --restart=always \
        -p 9104:9104 \
        -v /sys/fs/cgroup:/cgroup \
        -v /var/run/docker.sock:/var/run/docker.sock \
        prom/container-exporter

    eval "$(docker-machine env -u)"
    tmp_ip=$(docker-machine ip $id)
    cur=$(grep targets.*: prometheus.yml)
    if [[ "$nt" != "m" ]]; then
        new=$(echo $cur | sed s/]/", \'$tmp_ip:9104\']"/g)
    else
        new=$(echo $cur | sed s/]/", \'$tmp_ip:9104\', \'$tmp_ip:9101\' ]"/g)
    fi
    sed -i s/"-.*targets:.*]"/"$new"/g prometheus.yml
    sed -i s/"targets:.*\[,"/"targets: ["/g prometheus.yml
}

function deploy_swarm_node() {
    local id=$1
    local af=$2   #node type
    local clp=""

    if [[ "$dm_host" == "do" ]]; then
        clp=" -d digitalocean \
                --digitalocean-access-token $api_token \
                --digitalocean-private-networking \
                --digitalocean-image='ubuntu-14-04-x64' "
    elif [[ "$dm_host" == "clc" ]]; then
        clp=" -d centurylinkcloud \
                --centurylinkcloud-group-id=$clc_gid \
                --centurylinkcloud-private-address-only \
                --centurylinkcloud-source-server-id=UBUNTU-14-64-TEMPLATE \
                --centurylinkcloud-password='$clc_pwd' \
                --centurylinkcloud-username='$clc_uname' \
                --centurylinkcloud-network-id=$clc_nid "
    fi


    cmd="docker-machine --debug  \
             create $clp   \
            --swarm  $af \
            --swarm-discovery token://$SWARM_TOKEN  $id"

    eval $cmd

    install_prom_agent $id $nt
}

function deploy_cluster() {
    touch $ENV

    set_ev "NODE_COUNT" "$node_count"
    set_ev "APP_BASE_FOLDER" "$(pwd)/apps"
    set_ev "HYDRA_PORT" "8888"
    set_ev "PROVIDER" "$dm_host"

    apt-get -y -q install wget unzip curl

    #Install Docker
    wget -qO- https://get.docker.com/ | sh

    #Install Docker-Machine
    #curl -L https://github.com/docker/machine/releases/download/v0.3.0/docker-machine_linux-amd64 > /usr/local/bin/docker-machine
    #Installing custom docker machine built with clc integration
    cp bin/docker-machine_linux-amd64 /usr/local/bin/docker-machine
    chmod +x /usr/local/bin/docker-machine

    #Install Docker-Compose
    curl -L https://github.com/docker/compose/releases/download/1.3.1/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    #Cleanup old install/containers/docker-machine
    cleanup_old_install

    #Create Swarm Token
    SWARM_TOKEN=$(docker run swarm create)
    set_ev "SWARM_TOKEN" "$SWARM_TOKEN"

    SWARM_PREFIX="$(cat /dev/urandom | tr -dc 'a-z' | fold -w 4 | head -n 1)"
    set_ev "SWARM_PREFIX" "$SWARM_PREFIX"
    sw_master="swmstr"
    set_ev "SWARM_MASTER" "$sw_master"

    #Create Master
    deploy_swarm_node $sw_master " --swarm-master "

    #Create Swarm Minions
    for i in $(seq 1 $node_count); do
        deploy_swarm_node "$SWARM_PREFIX-$i" ""
    done

    #Switch back to admin machine
    eval "$(docker-machine env -u)"

    #Run Containers needed for cluster management
    sed -i s/ADMIN_HOST_IP_ADDRESS/$admin_host_ip/g docker-compose-hydra.yml
    sed -i s/ADMIN_HOST_IP_ADDRESS/$admin_host_ip/g alertmanager.conf
    docker-compose -f docker-compose-hydra.yml up -d

    #Start Hydra
    set_ev "LOG_LEVEL" "DEBUG"
    source $ENV && cd bin && ./hydrago >/dev/null 2>&1 &
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
    elif [[ "$#" == "8" ]]; then
        dm_host="clc"
        clc_uname="$3"
        clc_pwd="$4"
        clc_gid=$5
        clc_nid=$6
        admin_host_ip=$7
        node_count=$8

        deploy_cluster
    else
        echo -e "You need to run the admin script with \n\t$create_prompt\n"
        exit 1;
    fi
elif [[ "$admin_op" == "add" ]]; then
    if [[ "$#" == "3" ]]; then
        api_token=$2
        node_count=$3
        source $ENV
        add_cluster_nodes
        set_ev "NODE_COUNT" "$(($node_count+$NODE_COUNT))"
        eval "$(docker-machine env -u)"
    else
        echo -e "You need to run the admin script with \n\t$add_prompt\n"
        exit 1;
    fi
else
    echo -e "You need to run the admin script with \n\t$create_prompt \n\t OR $add_prompt\n"
    exit 1;
fi
