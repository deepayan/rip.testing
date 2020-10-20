#!/usr/bin/env bash

## Run with LAMBDA=0.001 and LAMBDA=0.01, METHOD=direct and METHOD=iterative

export LAMBDA=0.01
export METHOD=direct

Rscript denoise-image.R butterfly2.jpg $LAMBDA color butterfly2-cropped.jpg

for FILE in cheetah2.jpg hyena2_med.jpg; do
    Rscript denoise-image.R $FILE $LAMBDA color;
done

Rscript denoise-image.R tutu.jpg $LAMBDA grayscale

Rscript denoise-image.R chebolu-moon.jpg $LAMBDA grayscale chebolu-moon-cropped.jpg

for FILE in nayak-1 nayak-2; do
    Rscript denoise-image.R ${FILE}.jpg $LAMBDA grayscale ${FILE}-cropped.jpg;
done

Rscript denoise-image.R bk-electric-house.png $LAMBDA grayscale

for FILE in mukta lyndsey2_blurry; do
    Rscript denoise-image.R ${FILE}.jpg $LAMBDA color ${FILE}-cropped.png;
done


