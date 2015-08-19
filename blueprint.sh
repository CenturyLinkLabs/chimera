#! /bin/bash

echo $@ | logger

mkdir -p ~/chimera
cp -raf * ~/chimera/

#Install Docker
add-apt-repository -y "deb https://get.docker.com/ubuntu docker main"
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
apt-get update -y -qq
apt-get install -y lxc-docker-1.7.1 curl

#Create Swarm Token
token=$(docker run swarm:0.3.0 create)

#Deploy a temp log server to show progress during deployment.
docker run -d --name log_server -v /var/log/syslog:/log -p 80:80 centurylink/lighttpd:log 
echo "log_server" > /tmp/log_server_id

cmd="./admin.sh `echo $@` $token"
cd ~/chimera && nohup sh -c "eval $cmd | logger &"
