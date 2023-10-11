#' cube processes openEO standards mapped to gdalcubes processes
#'
#' @include Process-class.R
#' @import gdalcubes
#' @import rstac
#' @import useful
#' @import sf
#' @import stars
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
#' @description Return a list with datacube description and schema
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
    ),
    ### Additional variables for flexibility due to gdalcubes
    Parameter$new(
      name = "pixels_size",
      description = "size of pixels in x-direction(longitude / easting) and y-direction (latitude / northing). Default is 300",
      schema = list(
        type = "number"
      ),
      optional = TRUE
    ),
    Parameter$new(
      name = "time_aggregation",
      description = "size of pixels in time-direction, expressed as ISO8601 period string (only 1 number and unit is allowed) such as \"P16D\".Default is monthly i.e. \"P1M\".",
      schema = list(
        type = "string",
        subtype = "duration"
      ),
      optional = TRUE
    ),
    Parameter$new(
      name = "crs",
      description = "Coordinate Reference System, default = 4326",
      schema = list(
        type = "number",
        subtype = "epsg-code"
      ),
      optional = TRUE
    )
  ),
  returns = eo_datacube,
  operation = function(id, spatial_extent, temporal_extent, bands = NULL, pixels_size = 300, time_aggregation = "P1M",
                       crs = 4326, job) {
    # Temporal extent preprocess
    t0 <- temporal_extent[[1]]
    t1 <- temporal_extent[[2]]
    duration <- c(t0, t1)
    time_range <- paste(duration, collapse = "/")
    message("....After Temporal extent")

    # spatial extent for cube view
    xmin <- as.numeric(spatial_extent$west)
    ymin <- as.numeric(spatial_extent$south)
    xmax <- as.numeric(spatial_extent$east)
    ymax <- as.numeric(spatial_extent$north)
    message("...After Spatial extent")

    # spatial extent for stac call
    xmin_stac <- xmin
    ymin_stac <- ymin
    xmax_stac <- xmax
    ymax_stac <- ymax
    message("....After default Spatial extent for stac")
    if (crs != 4326) {
      message("....crs is not 4326")
      min_pt <- sf::st_sfc(st_point(c(xmin, ymin)), crs = crs)
      min_pt <- sf::st_transform(min_pt, crs = 4326)
      min_bbx <- sf::st_bbox(min_pt)
      xmin_stac <- min_bbx$xmin
      ymin_stac <- min_bbx$ymin
      max_pt <- sf::st_sfc(st_point(c(xmax, ymax)), crs = crs)
      max_pt <- sf::st_transform(max_pt, crs = 4326)
      max_bbx <- sf::st_bbox(max_pt)
      xmax_stac <- max_bbx$xmax
      ymax_stac <- max_bbx$ymax
      message("....transformed to 4326")
    }

    # Connect to STAC API and get satellite data
    message("STAC API call.....")
    stac_object <- stac("https://earth-search.aws.element84.com/v0")
    items <- stac_object %>%
      stac_search(
        collections = id,
        bbox = c(xmin_stac, ymin_stac, xmax_stac, ymax_stac),
        datetime = time_range,
        limit = 10000
      ) %>%
      post_request() %>%
      items_fetch()
    # create image collection from stac items features
    img.col <- stac_image_collection(items$features,
      property_filter =
        function(x) {
          x[["eo:cloud_cover"]] < 30
        }
    )
    # Define cube view with monthly aggregation
    crs <- c("EPSG", crs)
    crs <- paste(crs, collapse = ":")
    v.overview <- cube_view(
      srs = crs, dx = pixels_size, dy = pixels_size, dt = time_aggregation,
      aggregation = "median", resampling = "average",
      extent = list(
        t0 = t0, t1 = t1,
        left = xmin, right = xmax,
        top = ymax, bottom = ymin
      )
    )
    # gdalcubes creation
    cube <- raster_cube(img.col, v.overview)

    if (!is.null(bands)) {
      cube <- select_bands(cube, bands)
    }
    message("Data Cube is created....")
    message(as_json(cube))
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
    message("The output is being saved...")
    job$setOutput(format)
    return(data)
  }
)
