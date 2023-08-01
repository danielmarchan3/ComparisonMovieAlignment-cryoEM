#!/bin/bash

[ -z "$MACHINE" ] && echo "Machine name dir not set (export MACHINE)" && exit # i.e. export MACHINE=galileoShadow
[ -z "$XMIPP_PATH" ] && echo "Xmipp dir not set (export XMIPP_PATH)" && exit # i.e. export XMIPP_PATH=/home/user/scipion3/xmipp-bundle
[ -z "$GCTF_PATH" ] && echo "GCTF path not set (export GCTF_PATH)" && exit # i.e. export GCTF_PATH=/home/user/software/em/gctf-1.18/bin/Gctf_v1.18_sm30-75_cu10.1
# name_of_the_movie sampling_rate downsampling voltage gctf_dstep gctf_resL gctf_resH gctf_B_resH
declare -a MOVIES=("10196 0.745000 2.3489933 200.000000 3.725000 50.000000 3.920000 1.490000" "10288 0.860000 2.034884 300.000000 4.300000 43.000000 4.100000 1.720000" "10314 1.120000 1.562500 300.000000 5.600000 50.000000 4.000000 2.240000")

#set -x # show commands

BENCHMARK=./tmp_bench.txt
PARENT_DIR="$(dirname "$(dirname "$(readlink -fm "$0")")")"

# add programs to path
source $XMIPP_PATH/build/xmipp.bashrc

generate_full_image() {
	in="$1"
	out=${1/.mrc/.jpg}
	xmipp_image_convert -i $in -o $out
}

generate_windows() {
	in="$1"
	out_tl=${1/.mrc/_tl.jpg}
	xmipp_transform_window -i $in --corners 0 0 511 511 --physical -o $out_tl
	out_center=${1/.mrc/_ce.jpg}
	xmipp_transform_window -i $in --size 512 512 -o $out_center
	size=$(xmipp_image_header "$1" | head -n 11 | tail -n -1) # Dimensions     : 1 x 1 x 7676 x 7420  ((N)Objects x (Z)Slices x (Y)Rows x (X)Columns)
	read -a strarr <<< $size
	x=${strarr[8]}
	y=${strarr[6]}
	out_br=${1/.mrc/_br.jpg}
	xmipp_transform_window -i $in --corners $(($x-512)) $(($y-512)) $(($x-1)) $(($y-1)) --physical -o $out_br
	# merge them
	out=${1/.mrc/_windows.jpg}
	convert +append $out_tl $out_center $out_br -border 10x0 $out
	rm $out_tl $out_center $out_br
}

generate_histogram() {
	in="$1"
	hist=${1/.mrc/_hist.txt}
	out=${1/.mrc/_hist.png}
	xmipp_image_histogram -i $in -o $hist
	gnuplot -p histogram.plot < $hist
	mv 'histogram.png' $out
	rm $hist
}

generate_preview() {
	in="$1"
	norm=${1/.mrc/_norm.mrc}
	# normalize entire micrograph
	xmipp_transform_normalize --method OldXmipp -i $in -o $norm
	tmp=${1/.mrc/_tmp.jpg}
	# crop a window
	xmipp_transform_window -i $norm --size 640 640 -o $tmp
	hist=${1/.mrc/_hist.png}
	out=${1/.mrc/_preview.jpg}
	convert $tmp -gravity southeast $hist -composite $out
	rm $tmp $norm $hist
}

generate_psd() {
	in="$1"
	# compute PSD
	psd=${1/.mrc/.psd}
	xmipp_psd_estimate -i $in -o $psd
	# generate data
	xmp=${1/.mrc/_psd.xmp}
	xmipp_image_operate -i $psd --psd_radial_avg -o $xmp
	rm $xmp $psd # there will be .txt file that we're interested in
}

generate_ctf() {
	in="$1"
	dir="$(dirname $in)"/ctf
	mkdir $dir
	donwscaled=$(basename -- $in)
	sampling=$(echo "$2 * $3" | bc)
	xmipp_transform_downsample -i $in -o $dir/$donwscaled --step $3 --method fourier
	xmipp_ctf_estimate_from_micrograph --micrograph $dir/$donwscaled --oroot $dir/ctf --sampling_rate $sampling --defocusU 21250.000000 --defocus_range 18750.000000 --overlap 0.7 --pieceDim 512 --ctfmodelSize 512 --acceleration1D  --kV $4 --Cs 2.7 --Q0 0.1 --min_freq 0.05 --max_freq 0.35 --downSamplingPerformed $3 --selfEstimation  --skipBorders 0
	ctfparam=$dir/ctf.ctfparam
	ctfxmd=$dir/ctf.xmd
	cp $ctfparam $ctfxmd
	echo " _ctfModel $ctfparam" >> $ctfxmd
	echo " _image1 $dir/ctf_ctfmodel_quadrant.xmp" >> $ctfxmd
	echo " _image2 $dir/ctf_ctfmodel_halfplane.xmp" >> $ctfxmd
	echo " _micrograph $dir/$donwscaled" >> $ctfxmd
	echo " _psd $dir/ctf.psd" >> $ctfxmd
	echo " _psdEnhanced $dir/ctf_enhanced_psd.xmp" >> $ctfxmd
	xmipp_ctf_sort_psds -i $ctfxmd
	xmipp_metadata_utilities -i $ctfxmd --operate keep_column "ctfCritMaxFreq" -o $dir/freq.xmd
	res=${in/.mrc/.maxFreq}
	tail -n 1 $dir/freq.xmd > $res
	rm -rf $dir
}

generate_gctf() {
	$GCTF_PATH --apix $2 --kV $4 --cs 2.700000 --ac 0.100000 --dstep $5 --defL 5000.000000 --defH 90000.000000 --defS 500.000000 --astm 1000.000000 --resL $6 --resH $7 --do_EPA 1 --boxsize 1024 --plot_res_ring 1 --gid 0 --bfac 150 --B_resH $8 --overlap 0.500000 --convsize 85 --do_Hres_ref 0 --smooth_resL 1000 --EPA_oversmp 4 --ctfstar NONE --do_validation 0 $1
	dir="$(dirname $1)"
	rm $dir/*.epa $dir/*.pow $dir/*EPA.log
}

shopt -s globstar
#: <<'END'
RESULT_DIR=$PARENT_DIR/$MACHINE/phantom_movies
for i in $RESULT_DIR/**/*.mrc; do
    echo Processing $i
    generate_full_image "$i"
    generate_windows "$i"
    generate_histogram "$i"
    generate_preview "$i"
    generate_psd "$i"
done
#END

#: <<'END'
RESULT_DIR=$PARENT_DIR/$MACHINE/empiar_movies
for i in $RESULT_DIR/**/*.mrc; do
    echo Processing $i
    generate_full_image "$i"
    generate_windows "$i"
    generate_histogram "$i"
    generate_preview "$i"
    generate_psd "$i"
done
#END

#: <<'END'
RESULT_DIR=$PARENT_DIR/$MACHINE/empiar_movies
for rec in "${MOVIES[@]}"; do
	read -a strarr <<< $rec
	for i in $RESULT_DIR/${strarr[0]}/**/*_avg.mrc; do
		generate_ctf "$i" ${strarr[1]} ${strarr[2]} ${strarr[3]}
		generate_gctf "$i" ${strarr[1]} ${strarr[2]} ${strarr[3]} ${strarr[4]} ${strarr[5]} ${strarr[6]} ${strarr[7]}
	done
done
#END

