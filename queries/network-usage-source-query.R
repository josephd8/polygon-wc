
network_usage_source_query <- "
WITH blocks AS (
  SELECT
    block_number,
    block_timestamp,
    ethereum.public.udf_hex_to_int(block_header_json:baseFeePerGas) / POW(10,18) AS base_fee_per_gas
  FROM polygon.core.fact_blocks
  WHERE block_timestamp >= '2022-11-18' AND block_timestamp <= CURRENT_DATE()
),

transfer_events AS (
  SELECT
    _log_id,
    block_number,
    block_timestamp,
    tx_hash,
    event_index,
    event_name,
    tx_status,
    event_inputs:_from AS _from,
    event_inputs:_to AS _to,
    event_inputs:_id AS _id,
    event_inputs:_value AS _value
  FROM polygon.core.fact_event_logs
  WHERE lower(contract_address) = lower('0x9f202e685461B656b5b0e18EbDDCC626837D8aFd')
  	AND (event_name = 'TransferSingle')

  UNION ALL

  SELECT
    _log_id,
    block_number,
    block_timestamp,
    tx_hash,
    event_index,
    event_name,
    tx_status,
    event_inputs:_from AS _from,
    event_inputs:_to AS _to,
    event_inputs:_ids AS _id,
    ARRAY_SIZE(event_inputs:_values) AS _value
  FROM polygon.core.fact_event_logs
  WHERE lower(contract_address) = lower('0x9f202e685461B656b5b0e18EbDDCC626837D8aFd')
  	AND (event_name = 'TransferBatch')
),

mint_events AS (
  SELECT
    _log_id
  FROM transfer_events
  WHERE _from = '0x5850ca4f7456989bbd88cf6df9ca6437bbf7018b'
),

external_events AS (
  SELECT
    _log_id,
    block_number,
    block_timestamp,
    tx_hash,
    event_index,
    event_name,
    tx_status
  FROM polygon.core.fact_event_logs
  WHERE lower(contract_address) = lower('0x9f202e685461B656b5b0e18EbDDCC626837D8aFd')
    AND _log_id NOT IN (SELECT DISTINCT _log_id FROM mint_events)
),
  
mint AS (
  SELECT
    DISTINCT
    'polygon' AS source,
    m.tx_hash,
    t.gas_used * b.base_fee_per_gas AS burn,
    t.tx_fee AS tx_fee
  FROM transfer_events m
  LEFT JOIN polygon.core.fact_transactions t ON m.tx_hash = t.tx_hash
  LEFT JOIN blocks b ON m.block_number = b.block_number
  WHERE m._from = '0x5850ca4f7456989bbd88cf6df9ca6437bbf7018b'
),

external AS (
  SELECT
    DISTINCT
    'external' AS source,
    e.tx_hash,
    t.gas_used * b.base_fee_per_gas AS burn,
    t.tx_fee AS tx_fee
  FROM external_events e
  LEFT JOIN polygon.core.fact_transactions t ON e.tx_hash = t.tx_hash
  LEFT JOIN blocks b ON e.block_number = b.block_number
),

combined AS (
  SELECT * FROM mint
  UNION ALL
  SELECT * FROM external
)

SELECT
  source,
  COUNT(DISTINCT tx_hash) AS n_txns,
  SUM(burn) AS burned,
  SUM(tx_fee) AS tx_fees
FROM combined
GROUP BY 1

"