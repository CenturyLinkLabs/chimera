#! /bin/bash

set -x

mkdir -p ~/hydra
cp -raf * ~/hydra/
cd ~/hydra 
./admin.sh $@ >/dev/null 2>&1 &

exit 0;
