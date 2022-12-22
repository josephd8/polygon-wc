
addresses_query <- "
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

post_mint_txs AS (
  SELECT
  	tx_hash,
  	nonce,
  	from_address,
  	gas_used,
  	gas_price
  FROM polygon.core.fact_transactions
  WHERE block_timestamp >= '2022-11-18'
    AND from_address IN (SELECT address FROM addresses)
),

post_mint_nonces AS (
  SELECT
  	from_address AS address,
  	MAX(nonce) AS nonce
  FROM post_mint_txs
  GROUP BY 1
),

user_pre_tmp AS (
  SELECT
  	u.address,
  	p.nonce
  FROM addresses u 
  LEFT JOIN pre_mint_nonces p ON u.address = p.address
),

user_post_tmp AS (
  SELECT
  	u.address,
  	p.nonce
  FROM addresses u 
  LEFT JOIN post_mint_nonces p ON u.address = p.address
)

-- mint addresses
SELECT
  'total' AS type,
  COUNT(DISTINCT address)
FROM addresses

UNION ALL

-- existing addresses
SELECT
  'existing' AS type,
  COUNT(DISTINCT address)
FROM user_pre_tmp
WHERE nonce >= 0

UNION ALL
  
-- brand new address
SELECT 
  'new' AS type,
  COUNT(DISTINCT address)
FROM user_pre_tmp
WHERE NONCE IS NULL

UNION ALL
  
-- existing addresses w/ 1+ more txs
SELECT
  'existing+' AS type,
  COUNT(DISTINCT a.address)
FROM user_pre_tmp a
LEFT JOIN user_post_tmp b ON a.address = b.address
WHERE (a.nonce >= 0 AND b.nonce - a.nonce >= 1)

UNION ALL
  
-- new addresses w/ 1+ txs
SELECT
  'new+' AS type,
  COUNT(DISTINCT a.address)
FROM user_pre_tmp a
LEFT JOIN user_post_tmp b ON a.address = b.address
WHERE (a.nonce IS NULL AND b.nonce >= 0)

"