#!/usr/bin/env bash

## Run with ESTKERN=TRUE and ESTKERN=FALSE

export ESTKERN=TRUE 

## S = 10

for L in 0.01 0.001; do
    Rscript test-combinations.R 10 $L direct
done

for L in 0.01 0.001; do
    Rscript test-combinations.R 10 $L iterative
done

## S = 100

for L in 0.01 0.001; do
    Rscript test-combinations.R 100 $L direct
done

for L in 0.01 0.001; do
    Rscript test-combinations.R 100 $L iterative
done

