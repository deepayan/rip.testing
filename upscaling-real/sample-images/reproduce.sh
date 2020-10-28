#!/usr/bin/env bash

## Run with METHOD=iterative and METHOD=direct (but iterative not shown on website)
export METHOD=iterative

for KBW in 0.35 -1; do
    for FACTOR in 2 1 3; do
	Rscript test-sample-images.R $KBW $FACTOR 0.01;
	Rscript test-sample-images.R $KBW $FACTOR 0.001;
    done;
done

## separately just so we can parallelize

for KBW in 0.7 1.4; do
    for FACTOR in 2 1 3; do
	Rscript test-sample-images.R $KBW $FACTOR 0.01;
	Rscript test-sample-images.R $KBW $FACTOR 0.001;
    done;
done

