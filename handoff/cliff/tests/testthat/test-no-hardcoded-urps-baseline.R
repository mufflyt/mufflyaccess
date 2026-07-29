# [APPLY IN: cliff] -- fails if a hardcoded national URPS count appears in production code
library(testthat)
find_r_files <- function(root = ".") list.files(root, pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE)
strip_allowed_files <- function(paths) {
  excluded <- c("^tests/","^docs/","^renv/","^packrat/","^data-raw/","test-no-hardcoded-urps-baseline\\.R$")
  n <- gsub("\\\\","/",paths)
  paths[!vapply(n, function(p) any(grepl(excluded, p)), logical(1))]
}
find_literal <- function(files, literal) {
  pat <- paste0("(?<![0-9])", literal, "(?![0-9])")
  do.call(rbind, Filter(Negate(is.null), lapply(files, function(p) {
    ln <- readLines(p, warn = FALSE, encoding = "UTF-8"); m <- grep(pat, ln, perl = TRUE)
    if (!length(m)) NULL else data.frame(file=p, line=m, text=trimws(ln[m]), stringsAsFactors=FALSE)
  })))
}
test_that("production code contains no hardcoded SSOT counts", {
  files <- strip_allowed_files(find_r_files("."))
  forbidden <- c("1031","1339","308","1295","264")
  hits <- Filter(Negate(is.null), lapply(forbidden, function(v){ h<-find_literal(files,v); if(is.null(h))NULL else {h$literal<-v;h}}))
  if (!length(hits)) { succeed(); return(invisible()) }
  hits <- do.call(rbind, hits)
  fail(paste("Hardcoded URPS workforce values found. Use mufflyaccess::urps_count() instead.",
             paste0(hits$file,":",hits$line," contains ",hits$literal," — ",hits$text, collapse="\n"), sep="\n"))
})
