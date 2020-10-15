## optional arg KERNEL_FILE to estimate kernel from instead of full image

args <- commandArgs(TRUE)
str(args)
if (!(length(args) %in% c(3, 4)))
{
    cat("\nUsage: Rscript denoise-image <FILE> <LAMBDA> <TYPE=grayscale|color> [<KERNEL_FILE>=<FILE>] \n\n")
    q()
} 

METHOD <- Sys.getenv("METHOD", "direct") # "iterative"
PATCH <- if (METHOD == "direct") 150 else 300

suppressMessages(library(rip.recover))

INFILE <- args[1]
LAMBDA <- as.numeric(args[2])
TYPE <- args[3]
KERNEL_FILE <- if (length(args) == 4) args[4] else NULL
ETA <- 0.005
ZAP.DIGITS <- 2

GAMMA <- 2.2
NITER.RL <- 25
rho.iid <- list(along = 0, across = 0) # IID parameters
rho.ar <- list(along = 0.3, across = 0.6) # AR parameters

y <- rip.import(INFILE, type = TYPE) / 255
y[] <- y^(1/GAMMA)

yy <- if (is.null(KERNEL_FILE)) y else (rip.import(KERNEL_FILE, type = TYPE) / 255)^(1/GAMMA)

k <- symmetric.blur(rip.desaturate(yy), c(5, 5),
                    g.method = "autoreg",
                    eta.sq = ETA^2,
                    corr.grad = TRUE,
                    trim = (METHOD == "direct"), zap.digits = ZAP.DIGITS)

OUTDIR <- sprintf("autoreg-kernel-%g", ETA)
if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

OUTDIR <- file.path(OUTDIR, sprintf("%s-%g", METHOD, LAMBDA))
if (!dir.exists(OUTDIR)) dir.create(OUTDIR)


fout <- function(s) file.path(OUTDIR, sprintf("%s-%s-%s.jpg", INFILE, TYPE, s))
fexists <- function(label) {
    message(fout(label))
    file.exists(fout(label))
}
fexport <- function(x, label = deparse(substitute(x)))
{
    rip.export(round(255 * x^GAMMA), file = fout(label))
}

## fexport(y, label = "000-original")

if (!fexists("rl"))
{
    rl <- rip.deconvlucy(y, k, niter = NITER.RL)
    fexport(rl)
}
if (!fexists("giid"))
{
    giid <-
        rip.denoise(y, alpha = 2, lambda = LAMBDA, rho = rho.iid, method = METHOD,
                    k = k, patch = PATCH, overlap = 20, verbose = TRUE)
    fexport(giid)
}
if (!fexists("gar"))
{
    gar <-
        rip.denoise(y, alpha = 2, lambda = LAMBDA, rho = rho.ar, method = METHOD,
                    k = k, patch = PATCH, overlap = 20, verbose = TRUE)
    fexport(gar)
}
if (!fexists("sar"))
{
    sar <-
        rip.denoise(y, alpha = 0.8, lambda = LAMBDA, rho = rho.ar, method = METHOD,
                    k = k, patch = PATCH, overlap = 20, verbose = TRUE)
    fexport(sar)
}
if (!fexists("siid"))
{
    siid <-
        rip.denoise(y, alpha = 0.8, lambda = LAMBDA, rho = rho.iid, method = METHOD,
                    k = k, patch = PATCH, overlap = 20, verbose = TRUE)
    fexport(siid)
}

