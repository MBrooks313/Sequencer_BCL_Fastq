#!/bin/bash

dir=240910_VH00437_81_2223KW3NX
sampsheet=240910_SampleSheet_v2.csv
anal_num=3

#-------------------------------------#

mkdir -p $dir/Analysis/$anal_num/Data

/Applications/bin/bcl-convert \
--bcl-input-directory $dir \
--output-directory $dir/Analysis/$anal_num/Data/fastq \
--sample-sheet $dir/$sampsheet \
--no-lane-splitting true \
--force true

mv $dir/Analysis/$anal_num/Data/fastq/Reports $dir/Analysis/$anal_num/Data/
cp $dir/$sampsheet $dir/Analysis/$anal_num/Data/SampleSheet.csv
