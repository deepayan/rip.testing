#!/usr/bin/env bash

## command line to reproduce by-parts results: Estimate kernel
## separately for each patch

export METHOD=direct

for L in 0.01 0.001; do 
    Rscript denoise-by-parts.R nayak-1.jpg $L grayscale
    Rscript denoise-by-parts.R nayak-2.jpg $L grayscale
    Rscript denoise-by-parts.R chebolu-moon.jpg $L grayscale
done




