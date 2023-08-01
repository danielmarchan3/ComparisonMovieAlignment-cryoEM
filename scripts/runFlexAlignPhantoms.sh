#!/bin/bash

[ -z "$MACHINE" ] && echo "Machine name dir not set (export MACHINE)" && exit 
[ -z "$XMIPP_PATH" ] && echo "Xmipp dir not set (export XMIPP_PATH)" && exit # i.e. export XMIPP_PATH=/home/user/scipion3/xmipp-bundle

set -x # show commands

BENCHMARK=./tmp_bench.txt
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
$XMIPP_PATH/xmipp git show -s
# add flexalign to path
source $XMIPP_PATH/build/xmipp.bashrc

# measure autotuning time
#: <<'END'
for mic in $MOVIE_DIR/noisy/*.mrc; do
	filename=$(basename -- "$mic")
	DEST=$RESULT_DIR/noisy/autotuning
	mkdir -p $DEST
	out=flexalign_${filename/.mrc/.xmd}
	avg=flexalign_${filename/.mrc/_avg.mrc}
	for (( i=0; i<10; i++ ))
	do  
		rm -f $BENCHMARK
		echo benchmark - filename: $filename
		time xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg  --storage $BENCHMARK
		rm -f $BENCHMARK
	done
done
#END

# measure runtime / get data for quality (noise)
#: <<'END'
for mic in $MOVIE_DIR/noisy/*.mrc; do
	filename=$(basename -- "$mic")
	DEST=$RESULT_DIR/noisy/runtime
	mkdir -p $DEST
	rm -f $BENCHMARK
	out=flexalign_${filename/.mrc/.xmd}
	avg=flexalign_${filename/.mrc/_avg.mrc}
	gain=$(dirname $mic)/gain/$filename
	dark=$(dirname $mic)/dark/$filename
	xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --storage $BENCHMARK
	for (( i=0; i<10; i++ ))
	do  
		echo runtime - filename: $filename
		time xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg  --storage $BENCHMARK --gain $gain --dark $dark
	done
	rm -f $BENCHMARK
done
#END

# get data for quality (noiseless)
#: <<'END'
rm -f $BENCHMARK
for mic in $MOVIE_DIR/pristine/*.mrc; do
	filename=$(basename -- "$mic")
	DEST=$RESULT_DIR/pristine/runtime
	mkdir -p $DEST
	out=flexalign_${filename/.mrc/.xmd}
	avg=flexalign_${filename/.mrc/_avg.mrc}
	gain=$(dirname $mic)/gain/$filename
	dark=$(dirname $mic)/dark/$filename
	xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg  --storage $BENCHMARK --gain $gain --dark $dark
done
rm -f $BENCHMARK
#END

# get data for quality (shift)
#: <<'END'
declare -a SHIFTS=("pristine" "noisy")
rm -f $BENCHMARK
for DIR in "${SHIFTS[@]}"; do
	for mic in $MOVIE_DIR/$DIR/shift/*.mrc; do
		filename=$(basename -- "$mic")
		DEST=$RESULT_DIR/$DIR/runtime
		mkdir -p $DEST
		out=flexalign_${filename/.mrc/.xmd}
		avg=flexalign_${filename/.mrc/_avg.mrc}
		gain=$(dirname $mic)/gain/$filename
		dark=$(dirname $mic)/dark/$filename
		xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg  --storage $BENCHMARK --gain $gain --dark $dark
	done
done
rm -f $BENCHMARK
# END

# get data for different max shift
#: <<'END'
declare -a SHIFTS=("pristine" "noisy")
declare -a MAX_SHIFTS=("50" "60" "70" "80" "90" "100" "110" "120")
rm -f $BENCHMARK
for DIR in "${SHIFTS[@]}"; do
    mic=$MOVIE_DIR/$DIR/shift/shift_120.mrc
	for S in "${MAX_SHIFTS[@]}"; do
		filename=$(basename -- "$mic")
		DEST=$RESULT_DIR/$DIR/runtime/maxShift
		mkdir -p $DEST
		out=flexalign_${filename/.mrc/.xmd}
		avg=flexalign_maxshift_${S}_${filename/.mrc/_avg.mrc}
		gain=$(dirname $mic)/gain/$filename
		dark=$(dirname $mic)/dark/$filename
		xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg  --storage $BENCHMARK --gain $gain --dark $dark --maxShift $S
	done
done
rm -f $BENCHMARK
#END


# measure runtime in parallel execution
# : <<'END'
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
		rm -f $BENCHMARK
		gain=$(dirname $mic)/gain/$name_gain
		dark=$(dirname $mic)/dark/$name_gain
		out=flexalign_${filename/.mrc/_$gpus.xmd}
		# create benchmark
		for (( g=1; g<=$gpus; g++ )); do # create benchmark for each GPU
			xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --storage $BENCHMARK --device $((g-1))
		done
		rm $out
		for (( i=0; i<10; i++ )); do # for N runs
			start=`date +%s.%N`
			for (( g=1; g<=$gpus; g++ )); do # run # processes
				# run all this in a background process
				{
				copy=${mic/.mrc/_$g.mrc}
				avg=flexalign_${filename/.mrc/_$g.mrc}
				out=flexalign_${filename/.mrc/_$g.xmd}
				xmipp_cuda_movie_alignment_correlation -i $copy -o $DEST/$out --oavg $DEST/$avg  --storage $BENCHMARK --gain $gain --dark $dark --device $((g-1))
				} &
			done
			wait # for all processes spawned in the above loop
			end=`date +%s.%N`
			runtime=$( echo "$end - $start" | bc -l )
			# format output so that it can be processed by the same script. runtime is in seconds
			echo "runtime - filename: $filename using $gpus GPUs, one process per GPU"
			echo "real 0m${runtime}s"
		done
		rm -f $BENCHMARK
		for (( g=1; g<=$gpus; g++ )); do # clean generated data
			copy=${mic/.mrc/_$g.mrc}
			avg=flexalign_${filename/.mrc/_$g.mrc}
			out=flexalign_${filename/.mrc/_$g.xmd}
			rm $copy $DEST/$avg $DEST/$out
		done
	done
done
# END


) |& tee $LOG
 
