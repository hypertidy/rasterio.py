#' Example RGBA GeoTIFF image file
#'
#' Function returns a path to a file, for examples.
#'
#' The GeoTIFF is the canonical example file, used by rasterio examples. This
#' is a small image 718x791 in UTM Zone 18 at approx. `c(-77.76, 24.56)` from the
#' 'lnglat' property of the open data set.
#' @return
#' @export
#'
#' @examples
#' ## path to a 4-band TIFF image file
#' rgba_tif()
#' matrix(open.py(rgba_tif())$lnglat(), ncol = 2L,
#'          dimnames = list(NULL, c("longitude", "latitude")))
rgba_tif <- function() {
  system.file("extdata/RGBA.byte.tif", package = "rasterio.py", mustWork = TRUE)
}

#' Title
#'
#' @param fp file path, or url, or database connection string, or VRT string, anything GDAL can open as raster
#' @param mode open mode, readonly by default
#' @param driver driver to use, optional is autodetected
#' @param width width of data set (ignored in readonly)
#' @param height height of data set (ignored in readonly)
#' @param count number of bands (ignored in readonly)
#' @param crs projection of data set (ignored in readonly)
#' @param transform geotransform of data set, see details (ignored in readonly)
#' @param dtype data type of dataset (ignored in readonly)
#' @param nodata missing data value of dataset (ignored in readonly)
#' @param sharing open shared mode (FALSE by default)
#'
#' @return
#' @name open.py
#' @export open.py
#'
#' @examples
#' x <- open.py(rgba_tif())
open.py <- function(fp,
                 mode='r',
                 driver=NULL,
                 width=NULL,
                 height=NULL,
                 count=NULL,
                 crs=NULL,
                 transform=NULL,
                 dtype=NULL,
                 nodata=NULL,
                 sharing=FALSE) { ## missing *kwargs here

                   rasterio$open(fp, mode, driver, width, height, count, crs, transform, dtype, nodata, sharing)
}

#' Title
#'
#' @param x object, opened dataset or WarpedVRT dataset
#' @param ... ignored
#'
#' @return xmin,xmax,ymin,ymax
#' @export
#'
#' @examples
#' extent.py(open.py(rgba_tif()))
extent.py <- function(x, ...) {
  UseMethod("extent.py")
}

#' @name extent.py
#' @export
extent.py.rasterio._io.DatasetReaderBase <- function(x, ...) {
  xlim <- c(x$bounds$left, x$bounds$right)
  ylim <- c(x$bounds$bottom, x$bounds$top)
  c(xlim, ylim)
}

#' Title
#'
#' @param fp gdal data source name (file, url, VRT string, database connection string, etc)
#' @param extent xmin,xmax,ymin,ymax
#' @param dimension width,height in pixels
#' @param projection projection string of output (interpreted by GDAL input reader)
#'
#' @return WarpedVRT dataset
#' @export
#'
#' @examples
#' warped <- warp.py(rgba_tif(), extent = c(-1e3, 1e3, -1e3, 1e3), dimension = c(256, 256),
#'               projection = sprintf("+proj=omerc +lon_0=%f +lat_0=%f +datum=WGS84",
#'                                                              -77.75791, 24.56158))
#' plot(warped)
#'
#' longlat <- warp.py(rgba_tif(), extent =
#'                                 1.2 * c(-1, 1, -1, 1) +
#'                                rep(c(-77.75791, 24.56158), each = 2L),
#'                               projection = "OGC:CRS84",
#'                               dimension = c(256, 256), resample = "cubic")
#' plot(longlat, asp = 1/cos(24.5*pi/180))
#' maps::map(add = TRUE, col = "firebrick", lwd = 4)
warp.py <- function(fp, extent = c(-1e5, 1e5, -1e5, 1e5), dimension = c(100, 100),
                    projection = "+proj=laea", resample = "nearest") {
  ## here we need a WarpedVRT interface in its native form
  WVRT <- rasterio$vrt$WarpedVRT
  CRS <- rasterio$crs$CRS
  Resampling <- rasterio$enums$Resampling
  dst_crs = CRS$from_user_input(projection)
  # Output image transform
  xres = diff(extent[1:2]) / dimension[1L]
  yres = diff(extent[3:4]) / dimension[2L]
  dst_transform = rasterio$Affine(xres, 0.0, extent[1L],
                                0.0, -yres, extent[4L])

  WVRT(open.py(fp), crs=projection, transform = dst_transform,
            resampling=Resampling[[resample]], width = dimension[1L], height = dimension[2L])
}

#' Title
#'
#' We can't specify bands yet.
#'
#' @param x open dataset or WarpedVRT dataset
#' @param dimension size of array to plot (determine automatically, use `NULL` for native)
#'
#' @return used for side effect, a plot
#' @export
#'
#' @examples
#' plot(open.py(rgba_tif()))
plot.rasterio._io.DatasetReaderBase <- function(x, ..., dimension = if (dev.cur() == 1L) c(256, 256) else dev.size("px")) {
  if (is.null(dimension)) {
    im <- x$read()
  } else {
    dimension <- as.integer(c(x$count, pmax(1, as.integer(dimension))))
    im <- x$read(out_shape = as.list(dimension))
  }
  ext <- extent.py(x)

  ## do the hacky cosine thing for longlat here
  plotargs <- list(...)
  if (is.null(plotargs$xlim)) plotargs$xlim <- ext[1:2]
  if (is.null(plotargs$ylim)) plotargs$ylim <- ext[3:4]
  if (is.null(plotargs$xlab)) plotargs$xlab <- ""
  if (is.null(plotargs$ylab)) plotargs$ylab <- ""
  if (is.null(plotargs$xpd)) plotargs$xpd <- NA
  if (is.null(plotargs$asp)) plotargs$asp <- 1
  plotargs$x <- NA
  do.call(plot, plotargs)
  if (dim(im)[1L] > 1 && dim(im)[1L] %in% c(3L, 4L)) {
    im <- aperm(scales::rescale(im), c(2L, 3L, 1L))
  } else {

    im <- matrix(scales::rescale(im[1L, , ]), dim(im)[2L], dim(im)[3L])

  }
  rasterImage(im, ext[1L], ext[3L], ext[2L], ext[4L])

}

