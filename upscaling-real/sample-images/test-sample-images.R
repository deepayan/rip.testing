
args <- commandArgs(TRUE)
if (length(args) != 3)
{
    cat("\nUsage: ./test-sample-images <KBW> <FACTOR> <LAMBDA>\n\n")
    q()
} 

KBW <- as.numeric(args[1])
FACTOR <- as.integer(args[2])
LAMBDA <- as.numeric(args[3])
ETA <- 0.005
rho.iid <- list(along = 0, across = 0) # IID parameters
rho.ar <- list(along = 0.3, across = 0.6) # AR parameters

if (!(FACTOR %in% c(1, 2, 3))) stop("FACTOR must be 2 or 3")

suppressMessages(library(rip.recover))
load("../../deconvolution-synthetic/sample-images/sample.images.rda")
options(rip.cache.dir = ".")

METHOD <- Sys.getenv("METHOD", "iterative") # "direct"

OUTDIR <-
    (if (KBW < 0) sprintf("autoreg-kernel-%g-%g", ETA, LAMBDA)
     else sprintf("epanechnikov-%g-%g", KBW, LAMBDA))

if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

fout <- function(s) file.path(OUTDIR, sprintf("%d-%dx-%s-%s.jpg", i, FACTOR, METHOD, s))
fexists <- function(label) {
    message(fout(label))
    file.exists(fout(label))
}

fexport <- function(x, label = deparse(substitute(x)))
{
    rip.export(round(255 * x), file = fout(label))
}

for (i in rev(seq_along(sample.images)))
{
    message("Processing image ", i)
    y <- sample.images[[i]] / 255
    if (FACTOR == 1) 
        fexport(y, label = "00-original")
    else
        fexport(rip.resize(y, FACTOR * dim(y), method = "cubic"), label = "00-original")
    k.used <- 
        symmetric.blur(rip.desaturate(y), kdim = c(5, 5), resize = FACTOR,
                       g.method = "autoreg",
                       eta.sq = ETA^2,
                       corr.grad = TRUE,
                       trim = (METHOD == "direct"), zap.digits = 1)
    if (!fexists("giid"))
    {
        giid <- 
            rip.upscale(y, factor = FACTOR, alpha = 2, lambda = LAMBDA,
                        rho = rho.iid, method = METHOD,
                        k = if (KBW < 0) k.used else NULL,
                        kbw = KBW, patch = 150 / FACTOR, overlap = 10, verbose = TRUE)
        fexport(giid)
    }
    if (!fexists("gar"))
    {
        gar <- 
            rip.upscale(y, factor = FACTOR, alpha = 2, lambda = LAMBDA,
                        rho = rho.ar, method = METHOD,
                        k = if (KBW < 0) k.used else NULL,
                        kbw = KBW, patch = 150 / FACTOR, overlap = 10, verbose = TRUE)
        fexport(gar)
    }
    if (!fexists("siid"))
    {
        siid <- 
            rip.upscale(y, factor = FACTOR, alpha = 0.8, lambda = LAMBDA,
                        rho = rho.iid, method = METHOD,
                        k = if (KBW < 0) k.used else NULL,
                        kbw = KBW, patch = 150 / FACTOR, overlap = 10, verbose = TRUE)
        fexport(siid)
    }
    if (!fexists("sar"))
    {
        sar <- 
            rip.upscale(y, factor = FACTOR, alpha = 0.8, lambda = LAMBDA,
                        rho = rho.ar, method = METHOD,
                        k = if (KBW < 0) k.used else NULL,
                        kbw = KBW, patch = 150 / FACTOR, overlap = 10, verbose = TRUE)
        fexport(sar)
    }
}

