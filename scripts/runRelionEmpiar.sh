#!/bin/bash

[ -z "$MACHINE" ] && echo "Machine name dir not set (export MACHINE)" && exit 
[ -z "$RELION_PATH" ] && echo "Path to Relion MotionCor not set (export RELION_PATH)" && exit # i.e. export RELION_PATH=/home/user/software/em/relion-4.0/bin/relion_run_motioncorr
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
		echo "--patch_x 7 --patch_y 5"
	else	
		echo "--patch_x 5 --patch_y 5"
	fi
}


function get_cores() {
	cores=$(nproc --all)
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

#: <<'END'
PREFIX=10196
DIR=$MOVIE_DIR/$PREFIX
find $DIR -type f -exec md5sum {} \;
DEST=$RESULT_DIR/$PREFIX/relion
mkdir -p $DEST
gain=$DIR/SuperRef_sq05_3.mrc
for mic in $DIR/*.tif; do
	filename=$(basename -- "$mic")
	filename_mrc=${filename/.tif/_avg.mrc}
	patches=$(get_patches $mic)
  avg=relion_$filename_mrc
  $RELION_PATH $patches --i $mic --o $DEST --use_own --j $(get_cores) --gain_rot 1 --gain_flip 2 --angpix 0.745 --gainref $gain --voltage 200
  mv $DEST/${mic/.tif/.mrc} $DEST/../$avg
  # flip to get interesting feature in the top corner (also default for FlexAlign)
  xmipp_transform_mirror -i $DEST/../$avg --flipY
done
rm -r $DEST
#END


#: <<'END'
PREFIX=10288
DIR=$MOVIE_DIR/$PREFIX
find $DIR -type f -exec md5sum {} \;
DEST=$RESULT_DIR/$PREFIX/relion
mkdir -p $DEST
gain=$DIR/CountRef_CB1__00000_Feb18_23.26.46.dm4
# convert gain to .mrc (DM4 not supported)
gain_mrc=$(basename -- $gain)
gain_mrc=$DEST/${gain_mrc/.dm4/.mrc}
xmipp_image_convert -i $gain -o $gain_mrc
for mic in $DIR/*.tif; do
  filename=$(basename -- "$mic")
	filename_mrc=${filename/.tif/_avg.mrc}
  patches=$(get_patches $mic)
  avg=relion_$filename_mrc
  $RELION_PATH $patches --i $mic --o $DEST --use_own --j $(get_cores) --angpix 0.86 --gainref $gain_mrc --voltage 300 --gain_flip 1
  mic=${mic//./_} # relion stores it as CB1__00006_Feb18_23_39_55.mrc so we replace all dots by underscore and then replace the file extension
  mv $DEST/${mic/_tif/.mrc} $DEST/../$avg
  # flip to get interesting feature in the top corner (also default for FlexAlign)
  xmipp_transform_mirror -i $DEST/../$avg --flipY
done
rm -r $DEST
#END


#: <<'END'
PREFIX=10314
DIR=$MOVIE_DIR/$PREFIX
find $DIR -type f -exec md5sum {} \;
DEST=$RESULT_DIR/$PREFIX/relion
mkdir -p $DEST
for mic in $DIR/*.tif; do
  filename=$(basename -- "$mic")
	filename_mrc=${filename/.tif/_avg.mrc}
  patches=$(get_patches $mic)
  avg=relion_$filename_mrc
  $RELION_PATH $patches --i $mic --o $DEST --use_own --j $(get_cores) --angpix 1.12 --voltage 300
  mv $DEST/${mic/.tif/.mrc} $DEST/../$avg
  # flip to get interesting feature in the top corner (also default for FlexAlign)
  xmipp_transform_mirror -i $DEST/../$avg --flipY
done
rm -r $DEST
#END


) |& tee $LOG
 
