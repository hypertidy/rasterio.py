# _targets.R file
library(targets)
#source("R/functions.R")
options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("curl", "fs"))
list(
  tar_target(
    inst_dir,
    fs::dir_create("inst"),
    format = "file"
  ),
  tar_target(
    extdata_dir,
    fs::dir_create(file.path(inst_dir, "extdata")),
    format = "file"
  ),
  tar_target(
    rgba_tif_file,
    curl::curl_download("https://github.com/rasterio/rasterio/raw/master/tests/data/RGBA.byte.tif", file.path(extdata_dir, "RGBA.byte.tif")),
    format = "file"
  ),
  tar_target(
    rgba_tif,
    rgba_tif_file,
    format = "file"
  )

)

