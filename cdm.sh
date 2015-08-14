#!/bin/bash
#set -x

ENV_SETTINGS_FILE=${HOME}/.hydra_env

function banner {
  echo "#####################################"
  echo "           Welcome to CDM!           "
  echo "                                     "
  echo " A simple utility to switch between  "
  echo " docker daemons in a swarm cluster.  "
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
    echo "   help,    -h - print this help text"
    echo "   version, -v - print the version"
    echo "   list,    ls - list all the swarm nodes"
    echo "   connect, co - switch swarm node"
    echo "     options:"
    echo "            -l - to local, "
    echo "           -sm - to swarm master, " 
    echo "            -n - to node 'm' or <number>"
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
  elif [ "$1" == "connect" ] || [ "$1" == "co" ]; then
    connect $1 $2 $3
    exit
  elif [ "$1" == "list" ] || [ "$1" == "ls" ]; then
    list
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
      echo "Switching to docker daemon on master '$SWARM_MASTER' ..."
      eval "$(docker-machine env --swarm $SWARM_MASTER)"
    elif [ "$2" == "-n" ]; then
      if [ "$3" == "m" ]; then
        echo "Switching to docker daemon on node '$SWARM_MASTER' ..."
        eval "$(docker-machine env $SWARM_MASTER)"
      elif [ -z "$3" ] || ([ "$3" != "m" ] && ([ "$3" -gt "$NODE_COUNT" ] || [ "$3" -le 0 ])); then
        echo "Invalid node number, switching to docker daemon on node '$SWARM_MASTER' ..."
        eval "$(docker-machine env $SWARM_MASTER)"
      else
        echo "Switching to node '$SWARM_PREFIX-$3' ..."
        eval "$(docker-machine env $SWARM_PREFIX-$3)"
      fi
    elif [ "$2" == "-l" ]; then
      echo "Switching to local..."
      eval "$(docker-machine env -u)"
    fi
    # show a warning message to exit the subshell
    msg
    # this hack sets the envs in a new shell
    exec $SHELL -i
  fi  
}

function list {
  # list all swarm nodes
  echo "Listing all swarm nodes..."
  echo 
  docker-machine ls
}

function msg {
  # if [ "$SHLVL" -gt 2 ]; then
    echo
    echo "Sub-Shell Level: $SHLVL created."
    echo "** Please exit the current Sub-Shell $SHLVL before running the next 'connect' command. **"
    echo
  # fi  
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
if  [ -f "$ENV_SETTINGS_FILE" ]; then
  source $ENV_SETTINGS_FILE
else
  echo "Chimera environment settings are not set."
  exit
fi  

# call the function
ctl_dm_helper $1 $2 $3
