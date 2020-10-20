args <- commandArgs(TRUE)

INFILE <- Sys.getenv("INFILE", args[1])
LAMBDA <- as.numeric(Sys.getenv("LAMBDA", "0.01"))
METHOD <- "direct"
rho.iid <- list(along = 0, across = 0) # IID parameters
rho.ar <- list(along = 0.3, across = 0.6) # AR parameters
HUBER.K <- as.numeric(Sys.getenv("HUBERK", "1"))
GAMMA <- 2.2

OUTDIR <- sprintf("robust-%g", LAMBDA)
if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

fout <- function(s) file.path(OUTDIR, sprintf("%s-%s-%g-%g-%s.jpg",
                                              INFILE, METHOD, LAMBDA, HUBER.K, s))
fexists <- function(label) {
    message(fout(label))
    file.exists(fout(label))
}

fexport <- function(x, label = deparse(substitute(x)))
{
    rip.export(round(255 * x^GAMMA), file = fout(label))
}

suppressMessages(library(rip.recover))

y <- rip.import(INFILE, type = "original") / 255
y[] <- y^(1/GAMMA)

if (!fexists("sar"))
{
    sar <- 
        rip.denoise(y, alpha = 0.6, lambda = LAMBDA,
                    method = METHOD, rho = rho.ar,
                    yerror = "huber", huber.k = HUBER.K,
                    kbw = 0, patch = 200, overlap = 10, verbose = TRUE)
    fexport(sar)
}

