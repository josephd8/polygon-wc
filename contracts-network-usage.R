#libaries
library(shroomDK)
library(tidyverse)

source("queries/contracts-network-usage-query.R")
source("queries/contracts-network-usage-query-no-mint.R")

###### pull data from flipside #####
key <- readLines("api-key.txt")

cnu_data <- auto_paginate_query(
  query = contracts_network_usage_query,
  api_key = key
)

cnunm_data <- auto_paginate_query(
  query = contracts_network_usage_no_mint_query,
  api_key = key
)

# saveRDS(cnu_data, "data/cnu_data.rds")
# saveRDS(cnunm_data, "data/cnunm_data.rds")

##### analysis / visualizations #####
View(cnu_data)

cnu_dat <- cnu_data %>%
  filter(BURN >= 25) %>%
  mutate(matic_burn_rank = rank(BURN) / length(BURN),
         tx_fees_rank = rank(TX_FEE) / length(TX_FEE),
         txns_rank = rank(TXNS) / length(TXNS),
         events_rank = rank(EVENTS) / length(EVENTS))

wc_matic_burn_rank <- cnu_dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(matic_burn_rank)
wc_tx_fees_rank <- cnu_dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(tx_fees_rank)
wc_txns_rank <- cnu_dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(txns_rank)
wc_events_rank <- cnu_dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(events_rank)

cnu_dat %>%
  ggplot(aes(x = matic_burn_rank, y = log(BURN))) +
  geom_point() + 
  geom_vline(xintercept = wc_matic_burn_rank, col = 'blue', linetype = 'dashed') +
  ylab("matic burned (log)") + xlab("matic burned (percentile)") +
  theme_bw()

cnu_dat %>%
  ggplot(aes(x = tx_fees_rank, y = log(TX_FEE))) +
  geom_point() + 
  geom_vline(xintercept = wc_tx_fees_rank, col = 'blue', linetype = 'dashed') +
  ylab("tx fees (log)") + xlab("tx fees (percentile)") +
  theme_bw()

cnu_dat %>%
  ggplot(aes(x = txns_rank, y = log(TXNS))) +
  geom_point() + 
  geom_vline(xintercept = wc_txns_rank, col = 'blue', linetype = 'dashed') +
  ylab("# of txs (log)") + xlab("# of txs (percentile)") +
  theme_bw()

cnu_dat %>%
  ggplot(aes(x = events_rank, y = log(EVENTS))) +
  geom_point() + 
  geom_vline(xintercept = wc_events_rank, col = 'blue', linetype = 'dashed') +
  ylab("# of events (log)") + xlab("# of events (percentile)") +
  theme_bw()

# TODO: view the same but without all of the mint txs that were paid for
# by polygon themselves
cnunm_dat <- cnunm_data %>%
  filter(BURN >= 25) %>%
  mutate(matic_burn_rank = rank(BURN) / length(BURN),
         tx_fees_rank = rank(TX_FEE) / length(TX_FEE),
         txns_rank = rank(TXNS) / length(TXNS),
         events_rank = rank(EVENTS) / length(EVENTS))

wc_matic_burn_rank2 <- cnunm_dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(matic_burn_rank)
wc_tx_fees_rank2 <- cnunm_dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(tx_fees_rank)
wc_txns_rank2 <- cnunm_dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(txns_rank)
wc_events_rank2 <- cnunm_dat %>%
  filter(CONTRACT_ADDRESS == '0x9f202e685461b656b5b0e18ebddcc626837d8afd') %>%
  pull(events_rank)

cnunm_dat %>%
  ggplot(aes(x = matic_burn_rank, y = log(BURN))) +
  geom_point() + 
  geom_vline(xintercept = wc_matic_burn_rank2, col = 'blue', linetype = 'dashed') +
  ylab("matic burned (log)") + xlab("matic burned (percentile)") +
  theme_bw()

cnunm_dat %>%
  ggplot(aes(x = tx_fees_rank, y = log(TX_FEE))) +
  geom_point() + 
  geom_vline(xintercept = wc_tx_fees_rank2, col = 'blue', linetype = 'dashed') +
  ylab("tx fees (log)") + xlab("tx fees (percentile)") +
  theme_bw()

cnunm_dat %>%
  ggplot(aes(x = txns_rank, y = log(TXNS))) +
  geom_point() + 
  geom_vline(xintercept = wc_txns_rank2, col = 'blue', linetype = 'dashed') +
  ylab("# of txs (log)") + xlab("# of txs (percentile)") +
  theme_bw()

cnunm_dat %>%
  ggplot(aes(x = events_rank, y = log(EVENTS))) +
  geom_point() + 
  geom_vline(xintercept = wc_events_rank2, col = 'blue', linetype = 'dashed') +
  ylab("# of events (log)") + xlab("# of events (percentile)") +
  theme_bw()

