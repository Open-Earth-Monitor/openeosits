library(sitsdata)
library(sits)
library(jsonlite)
library(geojsonsf)

sits_data <- sitsdata::samples_prodes_4classes
sits_data

sits_data$time_series[[1]]

sf_samples <- sits::sits_as_sf(sits_data)

sf_samples


json_samples <- jsonlite::fromJSON(jsonlite::toJSON(sf_samples), simplifyDataFrame = F, simplifyMatrix = F)
json_samples

sf_to_json <- geojsonsf::sf_geojson(sf_samples)
sf_to_json

json_to_sf <- geojsonsf::geojson_sf(json_samples)
json_to_sf
