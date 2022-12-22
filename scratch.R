#libaries
library(shroomDK)
library(tidyverse)

###### pull data from flipside #####
# key <- readLines("api-key.txt")

# query <- "
# SELECT
#   block_number,
#   block_timestamp,
#   tx_hash,
#   event_index,
#   event_name,
#   event_inputs,
#   tx_status
# FROM polygon.core.fact_event_logs
# WHERE lower(contract_address) = lower('0x9f202e685461B656b5b0e18EbDDCC626837D8aFd')
# 	AND (event_name = 'TransferBatch' OR event_name = 'TransferSingle')
# "
#
# dat <- auto_paginate_query(
#   query = query,
#   api_key = key
# )

dat <- readRDS("data.rds")
events <- as_tibble(dat)

###### EDA #####
View(events)

single <- events %>%
  filter(EVENT_NAME == 'TransferSingle')
batch <- events %>%
  filter(EVENT_NAME == 'TransferBatch')

single$EVENT_INPUTS[1][[1]][1] # from
events$EVENT_INPUTS[1][[1]][2] # id

single$EVENT_INPUTS[1][[1]][5]
batch$EVENT_INPUTS[1][[1]][5]

as.numeric(unlist(batch$EVENT_INPUTS[1][[1]][2]))
as.numeric(unlist(batch$EVENT_INPUTS[1][[1]][5]))

# 1 = from
# 2 = id(s)
# 3 = operator
# 4 = to
# 5 = value(s)

timestamps <- lubridate::as_datetime(unlist(events$BLOCK_TIMESTAMP))
min(timestamps) # 2022-11-18 12:42:36 UTC
max(timestamps) # 2022-12-14 14:55:36 UTC -- will update if we pull new data

###### transform events data #####
## single transfers
singles <- apply(single, 1, function(x){
  
  from <- x['EVENT_INPUTS'][[1]][1]
  to <- x['EVENT_INPUTS'][[1]][4]
  id <- x['EVENT_INPUTS'][[1]][2]
  amount <- x['EVENT_INPUTS'][[1]][5]
  
  c(from, to, id, amount)
  
})

singles_tmp <- as.data.frame(do.call(rbind, singles))

single_transfers <- single %>%
  select(-EVENT_INPUTS) %>%
  cbind(singles_tmp)

names(single_transfers) <- c("block_number", "block_timestamp", "tx_hash", "event_index", "event_name", "tx_status",
  "from", "to", "id", "amount")

## batch transfers
batches <- apply(batch, 1, function(x){
  
  ids <- as.numeric(unlist(x['EVENT_INPUTS'][[1]][2]))
  amounts <- as.numeric(unlist(x['EVENT_INPUTS'][[1]][5]))
  
  tmp <- list()
  
  for(i in 1:length(ids)){
    out <- list(
      x$BLOCK_NUMBER, 
      x$BLOCK_TIMESTAMP, 
      x$TX_HASH, 
      x$EVENT_INDEX, 
      x$EVENT_NAME,
      x$TX_STATUS, 
      as.character(x['EVENT_INPUTS'][[1]][1]), 
      as.character(x['EVENT_INPUTS'][[1]][4]),
      ids[i],
      amounts[i]
    )
    tmp <- append(tmp, out)
  }
  tmp
})

for(b in 1:length(batches)){
  
  if(b == 1){
    batch_transfers <- as_tibble(t(matrix(unlist(batches[b]), nrow = 10)))
  } else {
    batch_transfers <- rbind(batch_transfers, as_tibble(t(matrix(unlist(batches[b]), nrow = 10)))) 
  }
  
}

names(batch_transfers) <- tolower(names(single_transfers))

# combine single and batch
transfers <- as_tibble(rbind(single_transfers, batch_transfers))

# fix data types
transfers <- transfers %>%
  mutate_at(vars(block_number, event_index, id, amount), funs(as.numeric)) %>%
  mutate_at(vars(tx_hash, event_name, tx_status, from, to), funs(as.character))

# saveRDS(transfers, "transfers.rds")

##### analysis #####
transfers %>%
  count(from) %>%
  arrange(desc(n))
# 0x5850ca4f7456989bbd88cf6df9ca6437bbf7018b = 319995

mint <- transfers %>%
  filter(from == "0x5850ca4f7456989bbd88cf6df9ca6437bbf7018b")
  
sybils <- transfers %>%
  count(to) %>%
  arrange(desc(n)) %>%
  filter(n > 30) %>%
  pull(to)

dumps <- unique(transfers %>%
  filter(to %in% sybils) %>%
  pull(from))

clean_mint <- transfers %>%
  filter(from == "0x5850ca4f7456989bbd88cf6df9ca6437bbf7018b") %>%
  filter(!to %in% sybils) %>%
  filter(!to %in% dumps)

users <- unique(clean_mint %>% pull(to))
length(users) # 47638

mint %>%
  count(to) %>%
  arrange(n) %>%
  ggplot(aes(x = n)) +
  geom_histogram() + 
  theme_bw()



# new users?
# test_query <- 
# sprintf("
# SELECT
#   tx_hash,
# 	nonce,
# 	from_address,
# 	gas_used,
# 	gas_price
# FROM polygon.core.fact_transactions
# WHERE (block_timestamp BETWEEN '2022-12-01' AND '2022-12-10')
#   AND from_address IN %s", users_str)
# 
# test_dat <- auto_paginate_query(
#   query = test_query,
#   api_key = key
# )




# cohorts
## whales
## at least touched an NFT
## touched an NFT and didn't transfer to a whale
## held NFT



