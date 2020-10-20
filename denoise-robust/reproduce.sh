#!/usr/bin/env bash

# ln -s ../rip.testing/denoising-real/real-blurred/autoreg-kernel-0.005/direct-0.001/bk-electric-house.png-grayscale-giid.jpg .
# ln -s ../rip.testing/deconvolution-blind/fergus/direct/lyndsey2_blurry.jpg-0.01-rl.jpg .

export LAMBDA=0.001

for F in bk-electric-house.png-grayscale-gar.jpg \
	     coffee-house.jpg \
	     lyndsey2_blurry.jpg-0.01-rl.jpg; do
    HUBERK=10 Rscript denoise-robust.R $F
    HUBERK=1 Rscript denoise-robust.R $F
    HUBERK=0.5 Rscript denoise-robust.R $F
done
    
