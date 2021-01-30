
args <- commandArgs(TRUE)
if (length(args) == 0)
{
    cat("\nUsage: Rscript test-combinations.R <S> <LAMBDA> <METHOD=direct>\n\n")
    q()
} 

suppressMessages(library(rip.recover))
options(rip.cache.dir = ".")

## additional images from Levin et al 2009
load("../../deconvolution-synthetic/sample-images/sample.images.rda") 

S <- as.numeric(args[1]) # noise in blurred image (try 100, 10)
LAMBDA <- as.numeric(args[2]) # tuning parameter ~ 0.01, 0.001
METHOD <- if (length(args) == 3) args[3] else "direct"

str(list(S = S, LAMBDA = LAMBDA, METHOD = METHOD))

## Other parameters

rho.iid <- list(along = 0, across = 0) # IID parameters
rho.ar <- list(along = 0.3, across = 0.6) # AR parameters
ZAPK.DIGITS <- 2 # 1 to be aggressive, 3 to keep essentially unchanged

SR.FACTOR <- 2
PATCH <- 45
OVERLAP <- 10


ESTIMATE.KERNEL <- as.logical(Sys.getenv("ESTKERN", "TRUE"))
ETA <- 0.005

OUTDIR <-
    file.path(if (ESTIMATE.KERNEL) sprintf("estimated-kernel-%g", ETA) else "true-kernel",
              sprintf("%s-%g-%g-%dx", METHOD, S, LAMBDA, SR.FACTOR))
if (!dir.exists(OUTDIR)) dir.create(OUTDIR, recursive = TRUE)

fout <- function(s) file.path(OUTDIR, sprintf("recovered-%d-%s.png", I, s))
fexists <- function(label, message = TRUE) {
    ans <- file.exists(fout(label))
    if (message)
        message(sprintf("%s: %s", fout(label),
                        if (ans) "exists" else "estimating"))
    ans
}

fexport <- function(x, label = deparse(substitute(x)))
{
    if (inherits(x, "try-error")) return()
    rip.export(round(255 * x), file = fout(label))
}

## NOTE: We add random noise, so setting seed is important to make
## sure we work on the same 'random' blurred images

tryq <- function(expr)
{
    call <- match.call()
    call[[1]] <- quote(try)
    call$silent <- TRUE
    ## print(call)
    eval.parent(call)
}

## kblur <- as.rip(matrix(1/(SR.FACTOR^2), SR.FACTOR, SR.FACTOR))
kblur <- make.kernel(h = 1.25, kern = "rect")
subsamp <- rep(FALSE, SR.FACTOR)
subsamp[ceiling(SR.FACTOR / 2)] <- TRUE


downsample <- function(x)
{
    xblur <- rip.conv(x, kblur, type = "same")
    as.rip(xblur[subsamp, subsamp])
}

set.seed(20200515)

pdf("kernels.pdf", width = 8, height = 5)
par(mfrow = c(1, 2))

for (I in seq_along(sample.images))
{
    message(sprintf("image: %d, factor: %s", I, SR.FACTOR))
    x <- sample.images[[I]]
    z <- downsample(x)
    y <- addPoissonNoise(z, S) # rescales to (0,1)
    fexport(y, "noisy")
    KERNEL.USED <-
        if (ESTIMATE.KERNEL)
            symmetric.blur(rip.resize(rip.desaturate(y), fx = SR.FACTOR),
                           kdim = c(2, 2), # results in 5x5 kernel
                           resize = 1, g.method = "autoreg",
                           eta.sq = ETA^2, corr.grad = TRUE,
                           trim = FALSE, zap.digits = ZAPK.DIGITS)
        else kblur
    image(-KERNEL.USED)
    image(-kblur)
    if (!fexists("giid"))
    {
        giid <- 
            tryq(rip.upscale(y, factor = SR.FACTOR, k = KERNEL.USED,
                             alpha = 2, lambda = LAMBDA,
                             rho = rho.iid, method = METHOD,
                             patch = PATCH, overlap = OVERLAP, verbose = TRUE))
        fexport(giid)
    }
    if (!fexists("gar"))
    {
        gar <- 
            tryq(rip.upscale(y, factor = SR.FACTOR, k = KERNEL.USED,
                             alpha = 2, lambda = LAMBDA,
                             rho = rho.ar, method = METHOD,
                             patch = PATCH, overlap = OVERLAP, verbose = TRUE))
        fexport(gar)
    }
    if (!fexists("siid"))
    {
        siid <- 
            tryq(rip.upscale(y, factor = SR.FACTOR, k = KERNEL.USED,
                             alpha = 0.8, lambda = LAMBDA,
                             rho = rho.iid, method = METHOD,
                             patch = PATCH, overlap = OVERLAP, verbose = TRUE))
        fexport(siid)
    }
    if (!fexists("sar"))
    {
        sar <- 
            tryq(rip.upscale(y, factor = SR.FACTOR, k = KERNEL.USED,
                             alpha = 0.8, lambda = LAMBDA,
                             rho = rho.ar, method = METHOD,
                             patch = PATCH, overlap = OVERLAP, verbose = TRUE))
        fexport(sar)
    }
}

## make one image each for noisy+4 priors, 8 images in a 2x4 layout.


out.list <- list(noisy = as.rip(matrix(1, 260 * 2, 260 * 4)))
for (s in c("giid", "gar", "siid", "sar"))
    out.list[[s]] <- out.list[["noisy"]]
for (I in seq_along(sample.images))
{
    II <- (I-1) %/% 4
    JJ <- (I-1) %% 4
    ## str(list(II = II, JJ = JJ))
    for (s in c("noisy", "giid", "gar", "siid", "sar"))
    {
        ## use first position to show kernel
        if (fexists(s, FALSE))
        {
            tmp <- rip.import(fout(s), type = "grayscale") / 255
            if (s == "noisy") tmp <- rip.resize(tmp, d = 2 * dim(tmp), method = "cubic")
            out.list[[s]][II * 260 + seq_len(nrow(tmp)),
                          JJ * 260 + seq_len(ncol(tmp))] <- tmp
        }
    }
}
for (s in c("noisy", "giid", "gar", "siid", "sar"))
    rip.export(round(255 * out.list[[s]]),
               file = file.path(OUTDIR, sprintf("combined-%s.png", s)))

## also create 'combined-latent.png' in current directory with ground truth images

if (!file.exists("combined-latent.png"))
{
    latent <- as.rip(matrix(1, 260 * 2, 260 * 4))
    for (I in seq_along(sample.images))
    {
        II <- (I-1) %/% 4
        JJ <- (I-1) %% 4
        tmp <- sample.images[[I]] / 255
        latent[II * 260 + seq_len(nrow(tmp)),
               JJ * 260 + seq_len(ncol(tmp))] <- tmp
    }
    rip.export(round(255 * latent), file = "combined-latent.png")
}

