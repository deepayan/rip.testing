
args <- commandArgs(TRUE)
str(args)
if (length(args) != 3)
{
    cat("\nUsage: Rscript upscale-images <KBW> <LAMBDA> <FILE>\n\n")
    q()
}

KBW <- as.numeric(args[1])
LAMBDA <- as.numeric(args[2])
INFILE <- args[3]
ETA <- 0.005

FACTOR <- 2
METHOD <- Sys.getenv("METHOD", "direct") # "iterative"

## Other parameters

rho.iid <- list(along = 0, across = 0) # IID parameters
rho.ar <- list(along = 0.3, across = 0.6) # AR parameters
PATCH <- if (METHOD == "iterative") 300 else 150

if (!(FACTOR %in% c(2, 3))) stop("FACTOR must be 2 or 3")

suppressMessages(library(rip.recover))
options(rip.cache.dir = ".")

y <- rip.import(INFILE, type = "grayscale") / 255

if (KBW < 0)
    k.used <-
        symmetric.blur(rip.desaturate(y), kdim = c(7, 7),
                       resize = FACTOR, g.method = "autoreg",
                       eta.sq = ETA^2, corr.grad = TRUE,
                       trim = (METHOD == "direct"), zap.digits = 1)

    
OUTDIR <- if (KBW < 0) sprintf("autoreg-kernel-%g", ETA) else as.character(KBW)
if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

fout <- function(s) file.path(OUTDIR, sprintf("%s-%dx-%s-%g-%s.jpg",
                                              INFILE, FACTOR, METHOD, LAMBDA, s))
fexists <- function(label) {
    message(fout(label))
    file.exists(fout(label))
}

fexport <- function(x, label = deparse(substitute(x)))
{
    rip.export(round(255 * x), file = fout(label))
}

message("Processing image ", INFILE)
fexport(rip.resize(y, fx = FACTOR, method = "cubic"), label = "00-original")
if (!fexists("giid"))
{
    giid <- 
        rip.upscale(y, factor = FACTOR, alpha = 2, lambda = LAMBDA,
                    method = METHOD, rho = rho.iid,
                    k = if (KBW < 0) k.used else NULL,
                    kbw = KBW, patch = PATCH / FACTOR, overlap = 10, verbose = TRUE)
    fexport(giid)
}
if (!fexists("gar"))
{
    gar <- 
        rip.upscale(y, factor = FACTOR, alpha = 2, lambda = LAMBDA,
                    method = METHOD, rho = rho.ar,
                    k = if (KBW < 0) k.used else NULL,
                    kbw = KBW, patch = PATCH / FACTOR, overlap = 10, verbose = TRUE)
    fexport(gar)
}
if (!fexists("siid"))
{
    siid <- 
        rip.upscale(y, factor = FACTOR, alpha = 0.8, lambda = LAMBDA,
                    method = METHOD, rho = rho.iid,
                    k = if (KBW < 0) k.used else NULL,
                    kbw = KBW, patch = PATCH / FACTOR, overlap = 10, verbose = TRUE)
    fexport(siid)
}
if (!fexists("sar"))
{
    sar <- 
        rip.upscale(y, factor = FACTOR, alpha = 0.8, lambda = LAMBDA,
                    method = METHOD, rho = rho.ar,
                    k = if (KBW < 0) k.used else NULL,
                    kbw = KBW, patch = PATCH / FACTOR, overlap = 10, verbose = TRUE)
    fexport(sar)
}

