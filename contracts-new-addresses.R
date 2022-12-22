#libaries
library(shroomDK)
library(tidyverse)

source("queries/contracts-new-address-stats-query.R")

###### pull data from flipside #####
key <- readLines("api-key.txt")

cnas_data <- auto_paginate_query(
  query = contracts_new_address_stats_query,
  api_key = key
)

# saveRDS(cnas_data, "data/cnas_data.rds")

##### analysis / visualizations #####
View(cnas_data)

cnas_dat <- cnas_data %>%
  mutate(new_addresses_rank = rank(NEW_ADDRESSES) / length(NEW_ADDRESSES),
         avg_nonce_rank = rank(AVG_NONCE) / length(AVG_NONCE),
         avg_matic_burned_rank = rank(AVG_MATIC_BURNED) / length(AVG_MATIC_BURNED),
         avg_tx_fees_rank = rank(AVG_TX_FEES) / length(AVG_TX_FEES))

wc_new_addresses_rank <- dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(new_addresses_rank)
wc_avg_nonce_rank <- dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(avg_nonce_rank)
wc_avg_matic_burned_rank <- dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(avg_matic_burned_rank)
wc_avg_tx_fees_rank <- dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(avg_tx_fees_rank)

cnas_dat %>%
  ggplot(aes(x = new_addresses_rank, y = log(NEW_ADDRESSES))) +
  geom_point() +
  geom_vline(xintercept = wc_new_addresses_rank, col = 'blue', linetype = 'dashed') +
  ylab("new addresses (log)") + xlab("new addresses (percentile)") +
  theme_bw()

cnas_dat %>%
  ggplot(aes(x = avg_nonce_rank, y = log(AVG_NONCE))) +
  geom_point() + 
  geom_vline(xintercept = wc_avg_nonce_rank, col = 'blue', linetype = 'dashed') + 
  ylab("avg nonce (log)") + xlab("avg nonce (percentile)") +
  theme_bw()

cnas_dat %>%
  ggplot(aes(x = avg_matic_burned_rank, y = log(AVG_MATIC_BURNED))) +
  geom_point() + 
  geom_vline(xintercept = wc_avg_matic_burned_rank, col = 'blue', linetype = 'dashed') +
  ylab("avg matic burned (log)") + xlab("avg matic burned (percentile)") +
  theme_bw()

cnas_dat %>%
  ggplot(aes(x = avg_tx_fees_rank, y = log(AVG_TX_FEES))) +
  geom_point() + 
  geom_vline(xintercept = wc_avg_tx_fees_rank, col = 'blue', linetype = 'dashed') + 
  ylab("avg tx fees (log)") + xlab("avg tx fees (percentile)") +
  theme_bw()
