args <- commandArgs(TRUE)

INFILE <- Sys.getenv("INFILE", args[1])

OUTDIR <- "opencv"
if (!dir.exists(OUTDIR)) dir.create(OUTDIR)

fout <- function(s) file.path(OUTDIR, sprintf("%s-%s.jpg", INFILE, s))
fexists <- function(label) {
    message(fout(label))
    file.exists(fout(label))
}

fexport <- function(x, label = deparse(substitute(x)))
{
    rip.export(x, file = fout(label))
}

suppressMessages(library(rip.recover))

y <- rip.import(INFILE, type = "grayscale")

## if (!fexists("bm3d"))
## {
##     bm3d <- rip.cv$xphoto$bm3dDenoising(y)
##     fexport(bm3d)
## }
if (!fexists("nlmeans"))
{
    nlmeans <- rip.cv$photo$fastNlMeansDenoising(y, 7, 15, 45)
    fexport(nlmeans)
}

