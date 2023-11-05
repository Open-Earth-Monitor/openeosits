library(sits)
library(sitsdata)
library(stars)
samples_prodes_4classes
# get dimensions
(time = samples_prodes_4classes$time_series[[1]]$Index)
samples_prodes_4classes |>
  st_as_sf(coords = c("longitude", "latitude"), crs = "OGC:CRS84") |>
  st_geometry()-> points
points
bands = colnames(samples_prodes_4classes$time_series[[1]])[-1]
bands
# merge all time series:
cube = do.call(rbind, samples_prodes_4classes$time_series)
cube$Index = NULL
cube = as.matrix(cube)
dim(cube)
dim(cube) = c(time = length(time), geom = length(points), band = length(bands))
dim(cube)
# create stars object:
st_as_stars(cube, raster = list(dimensions = c(NA_character_,NA_character_))) |>
  st_set_dimensions(1, values = as.Date(time)) |>
  st_set_dimensions(2, values = points) |>
  st_set_dimensions(3, values = bands) -> st
st
# print slices:
image(st[[1]][1,,])
image(st[[1]][,1,])
image(st[[1]][,,1])
