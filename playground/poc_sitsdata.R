library(sitsdata)
library(dplyr)
library(purrr)



## get sits data
out <- sitsdata::samples_prodes_4classes |> tidyr::unnest(cols = c(time_series))

## convert to json on client side
out_to_json <- jsonlite::toJSON(out)

##  convert to from json to sits tibble on sever side
data <- jsonlite::fromJSON(out_to_json)

orig <-  data |> tidyr::nest(
  .by = c(longitude, latitude, start_date, end_date, label, cube),
  .key = "time_series")

### function to convert 'Index' column to Date
convert_index_to_date <- function(data) {
  data |> mutate(Index = as.Date(Index))
}


orig <- orig |>
  mutate(time_series = map(time_series, convert_index_to_date),
         start_date = as.Date(start_date),
         end_date = as.Date(end_date))

orig = structure(orig, class = c("sits", class(orig)))

all.equal(orig, samples_prodes_4classes)
