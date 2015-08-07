#!/bin/bash

#Get swarm master IP address
source .hydra_env

mstr_ip=$(docker-machine ip $SWARM_MASTER) 
sed -i s/SWARM_MASTER_IP_ADDRES/$mstr_ip/g docker-compose-hydra.yml
sed -i s/SWARM_MASTER_IP_ADDRES/$mstr_ip/g apps/app1/docker-compose.yml
echo -e "\n $mstr_ip wordpress.wordpress.mysite.com"

docker run -d -p 8080:9101 --add-host wordpress.wordpress.mysite.com:$mstr_ip prom/haproxy-exporter -haproxy.scrape-uri="http://stats:interlock@wordpress.wordpress.mysite.com:8010/haproxy?stats;csv" -haproxy.server-metric-fields="1,2,3,4,7,12"
