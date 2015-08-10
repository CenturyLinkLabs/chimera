#! /bin/bash

set -x

echo $@ | logger

mkdir -p ~/hydra
cp -raf * ~/hydra/

cmd="cd ~/hydra && ./admin.sh $@ | logger 2>&1 &"
echo $cmd | logger
eval "$cmd" &>/dev/null &disown;
