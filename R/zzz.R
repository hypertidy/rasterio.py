
rasterio <- NULL

.onLoad <- function(libname, pkgname) {
  # delay load foo module (will only be loaded when accessed via $)
  rasterio <<- reticulate::import("rasterio", delay_load = TRUE)
  reticulate::configure_environment(pkgname)
}
