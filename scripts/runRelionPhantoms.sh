#!/bin/bash

[ -z "$MACHINE" ] && echo "Machine name dir not set (export MACHINE)" && exit 
[ -z "$RELION_PATH" ] && echo "Path to Relion MotionCor not set (export RELION_PATH)" && exit # i.e. export RELION_PATH=/home/user/software/em/relion-4.0/bin/relion_run_motioncorr
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

cores=$(nproc --all)


function get_patches() {
	size=$(xmipp_image_header "$1" | head -n 11 | tail -n -1) # Dimensions     : 1 x 1 x 7676 x 7420  ((N)Objects x (Z)Slices x (Y)Rows x (X)Columns)
	read -a strarr <<< $size
	x=5
	y=5
	if (( ${strarr[8]} > 5000 )); then
		x=7
	fi
	echo "--patch_x $(($x*$2)) --patch_y $(($y*$2))"
}

function get_cores() {
	if (( $cores > 8 )); then
		echo 8
	else
		echo $cores
	fi
}


#start logging
( 

# log version
$RELION_PATH --version

# measure runtime / get data for quality (noise)
#: <<'END'
for mic in $MOVIE_DIR/noisy/*.mrc; do
	filename=$(basename -- "$mic")
	DEST=$RESULT_DIR/noisy/runtime/relion
	mkdir -p $DEST
	avg=relion_${filename/.mrc/_avg.mrc}
	patches=$(get_patches $mic 1)
	gain=$(dirname $mic)/gain/$filename
	for (( i=0; i<10; i++ ))
	do  
		echo runtime - filename: $filename
		time $RELION_PATH $patches --i $mic --o $DEST --use_own --j $(get_cores) --angpix 1 --voltage 200 --gainref $gain
	done
	mv $DEST/$mic $DEST/../$avg
	rm -r $DEST

done
#END

# get data for quality (noiseless)
#: <<'END'
for mic in $MOVIE_DIR/pristine/*.mrc; do
	filename=$(basename -- "$mic")
	DEST=$RESULT_DIR/pristine/runtime/relion
	mkdir -p $DEST
	avg=relion_${filename/.mrc/_avg.mrc}
	patches=$(get_patches $mic 1)
	gain=$(dirname $mic)/gain/$filename
	$RELION_PATH $patches --i $mic --o $DEST --use_own --j $(get_cores) --angpix 1 --voltage 200 --gainref $gain
	mv $DEST/$mic $DEST/../$avg
	rm -r $DEST
done
#END

# get data for quality (shift)
#: <<'END'
declare -a SHIFTS=("pristine" "noisy")
for DIR in "${SHIFTS[@]}"; do
	for mic in $MOVIE_DIR/$DIR/shift/*.mrc; do
		filename=$(basename -- "$mic")
		DEST=$RESULT_DIR/$DIR/runtime/relion
		mkdir -p $DEST
		avg=relion_${filene/.mrc/_avg.mrc}
		log=relion_${filename/.mrc/.star}
		patches=$(get_patches $mic 1)
		gain=$(dirname $mic)/gain/$filename
		$RELION_PATH $patches --i $mic --o $DEST --use_own --j $(get_cores) --angpix 1 --voltage 200 --gainref $gain
		mv $DEST/$mic $DEST/../$avg
		mv $DEST/${mic/.mrc/.star} $DEST/../$log
		rm -r $DEST
	done
done
#END

#: <<'END'
# measure scaling
for mic in $MOVIE_DIR/noisy/*.mrc; do # for each movie
	for (( c=1; c<=$cores; c+=1 )); do # for each # cores
		processes=$(($cores / $c ))
		name_gain=$(basename -- "$mic")
		gain=$(dirname $mic)/gain/$name_gain
		for (( p=1; p<=$processes; p++ )); do # create 'unique' test data
			copy=${mic/.mrc/_$p.mrc}
			cp $mic $copy
		done
		echo ""
		echo Using $c cores per process
		for (( i=0; i<10; i++ )); do # for N runs
			start=`date +%s.%N`
			filename=$(basename -- "$mic")
			for (( p=1; p<=$processes; p++ )); do # run # processes
				# run all this in a backgroud process
				{
				DEST=$RESULT_DIR/noisy/runtime/relion_$p
				mkdir -p $DEST
				copy=${mic/.mrc/_$p.mrc}
				patches=$(get_patches $mic 1)
				# gain=$(dirname $mic)/gain/$filename
				$RELION_PATH $patches --i $copy --o $DEST --use_own --j $c --angpix 1 --voltage 200 --gainref $gain 
				rm -r $DEST
				} &
			done
			wait # for all processes spawned in the above loop
			end=`date +%s.%N`
			runtime=$( echo "$end - $start" | bc -l )
			# format output so that it can be processed by the same script. runtime is in seconds
			echo "runtime - filename: $filename using $processes processes and $c cores per process"
			echo "real 0m${runtime}s"
		done
		for (( p=1; p<=$processes; p++ )); do # clean generated data
			copy=${mic/.mrc/_$p.mrc}
			rm $copy
		done
	done
done
#END

# measure runtime / get data for patches (noise)
#: <<'END'
for mult in 2 3; do
	for mic in $MOVIE_DIR/noisy/*.mrc; do
		filename=$(basename -- "$mic")
		DEST=$RESULT_DIR/noisy/runtime/relion
		mkdir -p $DEST
		avg=relion_${filename/.mrc/_avg${mult}.mrc}
		patches=$(get_patches $mic $mult)
		gain=$(dirname $mic)/gain/$filename
		for (( i=0; i<10; i++ ))
		do  
			echo runtime - filename: $filename using patch multiplier $mult
			time $RELION_PATH $patches --i $mic --o $DEST --use_own --j $(get_cores) --angpix 1 --voltage 200 --gainref $gain
		done
		mv $DEST/$mic $DEST/../$avg
		rm -r $DEST

	done
done
#END

# get data for patches (noise)
#: <<'END'
for mult in 2 3; do
	for mic in $MOVIE_DIR/pristine/*.mrc; do
		filename=$(basename -- "$mic")
		DEST=$RESULT_DIR/pristine/runtime/relion
		mkdir -p $DEST
		avg=relion_${filename/.mrc/_avg${mult}.mrc}
		patches=$(get_patches $mic $mult)
		gain=$(dirname $mic)/gain/$filename
		$RELION_PATH $patches --i $mic --o $DEST --use_own --j $(get_cores) --angpix 1 --voltage 200 --gainref $gain
		mv $DEST/$mic $DEST/../$avg
		rm -r $DEST
	done
done
#END

) |& tee $LOG
 
