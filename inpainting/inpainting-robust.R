## main problem is to find a mask corresponding to the mesh

args <- commandArgs(TRUE)
str(args)
if (length(args) != 3)
{
    cat("\nUsage: Rscript ./inpainting-robust.R <FILE> <LAMBDA> <THRESHOLD> \n\n")
    q()
} 

INFILE <- args[1]
LAMBDA <- as.numeric(args[2])
THRESHOLD <- as.numeric(args[3])
KBW <- as.numeric(Sys.getenv("KBW", "1.5"))
GAMMA <- 2.2
rho.iid <- list(along = 0, across = 0) # IID parameters
rho.ar <- list(along = 0.3, across = 0.6) # AR parameters

suppressMessages(library(rip.recover))

COLOR <- TRUE

OUTDIR <- sprintf("epanechnikov-%g", KBW)
if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

fout <- function(s) file.path(OUTDIR,
                              sprintf("%s-%g-%g-%s.jpg",
                                      INFILE, THRESHOLD, LAMBDA, s))
fexists <- function(label) {
    message(fout(label))
    file.exists(fout(label))
}
fexport <- function(x, label = deparse(substitute(x)))
{
    rip.export(round(255 * x^GAMMA), file = fout(label))
}

y <- rip.import(INFILE, "color")

mask <- rip.desaturate(y) > THRESHOLD * 255
mask01 <- as.rip(mask * 1)
## image(mask01)

## set any neighbour within 2 pixels to also be NA
mask01[] <- as.numeric(rip.filter(mask01, k = as.rip(matrix(1, 5, 5))) > 0)
image(mask01)

## and then any within 2 pixels of those
mask01[] <- as.numeric(rip.filter(mask01, k = as.rip(matrix(1, 5, 5))) > 0)
image(mask01)

## OpenCV inpainting

if (!fexists("incv"))
{
    incv <- rip.cv$photo$inpaint(y, mask01, radius = 20)
    incv[] <- (incv/255)^(1/GAMMA)
    fexport(incv)
    if (!fexists("incv.robust"))
    {
        incv.robust <-
            rip.denoise(incv, kbw = 0, method = "direct", verbose = TRUE,
                        patch = 300, overlap = 20,
                        yerror = "huber", huber.k = 1,
                        lambda = LAMBDA, alpha = 2, rho = rho.iid)
        fexport(incv.robust)
    }
}


    
y[] <- (y/255)^(1/GAMMA)

if (COLOR)
{
    tmp <- y # or as.array(y) -> NA -> as.rip()
    is.na(tmp[, c(T, F, F)]) <- mask01 > 0
    is.na(tmp[, c(F, T, F)]) <- mask01 > 0
    is.na(tmp[, c(F, F, T)]) <- mask01 > 0
} else
{
    tmp <- rip.desaturate(y)
    is.na(tmp) <- mask01 > 0
}

## image(255 * rip.desaturate(tmp), rescale = FALSE)

if (!fexists("giid"))
{
    giid <-
        rip.denoise(tmp, kbw = KBW, method = "direct", verbose = TRUE,
                    patch = 300, overlap = 20,
                    lambda = LAMBDA, alpha = 2, rho = rho.iid)
    ## image(giid * 255, rescale = FALSE)
    fexport(giid)
}

if (!fexists("giid.robust"))
{
    giid.robust <-
        rip.denoise(tmp, kbw = KBW, method = "direct", verbose = TRUE,
                    patch = 300, overlap = 20,
                    yerror = "huber", huber.k = 1,
                    lambda = LAMBDA, alpha = 2, rho = rho.iid)
    fexport(giid.robust)
}


if (!fexists("sar"))
{
    sar <-
        rip.denoise(tmp, kbw = KBW, method = "direct", verbose = TRUE,
                    patch = 300, overlap = 20,
                    lambda = LAMBDA, alpha = 0.8, rho = rho.ar)
    fexport(sar)
}
    
if (!fexists("sar.robust"))
{
    sar.robust <-
        rip.denoise(tmp, kbw = KBW, method = "direct", verbose = TRUE,
                    patch = 300, overlap = 20,
                    yerror = "huber", huber.k = 1,
                    lambda = LAMBDA, alpha = 0.8, rho = rho.ar)
    fexport(sar.robust)
}


