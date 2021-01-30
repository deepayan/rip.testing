#!/usr/bin/env bash

## Run with LAMBDA=0.01, 0.001 and THRESHOLD=0.65, 0.7

# for LAMBDA in 0.01 0.001; do
#     for THRESHOLD in 0.65 0.7; do
# 	Rscript inpainting-robust.R mesh.jpg $LAMBDA $THRESHOLD
#     done
# done



for LAMBDA in 0.01 0.001; do
    for INFILE in barbara.png monarch.png einstein.png gibbon.png castle.png kid.png; do
	Rscript inpainting-black.R $INFILE $LAMBDA
    done
done


