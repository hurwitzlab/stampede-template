#!/bin/bash

set -u

# 
# Argument defaults
# 
BIN="$( readlink -f -- "${0%/*}" )"
if [ -f $BIN ]; then
  BIN=$(dirname $BIN)
fi

ARG1=""
ARG2=""
WORK_DIR=$BIN

#
# Functions
#
function lc() {
  wc -l $1 | cut -d ' ' -f 1
}

function HELP() {
  printf "Usage:\n  %s -a ARG1 -b ARG2\n\n" $(basename $0)

  echo "Required Arguments:"
  echo " -a ARG1"
  echo " -b ARG2"
  echo
  exit 0
}

if [[ $# == 0 ]]; then
  HELP
fi

#
# Setup
#
PROG=$(basename "$0" ".sh")
LOG="$BIN/launcher-$PROG.log"
PARAMS_FILE="$BIN/${PROG}.params"

if [[ -e $LOG ]]; then
  rm $LOG
fi

if [[ -e $PARAMS_FILE ]]; then
  echo Removing previous PARAMS_FILE \"$PARAMS_FILE\" >> $LOG
  rm $PARAMS_FILE
fi

echo $BAR >> $LOG
echo "Invocation: $0 $@" >> $LOG

#
# Get args
#
while getopts :a:b:w:h OPT; do
  case $OPT in
    a)
      ARG1="$OPTARG"
      ;;
    b)
      ARG2="$OPTARG"
      ;;
    h)
      HELP
      ;;
    w)
      WORK_DIR="$OPTARG"
      ;;
    :)
      echo "Error: Option -$OPTARG requires an argument." >> $LOG
      exit 1
      ;;
    \?)
      echo "Error: Invalid option: -${OPTARG:-""}" >> $LOG
      exit 1
  esac
done

#
# Check args
#
if [[ ${#ARG1} -lt 1 ]]; then
  echo "Error: No ARG1 specified." >> $LOG
  exit 1
fi

if [[ ${#ARG2} -lt 1 ]]; then
  echo "Error: No ARG2 specified." >> $LOG
  exit 1
fi

# 
# Find input files
# 
FILES_LIST=$(mktemp)
find $ARG1 -type f > $FILES_LIST
NUM_FILES=$(lc $FILES_LIST)

if [ $NUM_FILES -lt 1 ]; then
  echo "Error: Found no files in FASTA_DIR \"$FASTA_DIR\"" >> $LOG
  exit 1
fi

echo $BAR                      >> $LOG
echo Settings for run:         >> $LOG
echo "ARG1             $ARG1"  >> $LOG
echo "ARG2             $ARG2"  >> $LOG
echo "Will process $NUM_FILES files" >> $LOG
cat -n $FILES_LIST >> $LOG

i=0
while read FILE; do
  let i++
  BASENAME=$(basename $FILE)
  OUT_FILE=$OUT_DIR/$BASENAME 

  printf "%3d: %s\n" $i $BASENAME >> $LOG

  echo "wc -l $FILE" >> $PARAMS_FILE
done < $FILES_LIST

NUM_JOBS=$(lc $PARAMS_FILE)

if [[ $NUM_JOBS -gt 0 ]]; then
  echo "Submitting \"$NUM_JOBS\" jobs" >> $LOG

  export TACC_LAUNCHER_NPHI=0
  export TACC_LAUNCHER_PPN=2
  export EXECUTABLE=$TACC_LAUNCHER_DIR/init_launcher
  export WORKDIR=$BIN
  export TACC_LAUNCHER_SCHED=interleaved

  echo "Starting parallel job..." >> $LOG
  echo $(date) >> $LOG
  $TACC_LAUNCHER_DIR/paramrun SLURM $EXECUTABLE $WORKDIR $PARAMS_FILE
  echo $(date) >> $LOG
  echo "Done" >> $LOG
else
  echo "Error: No jobs to submit." >> $LOG
fi

echo Done.
