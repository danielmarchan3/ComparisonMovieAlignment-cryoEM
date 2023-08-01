#!/bin/bash

[ -z "$MACHINE" ] && echo "Machine name dir not set (export MACHINE)" && exit 
[ -z "$MOTIONCOR_PATH" ] && echo "Path to MotionCor2 not set (export MOTIONCOR_PATH)" && exit  # i.e. export MOTIONCOR_PATH=/home/user/scipion3/software/em/motioncor2-1.6.4/bin/MotionCor2_1.6.4_Cuda112_Mar312023
[ -z "$XMIPP_PATH" ] && echo "Xmipp dir not set (export XMIPP_PATH)" && exit # i.e. export XMIPP_PATH=/home/user/scipion3/xmipp-bundle

source $XMIPP_PATH/build/xmipp.bashrc

set -x # show commands

PARENT_DIR="$(dirname "$(dirname "$(readlink -fm "$0")")")"
MOVIE_DIR=$PARENT_DIR/empiar_movies
RESULT_DIR=$PARENT_DIR/$MACHINE/empiar_movies
SCRIPT=`basename "$0"`
LOG=${SCRIPT/.sh/.log}
LOG="$(dirname $RESULT_DIR)"/$LOG

mkdir -p $RESULT_DIR # to be able to store the log

function get_patches() {
	size=$(xmipp_image_header "$1" | head -n 11 | tail -n -1) # Dimensions     : 1 x 1 x 7676 x 7420  ((N)Objects x (Z)Slices x (Y)Rows x (X)Columns)
	read -a strarr <<< $size
	if (( ${strarr[8]} > 5000 )); then
		echo "-Patch 7 5"
	else	
		echo "-Patch 5 5"
	fi
}


#start logging
( 

# log version
$MOTIONCOR_PATH --version

#: <<'END'
PREFIX=10196
DIR=$MOVIE_DIR/$PREFIX
find $DIR -type f -exec md5sum {} \;
DEST=$RESULT_DIR/$PREFIX
mkdir -p $DEST
gain=$DIR/SuperRef_sq05_3.mrc
for mic in $DIR/*.tif; do
	filename=$(basename -- "$mic")
	filename_mrc=${filename/.tif/_avg.mrc}
	patches=$(get_patches $mic)
  avg=motioncor2_$filename_mrc
  $MOTIONCOR_PATH $patches -InTiff $mic -OutMrc $DEST/$avg -RotGain 1 -FlipGain 2 -PixSize 0.745 -Gain $gain -kV 200
  # flip to get interesting feature in the top corner (also default for FlexAlign)
  xmipp_transform_mirror -i $DEST/$avg --flipY
done
#END


#: <<'END'
PREFIX=10288
DIR=$MOVIE_DIR/$PREFIX
find $DIR -type f -exec md5sum {} \;
DEST=$RESULT_DIR/$PREFIX
mkdir -p $DEST
gain=$DIR/CountRef_CB1__00000_Feb18_23.26.46.dm4
# convert gain to .mrc (DM4 not supported)
gain_name=$(basename $gain) # TODO new command introduced
gain_mrc=$DEST/${gain_name/.dm4/.mrc}
xmipp_image_convert -i $gain -o $gain_mrc
for mic in $DIR/*.tif; do
  filename=$(basename -- "$mic")
	filename_mrc=${filename/.tif/_avg.mrc}
  patches=$(get_patches $mic)
  avg=motioncor2_$filename_mrc
  $MOTIONCOR_PATH $patches -InTiff $mic -OutMrc $DEST/$avg -PixSize 0.86 -Gain $gain_mrc -FlipGain 1
  # flip to get interesting feature in the top corner (also default for FlexAlign)
  xmipp_transform_mirror -i $DEST/$avg --flipY
done
#END


##: <<'END'
PREFIX=10314
DIR=$MOVIE_DIR/$PREFIX
find $DIR -type f -exec md5sum {} \;
DEST=$RESULT_DIR/$PREFIX
mkdir -p $DEST
for mic in $DIR/*.tif; do
	filename=$(basename -- "$mic")
	filename_mrc=${filename/.tif/_avg.mrc}
	patches=$(get_patches $mic)
  avg=motioncor2_$filename_mrc
  $MOTIONCOR_PATH $patches -InTiff $mic -OutMrc $DEST/$avg -PixSize 1.12
  # flip to get interesting feature in the top corner (also default for FlexAlign)
  xmipp_transform_mirror -i $DEST/$avg --flipY
done
#END

) |& tee $LOG
 
