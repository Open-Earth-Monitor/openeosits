#' Collection
#'
#' This class represents the collections, which contain a set of Granules.
#' @field id Id of the collection
#' @field title Collection title
#' @field description Short description of the collection
#' @field temporal_extent Temporal extent of the collection
#' @field spatial_extent Spatial extent of the collection
#' @field summaries Summary details of the collection
#' @field cube_dimensions Cube dimensions of the collection
#'
#' @include Session-Class.R
#' @importFrom R6 R6Class
#' @export
library(R6)

Collection <- R6Class(
  "Collection",
  public = list(
    id = NULL,
    title = NULL,
    description = NULL,
    temporal_extent = NULL,
    spatial_extent = NULL,
    summaries = NULL,
    cube_dimensions = NULL,

    initialize = function(id = NA, title = NA, description = NA,
                          temporal_extent = NULL, spatial_extent = NULL,
                          summaries = NULL, cube_dimensions = NULL) {

      self$id <- id
      self$title <- title
      self$description <- description
      self$temporal_extent <- temporal_extent
      self$spatial_extent <- spatial_extent
      self$summaries <- summaries
      self$cube_dimensions <- cube_dimensions
    },

    setMetadata = function() {
      # Calculate the extent and bands information here if needed
      private$metadata <- list(
        extent = self$spatial_extent,
        bands = self$cube_dimensions$bands$values
      )
    },

    collectionInfoExtended = function() {
      list(
        stac_version = Session$getConfig()$stac_version,
        stac_extensions = list(Session$getConfig()$stac_extensions),
        id = self$id,
        title = self$title,
        description = self$description,
        license = "proprietary",
        extent = list(
          spatial = list(
            bbox = list(
              list(
                self$spatial_extent$left,
                self$spatial_extent$bottom,
                self$spatial_extent$right,
                self$spatial_extent$top
              )
            )
          ),
          temporal = list(
            interval = list(
              list(self$temporal_extent$t0, self$temporal_extent$t1)
            )
          )
        ),
        links = list(
          list(
            rel = "root",
            href = paste(Session$getConfig()$base_url, "collections", sep = "/")
          )
        ),
        "cube:dimensions" = list(self$cube_dimensions),
        summaries = list(constellation = list(""), 'eo:bands' = self$cube_dimensions$bands)
      )
    }
  ),
  private = list()
)

is.Collection <- function(obj) {
  return("Collection" %in% class(obj))
}

# Instances of Collection with temporal and spatial extents, summaries, and cube dimensions:

temporal_extent <- list(t0 = "2015-06-27T10:25:31.456000Z", t1 = NULL)
spatial_extent <- list(left = -180, bottom = -90, right = 180, top = 90)
summaries <- list(platform = list("sentinel-2a","sentinel-2b"), constellation = list("Sentinel-2"), 'view:off_nadir' = 0, 'sci:doi'= list("10.5270/s2_-znk9xsj"), instruments = list("msi"))

cube_dimensions <- list(
  x = list(type = "spatial", axis = "x", extent = list(-180, 180)),
  y = list(type = "spatial", axis = "y", extent = list(-90, 90)),
  t = list(type = "temporal", extent = list("2015-06-27T10:25:31.456000Z", NULL)),
  bands = list(type = "bands", values = list("B01", "B02", "B03","B04", "B05", "B06", "B07", "B08", "B8A","B09","B10", "B11", "B12" ))
)

SENTINEL_2_L2A <- Collection$new(
  id = "SENTINEL-2-L2A",
  title = "Sentinel 2 L2A",
  description = "Sentinel-2a and Sentinel-2b imagery, processed to Level 2A (Surface Reflectance).",
  temporal_extent = temporal_extent,
  spatial_extent = spatial_extent,
  summaries = summaries,
  cube_dimensions = cube_dimensions
)
