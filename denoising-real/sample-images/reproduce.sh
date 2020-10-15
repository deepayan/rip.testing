#!/usr/bin/env bash

## Can run with METHOD=iterative, but results not shown on website

export METHOD=direct

## h=0.35 is just degenerate kernel; done this way to compare with 2x
## and 3x upscaling

for KBW in 0.35 0.7 1.4 -1; do
    for L in 0.01 0.001; do
	Rscript test-sample-images.R $KBW $L
    done
done


