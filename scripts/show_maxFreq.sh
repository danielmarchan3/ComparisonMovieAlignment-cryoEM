#!/bin/bash

[ -z "$MACHINE" ] && echo "Machine name dir not set (export MACHINE)" && exit 
declare -a MOVIES=("10196" "10288" "10314")
file_path="ctf_freq_summary.txt"

#set -x # show commands

BENCHMARK=./tmp_bench.txt
PARENT_DIR="$(dirname "$(dirname "$(readlink -fm "$0")")")"

RESULT_DIR=$PARENT_DIR/$MACHINE/empiar_movies
for mov in "${MOVIES[@]}"; do
	echo $mov
	for i in $RESULT_DIR/$mov/*_avg.maxFreq; do
		echo xmipp$'\t'$(cat $i)$'\t'$i >> ""$RESULT_DIR/$mov/xmipp_${mov}_${file_path}""
	done
	echo ""
	for i in $RESULT_DIR/$mov/*_avg_gctf.log; do
		line=$(tail -n 3 $i | head -n 1) # grab 3rd line from the end
		res=$(echo "$line" | awk '{print $NF}') # grab last word
		echo gctf$'\t'$res$'\t'$i >> ""$RESULT_DIR/$mov/gctf_${mov}_${file_path}""
	done
	echo ""
done
