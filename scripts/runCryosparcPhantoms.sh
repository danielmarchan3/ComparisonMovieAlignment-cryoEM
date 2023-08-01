#!/bin/bash

[ -z "$MACHINE" ] && echo "Machine name dir not set (export MACHINE)" && exit # export MACHINE=galileoShadow
[ -z "$CRYOSPARC_PATH" ] && echo "Path to cryosparc script not set (export CRYOSPARC_PATH)" && exit # i.e. export CRYOSPARC_PATH=/usr/local/cryosparc3/cryosparc_master/bin/cryosparcm
[ -z "$CRYOSPARC_PYTHON_PATH" ] && echo "Path to cryosparc python script not set (export CRYOSPARC_PATH)" && exit # i.e. export CRYOSPARC_PYTHON_PATH='python3 /home/user/ComparisonMovieAlignment-cryoEM/scripts/cryosparc_patch_motion_correction.py'
[ -z "$XMIPP_PATH" ] && echo "Xmipp dir not set (export XMIPP_PATH)" && exit # i.e. export XMIPP_PATH=/home/user/scipion3/xmipp-bundle

source $XMIPP_PATH/build/xmipp.bashrc

set -x # show commands

PARENT_DIR="$(dirname "$(dirname "$(readlink -fm "$0")")")"
MOVIE_DIR=$PARENT_DIR/phantom_movies
RESULT_DIR=$PARENT_DIR/$MACHINE/phantom_movies
SCRIPT=`basename "$0"`
LOG=${SCRIPT/.sh/.log}
LOG="$(dirname $RESULT_DIR)"/$LOG

mkdir -p $RESULT_DIR # to be able to store the log

#start logging
(

# log version
$CRYOSPARC_PATH cli 'get_running_version()'

# measure runtime / get data for quality (noise)
#: <<'END'
for mic in $MOVIE_DIR/noisy/*.mrc; do
	filename=$(basename -- "$mic")
	DEST=$RESULT_DIR/noisy/runtime
	mkdir -p $DEST
	avg=cryosparc_${filename/.mrc/_avg.mrc}
	gain=$(dirname $mic)/gain/$filename
	for (( i=0; i<10; i++ ))
	do
		echo runtime - filename: $filename
#		time $CRYOSPARC_PYTHON_PATH --InTiff $mic --OutMrc $DEST/$avg --Gain $gain --RotGain 0 --PixSize 0.745 --kV 200 --CSmm 2.7 --TotalDose 50.56 --GpuNum 1 # -Dark $dark
	  $CRYOSPARC_PYTHON_PATH --InTiff $mic --OutMrc $DEST/$avg --Gain $gain --RotGain 0 --PixSize 1 --kV 200 --CSmm 2.7 --TotalDose 50.56 --GpuNum 1
	done
done
#END


# get data for quality (noiseless)
#: <<'END'
for mic in $MOVIE_DIR/pristine/*.mrc; do
	filename=$(basename -- "$mic")
	DEST=$RESULT_DIR/pristine/runtime
	mkdir -p $DEST
	avg=cryosparc_${filename/.mrc/_avg.mrc}
	gain=$(dirname $mic)/gain/$filename
	$CRYOSPARC_PYTHON_PATH --InTiff $mic --OutMrc $DEST/$avg --Gain $gain --RotGain 0 --PixSize 1 --kV 200 --CSmm 2.7 --TotalDose 50.56 --GpuNum 1
done
#END


# get data for quality (shift)
#: <<'END'
declare -a SHIFTS=("pristine" "noisy")
for DIR in "${SHIFTS[@]}"; do
	for mic in $MOVIE_DIR/$DIR/shift/*.mrc; do
		filename=$(basename -- "$mic")
		DEST=$RESULT_DIR/$DIR/runtime
		mkdir -p $DEST
		avg=cryosparc_${filename/.mrc/_avg.mrc}
		gain=$(dirname $mic)/gain/$filename
		$CRYOSPARC_PYTHON_PATH --InTiff $mic --OutMrc $DEST/$avg --Gain $gain --RotGain 0 --PixSize 1 --kV 200 --CSmm 2.7 --TotalDose 50.56 --GpuNum 1
	done
done
#END

# measure runtime in parallel execution
#: <<'END'
noOfGpus=$(nvidia-smi -L | wc -l)
tmpDir=$MOVIE_DIR/noisy/tmp

for (( gpus=2; gpus<=$noOfGpus; gpus++ )); do
  for mic in $MOVIE_DIR/noisy/*.mrc; do
    mkdir $tmpDir
    #CREATE THE DATASET
    for (( g=1; g<=$gpus; g++)); do # create 'unique' test data
      copy=${mic/.mrc/_$g.mrc}
      f="$(basename -- $copy)"
      cp $mic $tmpDir/$f
    done
    #PROCESS DATA
    filename="$(basename -- $mic)"
    DEST=$RESULT_DIR/noisy/runtime/tmp
    gain=$(dirname $mic)/gain/$filename

    for (( i=0; i<10; i++ )); do # for N runs
      mkdir -p $DEST
      avg=cryosparc_$filename
      start=`date +%s.%N`
      # format output so that it can be processed by the same script. runtime is in seconds
      echo "runtime - filename: $filename using $gpus GPUs, one process per GPU"
      $CRYOSPARC_PYTHON_PATH --InTiff "$tmpDir/*.mrc" --OutMrc $DEST/$avg --Gain $gain --RotGain 0 --PixSize 1 --kV 200 --CSmm 2.7 --TotalDose 50.56 --GpuNum $gpus
      end=`date +%s.%N`
#      runtime=$( echo "$end - $start" | bc -l )
#      echo "real 0m${runtime}s"
      rm -r $DEST
    done
    rm -r $tmpDir
  done
done
#END

) |& tee $LOG
