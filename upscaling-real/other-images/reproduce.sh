#!/usr/bin/env bash

## Run with METHOD=iterative and METHOD=direct

export METHOD=iterative

for LAMBDA in 0.01 0.001; do
    for FILE in Im_24.png Im_6.png bk-electric-house.png; do
	Rscript upscale-images.R -1 ${LAMBDA} $FILE;
    done
done

for LAMBDA in 0.01 0.001; do
    for FILE in Im_24.png Im_6.png bk-electric-house.png; do
	Rscript upscale-images.R 2 ${LAMBDA} $FILE;
    done
done

for LAMBDA in 0.01 0.001; do
    for FILE in Im_24.png Im_6.png bk-electric-house.png; do
	Rscript upscale-images.R 1.5 ${LAMBDA} $FILE;
    done
done

for LAMBDA in 0.01 0.001; do
    for FILE in Im_24.png Im_6.png bk-electric-house.png; do
	Rscript upscale-images.R 1 ${LAMBDA} $FILE;
    done
done

