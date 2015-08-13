#!/bin/bash
#set -x

ENV_SETTINGS_FILE=${HOME}/.hydra_env
TEMP_FILE=${HOME}/.hydra_temp_env

function banner {
  echo "#####################################"
  echo "           Welcome to CDM!           "
  echo "                                     "
  echo " A simple utility to switch Chimera  "
  echo " swarm nodes with docker-machine     "
  echo "#####################################"
  echo
}

function version {
  echo "Version: 0.1"
}

function help {
    # help
    banner
    version
    echo "---------------------------------------------------------------------"
    echo "Help:"
    echo "   help, -h    - print this help text"
    echo "   version, -v - print the version"
    echo "   switch      - switch nodes"
    echo "            -l - to local docker daemon, "
    echo "           -sm - to swarm master, " 
    echo "            -n - to node 'm' or <number>"
    echo "   show        - list all the nodes"
    echo "---------------------------------------------------------------------"
}

function ctl_dm_helper {
  # commands switch
  if [ -z "$1" ] || [ "$1" == "help" ] || [ "$1" == "-h" ]; then
    help
    exit
  elif [ "$1" == "version" ] || [ "$1" == "-v" ]; then
    version
    exit
  elif [ "$1" == "switch" ]; then
    connect $1 $2 $3
    exit
  elif [ "$1" == "show" ]; then
    show
    exit
  else
    echo "Invalid command. Use 'cdm help' for usage."
  fi
}

function connect {
  # valid params: local, master, slave <no>

  if [ -z "$2" ] || ([ "$2" != "-l" ] && [ "$2" != "-sm" ] && [ "$2" != "-n" ]) ; then
    echo "Options: '-l', '-sm' or '-n'"
    exit
  else  
    if [ "$2" == "-sm" ]; then
      echo "Switching to master '$SWARM_MASTER' ..."
      #eval "$(docker-machine env --swarm $SWARM_MASTER)"
      docker-machine env --swarm $SWARM_MASTER > $TEMP_FILE
      source $TEMP_FILE
      # set_prompt $SWARM_MASTER
      exit
    elif [ "$2" == "-n" ]; then
      if [ -z "$3" ] || ([ "$3" != "m" ] && [ "$3" -gt "$NODE_COUNT" ]); then
        echo "Invalid node number, switching to node '$SWARM_MASTER' ..."
        eval "$(docker-machine env $SWARM_MASTER)"
        # set_prompt $SWARM_PREFIX-1
        exit
      else
        echo "Switching to node '$SWARM_PREFIX-$3' ..."
        eval "$(docker-machine env $SWARM_PREFIX-$3)"
        # set_prompt $SWARM_PREFIX-$3
        exit
      fi
    elif [ "$2" == "-l" ]; then
      echo "Switching to local..."
      eval "$(docker-machine env -u)"
      # reset_prompt
      exit
    fi
  fi  
}

function show {
  # list all swarm nodes
  echo "Listing all swarm nodes..."
  echo 
  docker-machine ls
}

# function set_prompt {
#   # reset prompt
#   if [ "$ORIG_PS" != "" ]; then
#     reset_prompt
#   fi  

#   local prompt=$1
# #  set_ev ORIG_PS "$PROMPT"
#   echo "export ORIG_PS=\"$PROMPT\"" >> "${HOME}/.zshrc"
# #  set_ev PROMPT "$ORIG_PS [$prompt]"
#   echo "export PROMPT=\"$ORIG_PS [$prompt]\"" >> "${HOME}/.zshrc"
#   source "${HOME}/.zshrc"
# }

# function reset_prompt {
# #  set_ev PROMPT $ORIG_PS
#   echo "export PROMPT=\"$ORIG_PS\"" >> "${HOME}/.zshrc"
#   source "${HOME}/.zshrc"
# }

# function set_ev {
#     local evn=$1
   
#     echo $"`sed  "/$evn=/d" "$ENV_SETTINGS_FILE"`" > "$ENV_SETTINGS_FILE"

#     echo "export $1=\"$2\"" >> "$ENV_SETTINGS_FILE"
#     export $1="$2"
#     source $ENV_SETTINGS_FILE
# }

########################
# set envs
touch $TEMP_FILE
if  [ -f "$ENV_SETTINGS_FILE" ]; then
  source $ENV_SETTINGS_FILE
else
  echo "Chimera environment settings are not set."
  exit
fi  

# call the function
ctl_dm_helper $1 $2 $3
