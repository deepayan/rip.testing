
## Estimate kernel from each patch. This is not directly supported by
## the package yet, so we need to do the splitting / merging ourselves

## optional arg KERNEL_FILE to estimate kernel from instead of full image

args <- commandArgs(TRUE)
str(args)
if (!(length(args) %in% c(3, 4)))
{
    cat("\nUsage: Rscript denoise-image <FILE> <LAMBDA> <TYPE=grayscale|color> \n\n")
    q()
} 

METHOD <- Sys.getenv("METHOD", "direct") # "iterative"
PATCH <- if (METHOD == "direct") 150 else 300

suppressMessages(library(rip.recover))

INFILE <- args[1]
LAMBDA <- as.numeric(args[2])
TYPE <- args[3]

ETA <- 0.005
ZAP.DIGITS <- 2
GAMMA <- 2.2
NITER.RL <- 25
rho.iid <- list(along = 0, across = 0) # IID parameters
rho.ar <- list(along = 0.3, across = 0.6) # AR parameters

y <- rip.import(INFILE, type = TYPE) / 255
y[] <- y^(1/GAMMA)

## only grayscale for now
ysplit <- rip.recover:::splitImage(y, patch = 250, overlap = 50)

ksplit <-
    lapply(lapply(ysplit, as.rip), symmetric.blur,
           kdim = c(5, 5), g.method = "autoreg",
           rho.along = 0.3, rho.across = 0.6,
           eta.sq = ETA^2, corr.grad = TRUE,
           trim = (METHOD == "direct"), zap.digits = ZAP.DIGITS)
dim(ksplit) <- dim(ysplit)

## zapsmallp() but don't trim for method=iterative: check if this helps with artifacts

## if (METHOD == "iterative")
##     for (i in seq_along(ksplit))
##         ksplit[[i]] <- zapsmallp(ksplit[[i]], digits = ZAP.DIGITS)

png(sprintf("%s-kernels.png", INFILE), width = 1000, height = 1000)
par(mfrow = rev(dim(ysplit)), oma = rep(0, 4), mai = rep(0, 4), mar = rep(0, 4))
invisible(lapply(t(ksplit), image, axes = FALSE))
dev.off()

OUTDIR <- sprintf("byparts-autoreg-kernel-%g", ETA)
if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

OUTDIR <- file.path(OUTDIR, sprintf("%s-%g", METHOD, LAMBDA))
if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

fout <- function(s) file.path(OUTDIR, sprintf("%s-%s-%s.jpg", INFILE, TYPE, s))
fexists <- function(label) {
    ans <- file.exists(fout(label))
    message(sprintf("%s: ", fout(label), if (ans) "exists" else "estimating"))
    ans
}
fexport <- function(x, label = deparse(substitute(x)))
{
    rip.export(round(255 * x^GAMMA), file = fout(label))
}

## fexport(y, label = "000-original")

if (!fexists("rl"))
{
    rl.split <- ysplit
    for (i in seq_along(ysplit))
    {
        message(i, " / ", length(ysplit))
        rl.split[[i]] <- 
            rip.deconvlucy(ysplit[[i]], ksplit[[i]], niter = NITER.RL)
    }
    rl <- rip.recover:::unsplitImage(rl.split)
    fexport(rl)
}

if (!fexists("giid"))
{
    giid.split <- ysplit
    for (i in seq_along(ysplit))
    {
        message(i, " / ", length(ysplit))
        giid.split[[i]] <- 
            rip.denoise(as.rip(ysplit[[i]]), alpha = 2, lambda = LAMBDA,
                        rho = rho.iid, method = METHOD,
                        k = ksplit[[i]], patch = PATCH, overlap = 20, verbose = TRUE)
    }
    giid <- rip.recover:::unsplitImage(giid.split)
    fexport(giid)
}

if (!fexists("gar"))
{
    gar.split <- ysplit
    for (i in seq_along(gar.split))
    {
        message(i, " / ", length(ysplit))
        gar.split[[i]] <- 
            rip.denoise(as.rip(ysplit[[i]]), alpha = 2, lambda = LAMBDA,
                        rho = rho.ar, method = METHOD,
                        k = ksplit[[i]], patch = PATCH, overlap = 20, verbose = TRUE)
    }
    gar <- rip.recover:::unsplitImage(gar.split)
    fexport(gar)
}

if (!fexists("siid"))
{
    siid.split <- ysplit
    for (i in seq_along(siid.split))
    {
        message(i, " / ", length(ysplit))
        siid.split[[i]] <- 
            rip.denoise(as.rip(ysplit[[i]]), alpha = 0.8, lambda = LAMBDA,
                        rho = rho.iid, method = METHOD,
                        k = ksplit[[i]], patch = PATCH, overlap = 20, verbose = TRUE)
    }
    siid <- rip.recover:::unsplitImage(siid.split)
    fexport(siid)
}

if (!fexists("sar"))
{
    sar.split <- ysplit
    for (i in seq_along(ysplit))
    {
        message(i, " / ", length(ysplit))
        sar.split[[i]] <- 
            rip.denoise(as.rip(ysplit[[i]]), alpha = 0.8, lambda = LAMBDA,
                        rho = rho.ar, method = METHOD,
                        k = ksplit[[i]], patch = PATCH, overlap = 20, verbose = TRUE)
    }
    sar <- rip.recover:::unsplitImage(sar.split)
    fexport(sar)
}


