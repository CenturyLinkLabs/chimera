#! /bin/bash

set -x

cd ../ && rm -f install_chimera.zip && zip -9 -r install_chimera.zip * -x \*.git\* \*chimerago/\* \*.zip\* \*Dockerfile\* *\.DS\* \*.package.manifest\* && cd -
#cd ../ && rm -f install_swarm.zip && cp swarm.package.manifest package.manifest && zip -9 -r install_swarm.zip * -x \*.git\* \*chimerago/\* \*.zip\* \*Dockerfile\* *\.DS\* \*.package.manifest\* && rm package.manifest && cd -

