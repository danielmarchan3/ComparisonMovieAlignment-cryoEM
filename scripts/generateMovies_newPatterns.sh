#!/bin/bash

declare -a SPA_SIZES=("4096 4096 70" "7676 7420 70" "11520 8184 70")
declare -a TOMO_SIZES=("4096 4096 10" "7676 7420 10" "11520 8184 10")

list_min=(60 90 150)
list_max=(100 150 250)

[ -z "$XMIPP_PATH" ] && echo "Xmipp dir not set (export XMIPP_PATH)" && exit
source $XMIPP_PATH/build/xmipp.bashrc

set -x # show commands
DIR_BASE="$(dirname "$(dirname "$(readlink -fm "$0")")")"

#: <<'END'
# generate noiseless movies with circles
DIR=$DIR_BASE/phantom_movies/pristine
mkdir -p $DIR/gain
mkdir -p $DIR/dark

i=0
for size in "${TOMO_SIZES[@]}"; do
	f=${size//[ ]/x}
	min="${list_min[i]}"
  max="${list_max[i]}"
	f_name=$f"_circles.mrc"
	xmipp_phantom_movie -size $size --type circle --particleSize $min $max --count 100 --thickness $max  --skipIce --skipDose -o $DIR/$f_name --gain $DIR/gain/$f_name --dark $DIR/dark/$f_name
  # Increment the counter variable
  i=$((i + 1))
done

i=0
for size in "${SPA_SIZES[@]}"; do
 f=${size//[ ]/x}
	min="${list_min[i]}"
  max="${list_max[i]}"
	f_name=$f"_circles.mrc"
	xmipp_phantom_movie -size $size --type circle --particleSize $min $max --count 100 --thickness $max  --skipIce --skipDose -o $DIR/$f_name --gain $DIR/gain/$f_name --dark $DIR/dark/$f_name
 Increment the counter variable
 i=$((i + 1))
done


#: <<'END'
# generate noisy movies
DIR=$DIR_BASE/phantom_movies/noisy
mkdir -p $DIR/gain
mkdir -p $DIR/dark

i=0
for size in "${TOMO_SIZES[@]}"; do
  f=${size//[ ]/x}
	min="${list_min[i]}"
  max="${list_max[i]}"
	f_name=$f"_circles.mrc"
	xmipp_phantom_movie -size $size --signal -0.1 --type circle --particleSize $min $max --count 100 --thickness $max -o $DIR/$f_name --gain $DIR/gain/$f_name --dark $DIR/dark/$f_name
  # Increment the counter variable
  i=$((i + 1))
done

i=0
for size in "${SPA_SIZES[@]}"; do
	f=${size//[ ]/x}
	min="${list_min[i]}"
  max="${list_max[i]}"
	f_name=$f"_circles.mrc"
	xmipp_phantom_movie -size $size --signal -0.1 --type circle --particleSize $min $max --count 100 --thickness $max -o $DIR/$f_name --gain $DIR/gain/$f_name --dark $DIR/dark/$f_name
# Increment the counter variable
  i=$((i + 1))
done
