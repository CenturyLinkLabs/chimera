#! /bin/bash

echo $@ | logger

mkdir -p ~/chimera
cp -raf * ~/chimera/

#Install Docker
add-apt-repository -y "deb https://apt.dockerproject.org/repo ubuntu-trusty main"
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
apt-get update -y -qq
apt-get install -y docker-engine

#Create Swarm Token
token=$(docker run swarm:0.4.0 create)

#Deploy a temp log server to show progress during deployment.
docker run -d --name log_server -v /var/log/syslog:/log -p 80:80 centurylink/lighttpd:log 
echo "log_server" > /tmp/log_server_id

cmd="./admin.sh `echo $@` $token"
cd ~/chimera && nohup sh -c "eval $cmd | logger &"
