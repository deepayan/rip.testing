

args <- commandArgs(TRUE)
if (!length(args) %in% c(2, 3))
{
    cat("\nUsage: Rscript test-combinations.R <S> <LAMBDA> <METHOD=direct>\n\n")
    q()
} 

suppressMessages(library(rip.recover))

load("sample.images.rda") # additional images from Levin et al 2009

S <- as.numeric(args[1]) # noise in blurred image (try 100, 10)
LAMBDA <- as.numeric(args[2]) # tuning parameter ~ 0.01, 0.001
METHOD <- if (length(args) == 3) args[3] else "direct"

str(list(S = S, LAMBDA = LAMBDA, METHOD = METHOD))

## Other parameters

rho.iid <- list(along = 0, across = 0) # IID parameters
rho.ar <- list(along = 0.3, across = 0.6) # AR parameters
zapk.digits <- 2 # 1 to be aggressive, 3 to keep essentially unchanged
NITER.RL <- 25  # for Richardon-Lucy
NITER.IRLS <- 5 # number of IRLS updates

PATCH <- 300
OVERLAP <- 10

OUTDIR <- sprintf("%s-%g-%g", METHOD, S, LAMBDA)
if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

fout <- function(s) file.path(OUTDIR, sprintf("recovered-%d-%d-%s.png", I, K, s))
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

## systematically test using various methods:

## NOTE: We add random noise, so setting seed is important to make
## sure we work on the same 'random' blurred images

addPoissonNoise <- rip.recover:::addPoissonNoise

tryq <- function(expr)
{
    call <- match.call()
    call[[1]] <- quote(try)
    ## call$silent <- TRUE
    ans <- eval.parent(call)
    ## if (inherits(ans, "try-error")) stop(attributes(ans)$condition$message)
    ans
}

set.seed(20200515)

for (I in seq_along(sample.images))
{
    for (K in seq_along(sample.kernels))
    {
        message(sprintf("image: %d, kernel: %d", I, K))
        x <- sample.images[[I]]
        k <- sample.kernels[[K]]
        if (any(dim(k) %%2 == 0)) stop("kernel must have odd dimensions")
        z <- rip.conv(x, k, type = "valid")
        y <- addPoissonNoise(z, S) # rescales to (0,1)
        kk <- zapsmallp(k, digits = zapk.digits) # use instead of actual k
        kk[] <- kk / sum(kk)
        fexport(y, "noisy")
        if (!fexists("rl"))
        {
            rl <- rip.deconvlucy(y, kk, niter = NITER.RL)
            fexport(rl)
        }
        if (!fexists("giid"))
        {
            giid <- 
                tryq(rip.deconv(y, kk, method = METHOD, cg.update = "FR",
                                alpha = 2, lambda = LAMBDA, rho = rho.iid,
                                patch = PATCH, overlap = OVERLAP, verbose = TRUE))
            fexport(giid)
        }
        if (!fexists("gar"))
        {
            gar <- 
                tryq(rip.deconv(y, kk, method = METHOD, cg.update = "FR",
                                alpha = 2, lambda = LAMBDA, rho = rho.ar,
                                patch = PATCH, overlap = OVERLAP, verbose = TRUE))
            fexport(gar)
        }
        if (!fexists("siid"))
        {
            siid <- 
                tryq(rip.deconv(y, kk, method = METHOD, cg.update = "FR",
                                alpha = 0.8, lambda = LAMBDA, rho = rho.iid,
                                patch = PATCH, overlap = OVERLAP, verbose = TRUE))
            fexport(siid)
        }
        if (!fexists("sar"))
        {
            sar <- 
                tryq(rip.deconv(y, kk, method = METHOD, cg.update = "FR",
                                alpha = 0.8, lambda = LAMBDA, rho = rho.ar,
                                patch = PATCH, overlap = OVERLAP, verbose = TRUE))
            fexport(sar)
        }
    }
}


## Finally, make a big 8x8 image matrix with recovered images, each side = 8*256 pixels

out.list <- list(noisy = as.rip(matrix(1, 256 * 8, 256 * 8)))
for (s in c("rl", "giid", "gar", "siid", "sar"))
    out.list[[s]] <- out.list[["noisy"]]



for (I in seq_along(sample.images))
{
    for (K in seq_along(sample.kernels))
    {
        for (s in c("noisy", "rl", "giid", "gar", "siid", "sar"))
        {
            if (fexists(s, FALSE))
            {
                tmp <- rip.import(fout(s), type = "grayscale") / 255
                out.list[[s]][(I-1) * 256 + seq_len(nrow(tmp)),
                              (K-1) * 256 + seq_len(ncol(tmp))] <- tmp
            }
        }
    }
}

for (s in c("noisy", "rl", "giid", "gar", "siid", "sar"))
    rip.export(round(255 * out.list[[s]]),
               file = file.path(OUTDIR, sprintf("combined-%s.png", s)))


## This is too large, so also make separate images for each kernel:
## one image each for noisy+4 priors+rl, 8 images in a 3x3 layout.


for (K in seq_along(sample.kernels))
{
    out.list <- list(noisy = as.rip(matrix(1, 256 * 3, 256 * 3)))
    for (s in c("rl", "giid", "gar", "siid", "sar"))
        out.list[[s]] <- out.list[["noisy"]]
    for (I in seq_along(sample.images))
    {
        II <- I %/% 3
        JJ <- I %% 3
        for (s in c("noisy", "rl", "giid", "gar", "siid", "sar"))
        {
            ## use first position to show kernel
            kk <- sample.kernels[[K]]
            kk[] <- kk / max(kk)
            offset <- (nrow(kk) - 1) / 2
            stopifnot(round(offset) == offset)
            out.list[[s]][1:240, 1:240] <-
                rip.resize(1-kk, d = c(240, 240), method = "nearest")
            if (fexists(s, FALSE))
            {
                tmp <- rip.import(fout(s), type = "grayscale") / 255
                out.list[[s]][II * 256 + offset + seq_len(nrow(tmp)),
                              JJ * 256 + offset + seq_len(ncol(tmp))] <- tmp
            }
        }
    }
    for (s in c("noisy", "rl", "giid", "gar", "siid", "sar"))
        rip.export(round(255 * out.list[[s]]),
                   file = file.path(OUTDIR, sprintf("combined-%d-%s.png", K, s)))
}

## also create 'combined-latent.png' in current directory with ground truth images

if (!file.exists("combined-latent.png"))
{
    latent <- as.rip(matrix(1, 256 * 3, 256 * 3))
    for (I in seq_along(sample.images))
    {
        II <- I %/% 3
        JJ <- I %% 3
        tmp <- sample.images[[I]] / 255
        latent[II * 256 + seq_len(nrow(tmp)),
               JJ * 256 + seq_len(ncol(tmp))] <- tmp
    }
    rip.export(round(255 * latent), file = "combined-latent.png")
}

