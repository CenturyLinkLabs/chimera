#!/bin/bash

ssh_key_id=799968
image_id=ubuntu-15-04-x64
DIGITALOCEAN_ACCESS_TOKEN=2ff42ab42473b85b30b43048568d81cffff53a42d2fd221246d3433b5c15dc54
admin_machine_name=hydra_head
dc_tag=nyc3
node_count=2

curl -X POST "https://api.digitalocean.com/v2/droplets" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_ACCESS_TOKEN" \
    -d {"region":"nyc3", "image":"`echo $image_id`", "size":"512mb", "private_networking": true, "user_data":"''", "name":"`echo $admin_machine_name`", "ssh_keys":[`echo $ssh_key_id`]}'

curl  -X GET https://api.digitalocean.com/v2/droplets/6147346   \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_ACCESS_TOKEN"

get ip address & run admin script with DIGITALOCEAN_ACCESS_TOKEN $admin_ip $node_count 

