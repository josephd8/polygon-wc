gas_three_query <- "
WITH events AS (
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
  FROM events
),

mint AS (
  SELECT
  	*
  FROM transfers
  WHERE lower(from_addr) = lower('0x5850ca4f7456989bbd88cf6df9ca6437bbf7018b')
),
  
users AS (
  SELECT
  	DISTINCT to_addr AS address
  FROM mint
),

gas_one_degree AS (
  SELECT
	matic_from_address,
	matic_to_address,
  	1 AS degree,
  	SUM(amount) AS amount,
  	COUNT(*) AS n_tx,
  	MAX(block_number) - MIN(block_number) AS block_distance
  FROM polygon.core.ez_matic_transfers
  WHERE block_timestamp < '2022-11-18'
    AND matic_to_address IN (SELECT address from users)
  GROUP BY 1,2,3
),

gas_one_addresses AS (
  SELECT
  	DISTINCT matic_from_address AS address
  FROM gas_one_degree
),

gas_two_degrees AS (
  SELECT
	matic_from_address,
	matic_to_address,
  	2 AS degree,
  	SUM(amount) AS amount,
  	COUNT(*) AS n_tx,
  	MAX(block_number) - MIN(block_number) AS block_distance
  FROM polygon.core.ez_matic_transfers
  WHERE block_timestamp < '2022-11-18'
    AND matic_to_address IN (SELECT address from gas_one_addresses)
  GROUP BY 1,2,3
),

gas_two_addresses AS (
  SELECT
  	DISTINCT matic_from_address AS address
  FROM gas_two_degrees
),

gas_three_degrees AS (
  SELECT
	matic_from_address,
	matic_to_address,
  	3 AS degree,
  	SUM(amount) AS amount,
  	COUNT(*) AS n_tx,
  	MAX(block_number) - MIN(block_number) AS block_distance
  FROM polygon.core.ez_matic_transfers
  WHERE block_timestamp < '2022-11-18'
    AND matic_to_address IN (SELECT address from gas_two_addresses)
  GROUP BY 1,2,3
)

SELECT
	*
FROM gas_three_degrees
"