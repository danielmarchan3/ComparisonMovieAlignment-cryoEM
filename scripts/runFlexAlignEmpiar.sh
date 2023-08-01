#!/bin/bash

[ -z "$MACHINE" ] && echo "Machine name dir not set (export MACHINE)" && exit 
[ -z "$XMIPP_PATH" ] && echo "Xmipp dir not set (export XMIPP_PATH)" && exit # i.e. export XMIPP_PATH=/home/user/scipion3/xmipp-bundle

set -x # show commands

BENCHMARK=./tmp_bench.txt
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
$XMIPP_PATH/xmipp git show -s
# add flexalign to path
source $XMIPP_PATH/build/xmipp.bashrc

#: <<'END'
PREFIX=10196
DIR=$MOVIE_DIR/$PREFIX
find $DIR -type f -exec md5sum {} \;
DEST=$RESULT_DIR/$PREFIX
mkdir -p $DEST
gain=$DIR/gain_flexalign.mrc
for mic in $DIR/*.tif; do
	filename=$(basename -- "$mic")
	filename_mrc=${filename/.tif/_avg.mrc}
	filename_xmd=${filename/.tif/_avg.xmd}
  avg=flexalign_$filename_mrc
  out=flexalign_$filename_xmd
  xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg --storage $BENCHMARK --sampling 0.745 --gain $gain
done
#END


#: <<'END'
PREFIX=10288
DIR=$MOVIE_DIR/$PREFIX
find $DIR -type f -exec md5sum {} \;
DEST=$RESULT_DIR/$PREFIX
mkdir -p $DEST
gain=$DIR/CountRef_CB1__00000_Feb18_23.26.46.dm4
for mic in $DIR/*.tif; do
  filename=$(basename -- "$mic")
	filename_mrc=${filename/.tif/_avg.mrc}
  filename_xmd=${filename/.tif/_avg.xmd}
  avg=flexalign_$filename_mrc
  out=flexalign_$filename_xmd
  xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg --storage $BENCHMARK --sampling 0.86 --gain $gain
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
	filename_xmd=${filename/.tif/_avg.xmd}
  avg=flexalign_$filename_mrc
  out=flexalign_$filename_xmd
  xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg --storage $BENCHMARK --sampling 1.12
done
# END

 :' NO NEED
#: <<'END'
# try different options
declare -a OPTIONS=("--patchesAvg" "--minLocalRes" "--maxResForCorrelation")
declare -a VALUES=("1 2 3 4 5" "300 400 500 600 700" "10 20 30 40 50")
declare -a DIR_PREFIX=("patchesAvg" "minLocalRes" "maxResForCorrelation")
declare -a AVERAGE_PREFIX=("avg" "minLocRes" "--maxRes")

for IDX in "${!OPTIONS[@]}"; do
    OPT="${OPTIONS[IDX]}"
    AVG_PREF="${AVERAGE_PREFIX[IDX]}"
    DIR_PREF="${DIR_PREFIX[IDX]}"
    read -a VALS <<< "${VALUES[IDX]}"
    for N in "${VALS[@]}"; do
        PREFIX=10196
        DIR=$MOVIE_DIR/$PREFIX
        find $DIR -type f -exec md5sum {} \;
        DEST=$RESULT_DIR/$PREFIX/$DIR_PREF
        mkdir -p $DEST
        gain=$DIR/gain_flexalign.mrc
        for mic in $DIR/*.tif; do
            filename=$(basename -- "$mic")  
            filename_mrc=${filename/.tif/_avg.mrc}
            filename_xmd=${filename/.tif/_avg.xmd}
            avg=flexalign_"${AVG_PREF}"${N}_$filename_mrc
            out=flexalign_$filename_xmd
            xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg --storage $BENCHMARK --sampling 0.745 --gain $gain ${OPT} ${N}
            rm $DEST/$out
            break # we need just one sample
        done

        PREFIX=10288
        DIR=$MOVIE_DIR/$PREFIX
        find $DIR -type f -exec md5sum {} \;
        DEST=$RESULT_DIR/$PREFIX/$DIR_PREF
        mkdir -p $DEST
        gain=$DIR/CountRef_CB1__00000_Feb18_23.26.46.dm4
        for mic in $DIR/*.tif; do
            filename=$(basename -- "$mic")
            filename_mrc=${filename/.tif/_avg.mrc}
            filename_xmd=${filename/.tif/_avg.xmd}
            avg=flexalign_"${AVG_PREF}"${N}_$filename_mrc
            out=flexalign_$filename_xmd
            xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg --storage $BENCHMARK --sampling 0.86 --gain $gain ${OPT} ${N}
            rm $DEST/$out
            break # we need just one sample
        done

        PREFIX=10314
        DIR=$MOVIE_DIR/$PREFIX
        find $DIR -type f -exec md5sum {} \;
        DEST=$RESULT_DIR/$PREFIX/$DIR_PREF
        mkdir -p $DEST
        for mic in $DIR/*.tif; do
            filename=$(basename -- "$mic")
            filename_mrc=${filename/.tif/_avg.mrc}
            filename_xmd=${filename/.tif/_avg.xmd}
            avg=flexalign_"${AVG_PREF}"${N}_$filename_mrc
            out=flexalign_$filename_xmd
            xmipp_cuda_movie_alignment_correlation -i $mic -o $DEST/$out --oavg $DEST/$avg --storage $BENCHMARK --sampling 1.12 ${OPT} ${N}
            rm $DEST/$out
            break # we need just one sample
        done
    done
done
#END
'
rm -f $BENCHMARK
#END

) |& tee $LOG
 
