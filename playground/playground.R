# Playground for proof of concept.
library(sits)
library(parallel)
library(sitsdata)
library(stars)

# detect the number of CPU cores on the current host
CORES <- parallel::detectCores()


# openeo load collection
load_collection <- function(id, spatial_extent, temporal_extent, bands = null, properties = null){
  source_id <- NULL
  if(id == "SENTINEL-2-L2A"){
    source_id = "AWS"
  }else{
    message("The image collection is defined is not suppported.")
  }

  # Temporal extent
  t0 = temporal_extent[[1]]
  t1 = temporal_extent[[2]]

  # spatial extent  of roi
  xmin = as.numeric(spatial_extent$west)
  ymin = as.numeric(spatial_extent$south)
  xmax = as.numeric(spatial_extent$east)
  ymax = as.numeric(spatial_extent$north)

  # roi
  roi_bounds = c(
    lon_min = xmin, lat_min = ymin,
    lon_max = xmax, lat_max = ymax
  )
  #get irregular data cube from ARD image collection
  cube <- sits::sits_cube(source = source_id,
                          collection = id,
                          roi = roi_bounds,
                          bands = bands,
                          start_date = t0,
                          end_date = t1)
  return(cube)
}

# openeo regularize data cubes
ml_regularize_data_cube <- function(data, period, resolution){
  cube <- sits::sits_regularize(cube = data,
                                output_dir = tempdir(),
                                period = period,
                                res = resolution,
                                multicores = CORES)
  return(cube)
}

# openeo ml random forest class training
ml_fit_class_random_forest <- function(predictors, target, max_variables = NULL , num_trees = 100, seed = NULL){
  # TO DO , samples need to be a union of predictors and targets
  # samples <- predictors, target
  samples <- predictors
  # model
  model <-sits::sits_train(
          samples = samples,
          ml_method = sits_rfor(num_trees = 100)
        )
  return(model)
}

# openeo ml prediction
ml_predict <- function(data, model, dimensions = "bands"){
  # classify data cube to obtain a probability cube
  cube_probability <- sits::sits_classify(
                  data = data,
                  ml_model = model,
                  output_dir = ".",
                  version = "rf-raster",
                  multicores = CORES,
                  memsize = 16
                  )
  # smoothen a  probability cube
  cube_bayes <- sits::sits_smooth(
            cube = cube_probability,
            output_dir = ".",
            version = "rf-raster",
            multicores = CORES,
            memsize = 16
            )
  return(cube_bayes)
}

# --------------------------------------------#
# -----------test-----------------------------#
spatial_extent = list(
  west = 24.97, south = -34.30,
  east = 25.87, north = -32.63
)

temporal_extent = c("2019-09-01", "2019-10-01")

# load sentinel data
datacube <- load_collection("SENTINEL-2-L2A", spatial_extent = spatial_extent, bands = c("B02", "B8A", "B11", "CLOUD"), temporal_extent = temporal_extent)

datacube

# regularize the data cube
datacube_reg <- ml_regularize_data_cube(data = datacube, period = "P1M", resolution=30)

datacube_reg

# ml fit rf model
## training data from sitsdata
ml_training_sample <- sitsdata::samples_deforestation_rondonia
ml_label <- ml_training_sample$label

# rf model
ml_model <- ml_fit_class_random_forest(predictors = ml_training_sample, target = ml_label)

plot(ml_model)

# predict
classified_cube <- ml_predict(data = datacube_reg, model = ml_model)
