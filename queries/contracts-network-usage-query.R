
contracts_network_usage_query <- "
WITH blocks AS (
  SELECT
    block_number,
    block_timestamp,
    ethereum.public.udf_hex_to_int(block_header_json:baseFeePerGas) / POW(10,18) AS base_fee_per_gas
  FROM polygon.core.fact_blocks
  WHERE block_timestamp >= '2022-11-18' AND block_timestamp <= CURRENT_DATE()
),

events AS (
  SELECT
    contract_address,
    COUNT(*) AS events
  FROM polygon.core.fact_event_logs l 
  WHERE block_timestamp >= '2022-11-18' AND block_timestamp <= CURRENT_DATE()
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
