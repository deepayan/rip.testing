
args <- commandArgs(TRUE)
str(args)
if (length(args) != 3)
{
    cat("\nUsage: Rscript deconv-image.R <INPUT-FILE> <KERNEL-FILE> <LAMBDA> \n\n")
    q()
} 

suppressMessages(library(rip.recover))

INFILE <- args[1]
KERNFILE <- args[2]
LAMBDA <- as.numeric(args[3])

GAMMA <- 2.2
NITER.RL <- 50
rho.iid <- list(along = 0, across = 0) # IID parameters
rho.ar <- list(along = 0.3, across = 0.6) # AR parameters

y <- rip.import(INFILE, type = "color") / 255
y[] <- y^(1/GAMMA)

k <- rip.import(KERNFILE, type = "grayscale")
k[] <- k / sum(k)

METHOD <- Sys.getenv("METHOD", "iterative") # "direct"
OUTDIR <- METHOD

PATCH <- switch(METHOD, direct = 100, iterative = 300)

if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

fout <- function(s)
    file.path(OUTDIR, sprintf("%s-%g-%s.jpg", INFILE, LAMBDA, s))
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
        rip.deconv(y, alpha = 2, lambda = LAMBDA, rho = rho.iid, method = METHOD,
                   k = k, patch = PATCH, overlap = 40, verbose = TRUE)
    fexport(giid)
}
if (!fexists("gar"))
{
    gar <-
        rip.deconv(y, alpha = 2, lambda = LAMBDA, rho = rho.ar, method = METHOD,
                   k = k, patch = PATCH, overlap = 40, verbose = TRUE)
    fexport(gar)
}
if (!fexists("siid"))
{
    siid <-
        rip.deconv(y, alpha = 0.8, lambda = LAMBDA, rho = rho.iid, method = METHOD,
                   k = k, patch = PATCH, overlap = 40, verbose = TRUE)
    fexport(siid)
}
if (!fexists("sar"))
{
    sar <-
        rip.deconv(y, alpha = 0.8, lambda = LAMBDA, rho = rho.ar, method = METHOD,
                   k = k, patch = PATCH, overlap = 40, verbose = TRUE)
    fexport(sar)
}

