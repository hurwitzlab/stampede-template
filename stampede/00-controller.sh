#!/bin/bash

set -u

#
# These arguments are what you need from the user
#
ARG1=""
ARG2="1"

#
# These arguments pertain to running the pipeline
#
PARTITION="normal" 
TIME="24:00:00"
GROUP="iPlant-Collabs"
RUN_STEP=""
MAIL_USER=""
MAIL_TYPE="BEGIN,END,FAIL"

#
# Function to print nicely formatted usage statement
#
function HELP() {
  printf "Usage:\n  %s -a ARG1 -b ARG2\n\n" $(basename $0)

  echo "Required arguments:"
  echo " -a ARG1"
  echo ""
  echo "Options (default in parentheses):"
  echo " -b ARG2 ($ARG2)"
  echo ""
  exit 0
}

#
# Print help if run with no arguments
#
if [[ $# -eq 0 ]]; then
  HELP
fi

function GET_ALT_ENV() {
  env | grep $1 | sed "s/.*=//"
}

#
# Get the arguments/options from the command line
#
while getopts :a:b:g:p:r:t:h OPT; do
  case $OPT in
    #
    # Put your arguments here, be sure to change "a," "b," etc. in "getopts"
    #
    a)
      ARG1="$OPTARG"
      ;;
    b)
      ARG2="$OPTARG"
      ;;

    #
    # These arguments are for how to run
    #
    g)
      GROUP="$OPTARG"
      ;;
    h)
      HELP
      ;;
    p)
      PARTITION="$OPTARG"
      ;;
    r)
      RUN_STEP="$OPTARG"
      ;;
    t)
      TIME="$OPTARG"
      ;;
    :)
      echo "Error: Option -$OPTARG requires an argument."
      exit 1
      ;;
    \?)
      echo "Error: Invalid option: -${OPTARG:-""}"
      exit 1
  esac
done

#
# Check args, e.g., that they have some value or point to 
# files/dirs that actually exist.
#
if [[ ${#ARG1} -lt 1 ]]; then
  echo "Error: No ARG1 specified."
  exit 1
fi

#
# All the arguments will now be written to a config file
# to share with the sub-processes. $$ is the process ID.
# Be sure to "export" any of your arguments you need passed
# to the other scripts.
#
CONFIG=$$.conf
CWD=$(pwd)
echo "export PATH=$PATH:$CWD/bin"  > $CONFIG
echo "export ARG1=$ARG1"          >> $CONFIG
echo "export ARG2=$ARG2"          >> $CONFIG

#
# These are just to let the user know how everything was
# interpreted / run.
#
echo "Run parameters:"
echo "CONFIG      $CONFIG"
echo "ARG1        $ARG1"
echo "ARG2        $ARG2"
echo "TIME        $TIME"
echo "PARTITION   $PARTITION"
echo "GROUP       $GROUP"
echo "RUN_STEP    ${RUN_STEP:-NA}"

#
# You probably don't need/want to change anything from here on.
#
PREV_JOB_ID=0
i=0

for STEP in $(ls 0[1-9]*.sh); do
  let i++

  if [[ ${#RUN_STEP} -gt 0 ]] && [[ $(basename $STEP) != $RUN_STEP ]]; then
    continue
  fi

  #
  # Allow overrides for each job in config
  #
  THIS_PARTITION=$PARTITION

  ALT_PARTITION=$(GET_ALT_ENV "OPT_PARTITION_${i}")
  if [[ ${#ALT_PARTITION} -gt 0 ]]; then
    THIS_PARTITION=$ALT_PARTITION
  fi

  THIS_TIME=$TIME

  ALT_TIME=$(GET_ALT_ENV "OPT_TIME${i}")
  if [[ ${#ALT_TIME} -gt 0 ]]; then
    THIS_TIME=$ALT_TIME
  fi

  STEP_NAME=$(basename $STEP '.sh')
  STEP_NAME=$(echo $STEP_NAME | sed "s/.*-//")
  ARGS="-p $THIS_PARTITION -t $THIS_TIME -A $GROUP -N 1 -n 1 -J $STEP_NAME"

  if [[ ${#MAIL_USER} -gt 0 ]]; then
    ARGS="$ARGS --mail-user=$MAIL_USER --mail-type=$MAIL_TYPE"
  fi

  if [[ $PREV_JOB_ID -gt 0 ]]; then
    ARGS="$ARGS --dependency=afterok:$PREV_JOB_ID"
  fi

  CMD="sbatch $ARGS ./$STEP $CONFIG"
  JOB_ID=$($CMD | egrep -e "^Submitted batch job [0-9]+$" | awk '{print $NF}')

  if [[ $JOB_ID -lt 1 ]]; then 
    echo Failed to get JOB_ID from \"$CMD\"
    exit 1
  fi
  
  printf "%3d: %s [%s]\n" $i $STEP $JOB_ID

  PREV_JOB_ID=$JOB_ID
done

echo Done.
