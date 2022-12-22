#libaries
library(shroomDK)
library(tidyverse)

source("gas-network-one-query.R")
source("gas-network-two-query.R")
source("gas-network-three-query.R")
source("gas-network-four-query.R")

###### pull data from flipside #####
# TODO: paginiation for 2-4, currently only pulling 1m rows
key <- readLines("api-key.txt")

gas_one <- auto_paginate_query(
  query = gas_one_query,
  api_key = key
)
gas_two_tmp <- auto_paginate_query(
  query = gas_two_query,
  api_key = key,
  maxrows = 2000000
)
gas_three <- auto_paginate_query(
  query = gas_three_query,
  api_key = key
)
gas_four <- auto_paginate_query(
  query = gas_four_query,
  api_key = key
)

## save data
# saveRDS(gas_one, "gas_one.rds")
# saveRDS(gas_two, "gas_two.rds")
# saveRDS(gas_three, "gas_three.rds")
# saveRDS(gas_four, "gas_four.rds")

## join data
gas <- rbind(gas_one, gas_two, gas_three, gas_four)
# saveRDS(gas, "gas.rds")

##### network #####




