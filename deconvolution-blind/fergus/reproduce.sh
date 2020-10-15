## Run with METHOD=direct and METHOD=iterative

export METHOD=direct

Rscript deconv-image.R mukta1_blurry.jpg fergus_mukta1_kernel.ppm 0.01
Rscript deconv-image.R mukta1_blurry.jpg fergus_mukta1_kernel.ppm 0.001

Rscript deconv-image.R lyndsey2_blurry.jpg fergus_lyndsey2_kernel.ppm 0.01
Rscript deconv-image.R lyndsey2_blurry.jpg fergus_lyndsey2_kernel.ppm 0.001

Rscript deconv-image.R fountain_blurry.png fergus_fountain_kernel.ppm 0.01
Rscript deconv-image.R fountain_blurry.png fergus_fountain_kernel.ppm 0.001




