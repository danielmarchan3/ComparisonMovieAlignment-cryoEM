#!/bin/bash

declare -a SPA_SIZES=("3838 3710 70" "4096 4096 70" "5760 4092 70" "7676 7420 70" "11520 8184 70")
declare -a TOMO_SIZES=("3838 3710 6" "4096 4096 6" "5760 4092 6" "7676 7420 6" "11520 8184 6" "3838 3710 10" "4096 4096 10" "5760 4092 10" "7676 7420 10" "11520 8184 10")
declare -a SHIFTS=("shift_50 0.71" "shift_60 0.85" "shift_70 1.0" "shift_80 1.14" "shift_90 1.28" "shift_100 1.42" "shift_110 1.57" "shift_120 1.71")

[ -z "$XMIPP_PATH" ] && echo "Xmipp dir not set (export XMIPP_PATH)" && exit # i.e. export XMIPP_PATH=/home/user/scipion3/xmipp-bundle
source $XMIPP_PATH/build/xmipp.bashrc

set -x # show commands
DIR_BASE="$(dirname "$(dirname "$(readlink -fm "$0")")")"


#: <<'END'
# generate noiseless movies
DIR=$DIR_BASE/phantom_movies/pristine
mkdir -p $DIR/gain
mkdir -p $DIR/dark

for size in "${TOMO_SIZES[@]}"; do
	f=${size//[ ]/x}
	xmipp_phantom_movie -size $size -step 150 150 --skipIce --skipDose -o $DIR/$f.mrc --gain $DIR/gain/$f.mrc --dark $DIR/dark/$f.mrc
done
for size in "${SPA_SIZES[@]}"; do
	f=${size//[ ]/x}
	xmipp_phantom_movie -size $size -step 150 150 --skipIce --skipDose -o $DIR/$f.mrc --gain $DIR/gain/$f.mrc --dark $DIR/dark/$f.mrc
done
#END

#: <<'END'
# generate noisy movies
DIR=$DIR_BASE/phantom_movies/noisy
mkdir -p $DIR/gain
mkdir -p $DIR/dark

for size in "${TOMO_SIZES[@]}"; do
	f=${size//[ ]/x}
	xmipp_phantom_movie -size $size -step 150 150 -o $DIR/$f.mrc --gain $DIR/gain/$f.mrc --dark $DIR/dark/$f.mrc
done
for size in "${SPA_SIZES[@]}"; do
	f=${size//[ ]/x}
	xmipp_phantom_movie -size $size -step 150 150 -o $DIR/$f.mrc --gain $DIR/gain/$f.mrc --dark $DIR/dark/$f.mrc
done
#END

#: <<'END'
# generate shift movies
DIR=$DIR_BASE/phantom_movies/noisy/shift
mkdir -p $DIR/gain
mkdir -p $DIR/dark
for shift in "${SHIFTS[@]}"; do
	read -a strarr <<< $shift
	xmipp_phantom_movie -size 4096 4096 70 -step 300 300 -o $DIR/${strarr[0]}.mrc --gain $DIR/gain/${strarr[0]}.mrc --dark $DIR/dark/${strarr[0]}.mrc --simple --shift ${strarr[1]} 0 ${strarr[1]} 0
done
DIR=$DIR_BASE/phantom_movies/pristine/shift
mkdir -p $DIR/gain
mkdir -p $DIR/dark
for shift in "${SHIFTS[@]}"; do
	read -a strarr <<< $shift
	xmipp_phantom_movie -size 4096 4096 70 -step 300 300 --skipIce --skipDose -o $DIR/${strarr[0]}.mrc --gain $DIR/gain/${strarr[0]}.mrc --dark $DIR/dark/${strarr[0]}.mrc --simple --shift ${strarr[1]} 0 ${strarr[1]} 0
done
#END
