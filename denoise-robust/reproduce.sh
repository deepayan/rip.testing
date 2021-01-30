#!/usr/bin/env bash

# ln -s ../rip.testing/denoising-real/real-blurred/autoreg-kernel-0.005/direct-0.001/bk-electric-house.png-grayscale-giid.jpg .
# ln -s ../rip.testing/deconvolution-blind/fergus/direct/lyndsey2_blurry.jpg-0.01-rl.jpg .

# Run with LAMBDA=0.01 and 0.001

export LAMBDA=0.02

for F in bk-electric-house.png-grayscale-gar.jpg \
	     bk-electric-house.png-2x-direct-0.001-gar.jpg \
	     wiki_bm3d_example.jpg \
	     coffee-house.jpg \
	     lyndsey2_blurry.jpg-0.01-rl.jpg; do
    HUBERK=10 Rscript denoise-robust.R $F
    HUBERK=1 Rscript denoise-robust.R $F
    HUBERK=0.5 Rscript denoise-robust.R $F
    Rscript denoise-opencv.R $F
done

for F in image--013.png image--019.png; do
    HUBERK=10 Rscript denoise-robust.R $F
    HUBERK=1 Rscript denoise-robust.R $F
    HUBERK=0.5 Rscript denoise-robust.R $F
    Rscript denoise-opencv.R $F
done
    

