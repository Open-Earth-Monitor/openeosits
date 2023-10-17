#' cube processes openEO standards mapped to gdalcubes processes
#'
#' @include Process-class.R
#' @import gdalcubes
#' @import rstac
#' @import useful
#' @import sf
#' @import parallel
NULL

#' schema_format
#' @description format for the schema
#'
#' @param type data type
#' @param subtype subtype of the data
#'
#' @return list with type and subtype(optional)
#' @export
schema_format <- function(type, subtype = NULL, items = NULL) {
  schema <- list()
  schema <- append(schema, list(type = type))

  if (!is.null(subtype) && !is.na(subtype)) {
    schema <- append(schema, list(subtype = subtype))
  }
  if (!is.null(items) && !is.na(items)) {
    schema <- append(schema, list(items = items))
  }
  return(schema)
}



#' datacube_schema
#' @description Return a list with data cube description and schema
#'
#' @return datacube list
datacube_schema <- function() {
  info <- list(
    description = "A data cube for further processing",
    schema = list(type = "object", subtype = "raster-cube")
  )
  return(info)
}

#' return object for the processes
eo_datacube <- datacube_schema()


#' load collection
load_collection <- Process$new(
  id = "load_collection",
  description = "Loads a collection from the current back-end by its id and returns it as processable data cube",
  categories = as.array("cubes", "import"),
  summary = "Load a collection",
  parameters = list(
    Parameter$new(
      name = "id",
      description = "The collection id",
      schema = list(
        type = "string",
        subtype = "collection-id"
      )
    ),
    Parameter$new(
      name = "spatial_extent",
      description = "Limits the data to load from the collection to the specified bounding box",
      schema = list(
        list(
          title = "Bounding box",
          type = "object",
          subtype = "bounding-box",
          properties = list(
            east = list(
              description = "East (upper right corner, coordinate axis 1).",
              type = "number"
            ),
            west = list(
              description = "West lower left corner, coordinate axis 1).",
              type = "number"
            ),
            north = list(
              description = "North (upper right corner, coordinate axis 2).",
              type = "number"
            ),
            south = list(
              description = "South (lower left corner, coordinate axis 2).",
              type = "number"
            )
          ),
          required = c("east", "west", "south", "north")
        ),
        list(
          title = "GeoJson",
          type = "object",
          subtype = "geojson"
        ),
        list(
          title = "No filter",
          description = "Don't filter spatially. All data is included in the data cube.",
          type = "null"
        )
      )
    ),
    Parameter$new(
      name = "temporal_extent",
      description = "Limits the data to load from the collection to the specified left-closed temporal interval.",
      schema = list(
        type = "array",
        subtype = "temporal-interval"
      )
    ),
    Parameter$new(
      name = "bands",
      description = "Only adds the specified bands into the data cube so that bands that don't match the list of band names are not available.",
      schema = list(
        type = "array"
      ),
      optional = TRUE
    )
  ),
  returns = eo_datacube,
  operation = function(id, spatial_extent, temporal_extent, bands = NULL, job) {
    source_id <- NULL
    if (id == "SENTINEL-2-L2A") {
      source_id <- "AWS"
    } else {
      stop("The image collection specified is  not supported.")
    }

    # Temporal extent
    t0 <- temporal_extent[[1]]
    t1 <- temporal_extent[[2]]

    # spatial extent  of roi
    xmin <- as.numeric(spatial_extent$west)
    ymin <- as.numeric(spatial_extent$south)
    xmax <- as.numeric(spatial_extent$east)
    ymax <- as.numeric(spatial_extent$north)

    # roi
    roi_bounds <- c(
      lon_min = xmin, lat_min = ymin,
      lon_max = xmax, lat_max = ymax
    )
    # get irregular data cube from ARD image collection
    cube <- sits::sits_cube(
      source = source_id,
      collection = id,
      roi = roi_bounds,
      bands = bands,
      start_date = t0,
      end_date = t1
    )
    return(cube)
  }
)



#' data cube regularization
ml_regularize_data_cube <- Process$new(
  id = "ml_regularize_data_cube",
  description = cat("Converts irregular data cubes into regular and complete data cubes in space and time, ensuring compatibility with machine learning and deep learning classification algorithms.
  This process eliminates gaps and missing values, enabling the use of machine learning and deep learning algorithms for remote sensing data."),
  categories = as.array("cubes", "machine learning"),
  summary = "Converts irregular data cubes into regular data cubes",
  parameters = list(
    Parameter$new(
      name = "data",
      description = "A raster data cube.",
      schema = list(
        type = "object",
        subtype = "datacube"
      )
    ),
    Parameter$new(
      name = "period",
      description = cat("The parameter allows you to specify the time interval between images in a data cube.
      The values for the period parameter follow the `ISO8601` time period specification format.
      This format represents time intervals as `P[n]Y[n]M[n]D`, where `Y` represents years, `M` represents months, and `D` represents days.
      For example, if you set the period as `P1M`, it signifies a one-month interval, while `P15D` represents a fifteen-day interval."),
      schema = list(
        type = "string"
      )
    ),
    Parameter$new(
      name = "period",
      description = "Resamples the data cube to the target resolution, which can be specified either as separate values for x and y or as a single value for both axes.",
      schema = list(
        type = "number"
      ),
      optional = TRUE
    )
  ),
  returns = eo_datacube,
  operation = function(data, period, resolution = 30, job) {
    #' detect the number of CPU cores on the current host
    CORES <- parallel::detectCores()

    #' regularize irregular data cubes using sits
    cube <- sits::sits_regularize(cube = data,
                                  output_dir = tempdir(),
                                  period = period,
                                  res = resolution,
                                  multicores = CORES)
    return(cube)
  }
)


#' save result
save_result <- Process$new(
  id = "save_result",
  description = "Saves processed data to the local user workspace / data store of the authenticated user.",
  categories = as.array("cubes", "export"),
  summary = "Save processed data to storage",
  parameters = list(
    Parameter$new(
      name = "data",
      description = "The data to save.",
      schema = list(
        type = "object",
        subtype = "raster-cube"
      )
    ),
    Parameter$new(
      name = "format",
      description = "The file format to save to.",
      schema = list(
        type = "string",
        subtype = "output-format"
      )
    ),
    Parameter$new(
      name = "options",
      description = "The file format parameters to be used to create the file(s).",
      schema = list(
        type = "object",
        subtype = "output-format-options"
      ),
      optional = TRUE
    )
  ),
  returns = list(
    description = "false if saving failed, true otherwise.",
    schema = list(type = "boolean")
  ),
  operation = function(data, format, options = NULL, job) {
    message("Data is being saved in format :")
    message(format)
    job$setOutput(format)
    return(data)
  }
)
