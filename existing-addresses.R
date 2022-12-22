#libaries
library(shroomDK)
library(tidyverse)

source("queries/existing-address-query.R")

###### pull data from flipside #####
key <- readLines("api-key.txt")

ex_data_v2 <- auto_paginate_query(
  query = existing_address_query,
  api_key = key
)

# saveRDS(ex_data, "data/ex_data.rds")
# saveRDS(ex_data_v2, "data/ex_data_v2.rds")

###### analysis / visualizations #####
View(ex_data)

ex_data_v2 %>% 
  mutate(current = CURRENT_NONCE + 1,
         original = ORIGINAL_NONCE + 1) %>%
  select(GRP, ADDRESS, current, original) %>%
  mutate(velocity = (current - original) / original) %>%
  group_by(GRP) %>%
  summarize(mean(velocity))

ex_dat <- ex_data_v2 %>% 
  mutate(current = CURRENT_NONCE + 1,
         original = ORIGINAL_NONCE + 1) %>%
  select(GRP, ADDRESS, current, original) %>%
  mutate(velocity = (current - original) / original)

ex_dat %>%
  filter(GRP == 'treatment') %>%
  filter(current - original == 0)

treatment <- ex_dat %>% filter(GRP == 'treatment') %>% pull(velocity)
control <- ex_dat %>% filter(GRP == 'control') %>% pull(velocity)

t.test(x = treatment, y = control)

ex_dat %>% 
  ggplot(aes(x = log(velocity), col = GRP)) +
  geom_density() +
  xlab("tx growth (log)") +
  theme_bw()

ex_dat %>% 
  ggplot(aes(x = log(current), col = GRP)) +
  geom_density() +
  xlab("current nonce (log)") +
  theme_bw()

ex_dat %>%
  ggplot(aes(x = log(original), col = GRP)) +
  geom_density() +
  xlab("original nonce (log)") +
  theme_bw()


ex_dat %>%
  group_by(GRP) %>%
  summarize(no_txs = sum(current - original == 0) / length(ADDRESS))
