#!/usr/bin/env bash

apt-get -y install apache2-utils

for ((i=1;i<=1000;i++));
do
  ab -n 1000 -c 100 http://wordpress.wordpress.mysite.com:8010/ &
  sleep 10s
done;
