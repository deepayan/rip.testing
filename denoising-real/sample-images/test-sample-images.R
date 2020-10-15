
args <- commandArgs(TRUE)
if (length(args) != 2)
{
    cat("\nUsage: Rscript test-sample-images <KBW> <LAMBDA>\n\n")
    q()
} 

KBW <- as.numeric(args[1])
LAMBDA <- as.numeric(args[2])
ETA <- 0.005
rho.iid <- list(along = 0, across = 0) # IID parameters
rho.ar <- list(along = 0.3, across = 0.6) # AR parameters

suppressMessages(library(rip.recover))

load("../../deconvolution-synthetic/sample-images/sample.images.rda")

METHOD <- Sys.getenv("METHOD", "iterative") # "direct"

OUTDIR <-
    (if (KBW < 0) sprintf("autoreg-kernel-%g-%g", ETA, LAMBDA)
     else sprintf("epanechnikov-%g-%g", KBW, LAMBDA))

if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

fout <- function(s) file.path(OUTDIR, sprintf("%d-%s-%s.jpg", i, METHOD, s))
fexists <- function(label) {
    message(fout(label))
    file.exists(fout(label))
}

fexport <- function(x, label = deparse(substitute(x)))
{
    rip.export(round(255 * x), file = fout(label))
}

for (i in seq_along(sample.images))
{
    message("Processing image ", i)
    y <- sample.images[[i]] / 255
    fexport(y, label = "00-original")
    k.used <- 
        symmetric.blur(rip.desaturate(y), kdim = c(5, 5),
                       g.method = "autoreg",
                       eta.sq = ETA^2,
                       corr.grad = TRUE,
                       trim = (METHOD == "direct"), zap.digits = 1)
    if (!fexists("giid"))
    {
        giid <- 
            rip.denoise(y, alpha = 2, lambda = LAMBDA, rho = rho.iid, method = METHOD,
                        k = if (KBW < 0) k.used else NULL,
                        kbw = KBW, patch = 150, overlap = 10, verbose = TRUE)
        fexport(giid)
    }
    if (!fexists("gar"))
    {
        gar <- 
            rip.denoise(y, alpha = 2, lambda = LAMBDA, rho = rho.ar, method = METHOD,
                        k = if (KBW < 0) k.used else NULL,
                        kbw = KBW, patch = 150, overlap = 10, verbose = TRUE)
        fexport(gar)
    }
    if (!fexists("siid"))
    {
        siid <- 
            rip.denoise(y, alpha = 0.8, lambda = LAMBDA, rho = rho.iid, method = METHOD,
                        k = if (KBW < 0) k.used else NULL,
                        kbw = KBW, patch = 150, overlap = 10, verbose = TRUE)
        fexport(siid)
    }
    if (!fexists("sar"))
    {
        sar <- 
            rip.denoise(y, alpha = 0.8, lambda = LAMBDA, rho = rho.ar, method = METHOD,
                        k = if (KBW < 0) k.used else NULL,
                        kbw = KBW, patch = 150, overlap = 10, verbose = TRUE)
        fexport(sar)
    }
}

