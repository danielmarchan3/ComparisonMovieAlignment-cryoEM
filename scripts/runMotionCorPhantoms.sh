#!/bin/bash

[ -z "$MACHINE" ] && echo "Machine name dir not set (export MACHINE)" && exit 
[ -z "$MOTIONCOR_PATH" ] && echo "Path to MotionCor2 not set (export MOTIONCOR_PATH)" && exit # i.e. export MOTIONCOR_PATH=/home/dmarchan/scipion3/software/em/motioncor2-1.6.4/bin/MotionCor2_1.6.4_Cuda112_Mar312023
[ -z "$XMIPP_PATH" ] && echo "Xmipp dir not set (export XMIPP_PATH)" && exit # i.e. export XMIPP_PATH=/home/dmarchan/scipion3/xmipp-bundle

source $XMIPP_PATH/build/xmipp.bashrc

set -x # show commands

PARENT_DIR="$(dirname "$(dirname "$(readlink -fm "$0")")")"
MOVIE_DIR=$PARENT_DIR/phantom_movies
RESULT_DIR=$PARENT_DIR/$MACHINE/phantom_movies
SCRIPT=`basename "$0"`
LOG=${SCRIPT/.sh/.log}
LOG="$(dirname $RESULT_DIR)"/$LOG

mkdir -p $RESULT_DIR # to be able to store the log

function get_patches() {
	size=$(xmipp_image_header "$1" | head -n 11 | tail -n -1) # Dimensions     : 1 x 1 x 7676 x 7420  ((N)Objects x (Z)Slices x (Y)Rows x (X)Columns)
	read -a strarr <<< $size
	x=5
	y=5
	if (( ${strarr[8]} > 5000 )); then
		x=7
	fi
	echo "-Patch $(($x*$2)) $(($y*$2))"
}


#start logging
( 

# log version
$MOTIONCOR_PATH --version

# measure runtime / get data for quality (noise)
#: <<'END'
for mic in $MOVIE_DIR/noisy/*.mrc; do
	filename=$(basename -- "$mic")
	DEST=$RESULT_DIR/noisy/runtime
	mkdir -p $DEST
	avg=motioncor2_${filename/.mrc/_avg.mrc}
	patches=$(get_patches $mic 1)
	gain=$(dirname $mic)/gain/$filename
	dark=$(dirname $mic)/dark/$filename
	for (( i=0; i<10; i++ ))
	do  
		echo runtime - filename: $filename
		time $MOTIONCOR_PATH $patches -InMrc $mic -OutMrc $DEST/$avg -Gain $gain -Dark $dark
	done

done
#END

# get data for quality (noiseless)
#: <<'END'
for mic in $MOVIE_DIR/pristine/*.mrc; do
	filename=$(basename -- "$mic")
	DEST=$RESULT_DIR/pristine/runtime
	mkdir -p $DEST
	avg=motioncor2_${filename/.mrc/_avg.mrc}
	patches=$(get_patches $mic 1)
	gain=$(dirname $mic)/gain/$filename
	dark=$(dirname $mic)/dark/$filename
	$MOTIONCOR_PATH $patches -InMrc $mic -OutMrc $DEST/$avg -Gain $gain -Dark $dark
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
		avg=motioncor2_${filename/.mrc/_avg.mrc}
		patches=$(get_patches $mic 1)
		gain=$(dirname $mic)/gain/$filename
		dark=$(dirname $mic)/dark/$filename
		$MOTIONCOR_PATH $patches -InMrc $mic -OutMrc $DEST/$avg -Gain $gain -Dark $dark
	done
done
#END


# measure runtime / get data for patches (noise)
#: <<'END'
for mult in 2 3; do
	for mic in $MOVIE_DIR/noisy/*.mrc; do
		filename=$(basename -- "$mic")
		DEST=$RESULT_DIR/noisy/runtime
		mkdir -p $DEST
		avg=motioncor2_${filename/.mrc/_avg${mult}.mrc}
		patches=$(get_patches $mic $mult)
		gain=$(dirname $mic)/gain/$filename
		dark=$(dirname $mic)/dark/$filename
		for (( i=0; i<10; i++ ))
		do  
			echo runtime - filename: $filename using patch multiplier $mult
			time $MOTIONCOR_PATH $patches -InMrc $mic -OutMrc $DEST/$avg -Gain $gain -Dark $dark
		done
	done
done
#END

# get data for patches (noise)
#: <<'END'
for mult in 2 3; do
	for mic in $MOVIE_DIR/noisy/*.mrc; do
		filename=$(basename -- "$mic")
		DEST=$RESULT_DIR/noisy/runtime
		mkdir -p $DEST
		avg=motioncor2_${filename/.mrc/_avg${mult}.mrc}
		patches=$(get_patches $mic $mult)
		gain=$(dirname $mic)/gain/$filename
		dark=$(dirname $mic)/dark/$filename
		$MOTIONCOR_PATH $patches -InMrc $mic -OutMrc $DEST/$avg -Gain $gain -Dark $dark
	done
done
#END


# measure runtime in parallel execution (no batch)
#: <<'END'
noOfGpus=$(nvidia-smi -L | wc -l)
for (( gpus=2; gpus<=$noOfGpus; gpus++ )); do
	for mic in $MOVIE_DIR/noisy/*.mrc; do
		name_gain=$(basename -- "$mic")
		for (( g=1; g<=$gpus; g++ )); do # create 'unique' test data
			copy=${mic/.mrc/_$g.mrc}
			cp $mic $copy
		done
		filename=$(basename -- "$mic")
		DEST=$RESULT_DIR/noisy/runtime
		mkdir -p $DEST
		gain=$(dirname $mic)/gain/$name_gain
		dark=$(dirname $mic)/dark/$name_gain
		patches=$(get_patches $mic 1)
		# create benchmark
		for (( i=0; i<10; i++ )); do # for N runs
			start=`date +%s.%N`
			for (( g=1; g<=$gpus; g++ )); do # run # processes
				# run all this in a background process
				{
				copy=${mic/.mrc/_$g.mrc}
				avg=motioncor2_${filename/.mrc/_$g.mrc}
				$MOTIONCOR_PATH $patches -InMrc $copy -OutMrc $DEST/$avg -Gain $gain -Dark $dark -Gpu $((g-1))
				} &
			done
			wait # for all processes spawned in the above loop
			end=`date +%s.%N`
			runtime=$( echo "$end - $start" | bc -l )
			# format output so that it can be processed by the same script. runtime is in seconds
			echo "runtime - filename: $filename using $gpus GPUs, one process per GPU"
			echo "real 0m${runtime}s"
		done
		for (( g=1; g<=$gpus; g++ )); do # clean generated data
			copy=${mic/.mrc/_$g.mrc}
			avg=motioncor2_${filename/.mrc/_$g.mrc}
			rm $copy $DEST/$avg $DEST/$out
		done
	done
done
#END


# measure runtime batch execution (several GPUs)
#: <<'END'
noOfGpus=$(nvidia-smi -L | wc -l)
range=0
for mic in $MOVIE_DIR/noisy/*.mrc; do
	batchDir=$(dirname $mic)/batch
	mkdir -p $batchDir
	filename=$(basename -- "$mic")
	for (( c=1; c<=20; c++ )); do # create 'unique' test data
		copy=${filename/.mrc/_$c.mrc}
		cp $mic $batchDir/$copy
	done
  for (( gpus=1; gpus<=$noOfGpus; gpus++ )); do
    range=$(echo $(seq 0 $(($gpus-1))))
    DEST=$RESULT_DIR/noisy/runtime/batch
    mkdir -p $DEST
    gain=$(dirname $mic)/gain/$filename
    dark=$(dirname $mic)/dark/$filename
    patches=$(get_patches $mic 1)
    # create benchmark
    for (( i=0; i<5; i++ )); do # for N runs
      echo "runtime - filename: $filename using $range GPUs in batch"
      time $MOTIONCOR_PATH $patches -InMrc $batchDir/ -OutMrc $DEST/ -Gain $gain -Dark $dark -Gpu $range -Serial 1
      rm -rf $DEST
    done
  done
	rm -rf $batchDir

done
#END

# measure runtime (no batch 1 GPU)
#: <<'END'
noOfGpus=$(nvidia-smi -L | wc -l)
for mic in $MOVIE_DIR/noisy/*.mrc; do
	batchDir=$(dirname $mic)/batch
	mkdir -p $batchDir
	filename=$(basename -- "$mic")
	for (( c=1; c<=20; c++ )); do # create 'unique' test data
		copy=${filename/.mrc/_$c.mrc}
		cp $mic $batchDir/$copy
	done
  DEST=$RESULT_DIR/noisy/runtime/batch
	gain=$(dirname $mic)/gain/$filename
	dark=$(dirname $mic)/dark/$filename
	patches=$(get_patches $mic 1)
  # create benchmark
  for (( i=0; i<5; i++ )); do # for N runs
    mkdir -p $DEST
    #	range=$(echo $(seq 0 $(($gpus-1))))
	  start=`date +%s.%N`
	  for micCopy in $batchDir/*.mrc; do
	    name=$(basename -- "$micCopy")
	    avg=motioncor2_${name/.mrc/_avg.mrc}
	    $MOTIONCOR_PATH $patches -InMrc $micCopy -OutMrc $DEST/$avg -Gain $gain -Dark $dark -Gpu 0
    done
    end=`date +%s.%N`
		runtime=$( echo "$end - $start" | bc -l )
		# format output so that it can be processed by the same script. runtime is in seconds
		echo "runtime - filename: $filename using 1 GPUs no batch"
		echo "real 0m${runtime}s"
    rm -rf $DEST
  done
	rm -rf $batchDir
done
#END

) |& tee $LOG
 
