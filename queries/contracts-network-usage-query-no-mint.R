
contracts_network_usage_no_mint_query <- "
WITH blocks AS (
  SELECT
    block_number,
    block_timestamp,
    ethereum.public.udf_hex_to_int(block_header_json:baseFeePerGas) / POW(10,18) AS base_fee_per_gas
  FROM polygon.core.fact_blocks
  WHERE block_timestamp >= '2022-11-18' AND block_timestamp <= CURRENT_DATE()
),

wc_mint_events AS (
  SELECT
    _log_id,
    tx_hash
  FROM polygon.core.fact_event_logs
  WHERE (lower(contract_address) = lower('0x9f202e685461B656b5b0e18EbDDCC626837D8aFd')
    AND lower(event_inputs:_from) = lower('0x5850ca4f7456989bbd88cf6df9ca6437bbf7018b'))
),

events AS (
  SELECT
    contract_address,
    COUNT(*) AS events
  FROM polygon.core.fact_event_logs l 
  WHERE block_timestamp >= '2022-11-18' AND block_timestamp <= CURRENT_DATE()
    AND _log_id NOT IN (SELECT DISTINCT _log_id FROM wc_mint_events)
  GROUP BY 1
),

txns AS (
  SELECT
    DISTINCT
    l.contract_address,
    l.tx_hash,
    t.gas_used * b.base_fee_per_gas AS burn,
    t.tx_fee AS tx_fee
  FROM polygon.core.fact_event_logs l 
  LEFT JOIN blocks b ON l.block_number = b.block_number
  LEFT JOIN polygon.core.fact_transactions t ON l.tx_hash = t.tx_hash
  WHERE l.block_timestamp >= '2022-11-18' AND l.block_timestamp <= CURRENT_DATE()
    AND l.tx_hash NOT IN (SELECT DISTINCT tx_hash FROM wc_mint_events)
),

agg AS (
  SELECT
    contract_address,
    SUM(burn) AS burn,
    SUM(tx_fee) AS tx_fee,
    COUNT(DISTINCT tx_hash) AS txns
  FROM txns
  GROUP BY 1
)

SELECT 
  a.*,
  e.events
FROM agg a
LEFT JOIN events e ON a.contract_address = e.contract_address
"