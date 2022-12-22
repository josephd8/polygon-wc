
existing_address_query <- "
WITH transfer_events AS (
  SELECT
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

transfers AS (
  SELECT
  	block_number,
  	block_timestamp,
  	tx_hash,
  	event_index,
  	event_name,
  	tx_status,
  	_from AS from_addr,
  	_to AS to_addr,
  	_id AS id,
  	_value AS amount
  FROM transfer_events
),

mint AS (
  SELECT
  	*
  FROM transfers
  WHERE lower(from_addr) = lower('0x5850ca4f7456989bbd88cf6df9ca6437bbf7018b')
),
  
addresses AS (
  SELECT
  	DISTINCT to_addr AS address
  FROM mint
),

pre_mint_txs AS (
  SELECT
  	tx_hash,
  	nonce,
  	from_address,
  	gas_used,
  	gas_price
  FROM polygon.core.fact_transactions
  WHERE block_timestamp < '2022-11-18'
    AND from_address IN (SELECT address FROM addresses)
),

pre_mint_nonces AS (
  SELECT
  	from_address AS address,
  	MAX(nonce) AS nonce
  FROM pre_mint_txs
  GROUP BY 1
),

pre_mint_txs_sample AS (
  SELECT
  	tx_hash,
  	nonce,
  	from_address,
  	gas_used,
  	gas_price
  FROM polygon.core.fact_transactions
  SAMPLE (1000000 rows)
  WHERE block_timestamp < '2022-11-18'
),

pre_mint_nonces_sample AS (
  SELECT
  	from_address AS address,
  	MAX(nonce) AS nonce
  FROM pre_mint_txs_sample
  GROUP BY 1
),

treatment_base AS (
  SELECT
    'treatment' AS grp,
    address,
    nonce AS original_nonce
  FROM pre_mint_nonces
  WHERE nonce >= 0
),

control_base AS (
  SELECT
    'control' AS grp,
    address,
    nonce AS original_nonce
  FROM pre_mint_nonces_sample
  SAMPLE (25000 rows)
  WHERE address NOT IN (SELECT address FROM treatment_base)
),

base AS (
  SELECT * FROM treatment_base
  UNION ALL
  SELECT * FROM control_base
),

post_mint_txs AS (
  SELECT
  	from_address AS address,
  	MAX(nonce) AS current_nonce
  FROM polygon.core.fact_transactions
  WHERE from_address IN (SELECT DISTINCT address FROM base)
  GROUP BY 1
),

tmp AS (
  SELECT
    b.grp,
    b.address,
    b.original_nonce,
    p.current_nonce
  FROM base b
  LEFT JOIN post_mint_txs p ON b.address = p.address
)

SELECT * FROM tmp
"