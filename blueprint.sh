#! /bin/bash

set -x

sudo su
mkdir -p ~/hydra
cp -ra * ~/hydra/
cd ~/hydra && ./admin.sh "$@" >/dev/null 2>&1 &

exit 0;
