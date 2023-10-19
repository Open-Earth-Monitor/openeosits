library(openeo)

# connect  to the back-end when deployed locally
con = connect("http://localhost:8000")

# basic login with default params
login(user = "user",
      password = "password")

# get the collection list
collections = list_collections()

# get the processes list
process_list = list_processes()
process_list$load_collection

# to check description of a collection
collections$`SENTINEL-2-L2A`$description

# get the process collection to use the predefined processes of the back-end
p = processes()

# load the initial data collection and limit the amount of data loaded
datacube_init = p$load_collection(id = "SENTINEL-2-L2A",
                                  spatial_extent = list(west = 24.97,
                                                        south = -34.30,
                                                        east = 25.87,
                                                        north = -32.63),
                                  temporal_extent = c("2019-09-01", "2019-10-01"))

# regularize data cube for ml and dl
datacube_regularized = p$ml_regularize_data_cube(data = datacube_init, period = "P1M", resolution = 50)

# supported formats
formats = list_file_formats()

result = p$save_result(data = datacube_regularized, format = formats$output$GTiff)

# Process and download data synchronously
start.time <- Sys.time()
compute_result(graph = result, output_file = "test.tif")
end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken
print("End of processes")
