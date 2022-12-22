#libaries
library(shroomDK)
library(tidyverse)

source("queries/addresses-query.R")

###### pull data from flipside #####
key <- readLines("api-key.txt")

add_data <- auto_paginate_query(
  query = addresses_query,
  api_key = key
)

# saveRDS(add_data, "data/add_data.rds")

###### analysis / visualizations #####
add_data

