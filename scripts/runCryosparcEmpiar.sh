#!/bin/bash

[ -z "$MACHINE" ] && echo "Machine name dir not set (export MACHINE)" && exit
[ -z "$CRYOSPARC_PATH" ] && echo "Path to cryosparc script not set (export CRYOSPARC_PATH)" && exit # i.e. export CRYOSPARC_PATH=/usr/local/cryosparc3/cryosparc_master/bin/cryosparcm
[ -z "$CRYOSPARC_PYTHON_PATH" ] && echo "Path to cryosparc python script not set (export CRYOSPARC_PATH)" && exit #i.e. export CRYOSPARC_PYTHON_PATH='python3 /home/user/ComparisonMovieAlignment-cryoEM/scripts/cryosparc_patch_motion_correction.py'
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

#start logging
(

# log version
$CRYOSPARC_PATH cli 'get_running_version()'

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
	avg=cryosparc_$filename_mrc
  $CRYOSPARC_PYTHON_PATH --InTiff $mic --OutMrc $DEST/$avg --Gain $gain --RotGain 1 --FlipGain 2 --PixSize 0.745 --kV 200 --CSmm 2.7 --TotalDose 50.56 --GpuNum 1
  # flip to get interesting feature in the top corner (also default for FlexAlign)
  #xmipp_transform_mirror -i $DEST/$avg --flipY
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
  avg=cryosparc_$filename_mrc
  $CRYOSPARC_PYTHON_PATH --InTiff $mic --OutMrc $DEST/$avg --Gain $gain_mrc --RotGain 0 --FlipGain 0 --PixSize 0.86 --kV 200 --CSmm 2.7 --TotalDose 50.56 --GpuNum 1 #kV, cs__mm and TotalDose no info
  # flip to get interesting feature in the top corner (also default for FlexAlign)
  #xmipp_transform_mirror -i $DEST/$avg --flipY
done
#END


#: <<'END'
PREFIX=10314
DIR=$MOVIE_DIR/$PREFIX
find $DIR -type f -exec md5sum {} \;
DEST=$RESULT_DIR/$PREFIX
mkdir -p $DEST
for mic in $DIR/*.tif; do
	filename=$(basename -- "$mic")
	filename_mrc=${filename/.tif/_avg.mrc}
  avg=cryosparc_$filename_mrc
  $CRYOSPARC_PYTHON_PATH --InTiff $mic --OutMrc $DEST/$avg --PixSize 1.12 --kV 200 --CSmm 2.7 --TotalDose 50 --GpuNum 1 #kV, cs__mm no info
  # flip to get interesting feature in the top corner (also default for FlexAlign)
  #xmipp_transform_mirror -i $DEST/$avg --flipY
done
#END

) |& tee $LOG