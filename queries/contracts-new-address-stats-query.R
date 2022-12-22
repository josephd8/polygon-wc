
contracts_new_address_stats_query <- "
WITH events AS (
  SELECT
    *
  FROM polygon.core.fact_event_logs
  WHERE block_timestamp >= '2022-11-18' AND block_timestamp <= CURRENT_DATE()
    -- AND contract_address = '0x9f202e685461b656b5b0e18ebddcc626837d8afd'
),

new_addresses AS (
  SELECT
    DISTINCT
    e.contract_address,
    t.from_address AS new_address
  FROM events e
  LEFT JOIN polygon.core.fact_transactions t ON e.tx_hash = t.tx_hash
  WHERE t.nonce = 0
),

tx_data AS (
  SELECT
    t.from_address AS new_address,
    MAX(t.nonce) AS max_nonce,
    SUM(b.gas_used * (ethereum.public.udf_hex_to_int(b.block_header_json:baseFeePerGas) / POW(10,18))) AS matic_burned,
    SUM(t.tx_fee) AS tx_fees
  FROM polygon.core.fact_transactions t
  LEFT JOIN polygon.core.fact_blocks b ON t.block_number = b.block_number
  WHERE from_address IN (SELECT DISTINCT new_address FROM new_addresses)
    AND nonce >= 0
  GROUP BY 1
),

base AS (
  SELECT
    n.contract_address,
    n.new_address,
    t.max_nonce,
    t.matic_burned,
    t.tx_fees
  FROM new_addresses n
  LEFT JOIN tx_data t ON n.new_address = t.new_address
)

SELECT 
  contract_address,
  COUNT(DISTINCT new_address) AS new_addresses,
  AVG(max_nonce) AS avg_nonce,
  MEDIAN(max_nonce) AS median_nonce,
  STDDEV(max_nonce) AS stddev_nonce,
  SUM(max_nonce) AS sum_nonce,
  AVG(matic_burned) AS avg_matic_burned,
  MEDIAN(matic_burned) AS median_matic_burned,
  STDDEV(matic_burned) AS stddev_matic_burned,
  SUM(matic_burned) AS sum_matic_burned,
  AVG(tx_fees) AS avg_tx_fees,
  MEDIAN(tx_fees) AS median_tx_fees,
  STDDEV(tx_fees) AS stddev_tx_fees,
  SUM(tx_fees) AS sum_tx_fees
FROM base
GROUP BY 1
HAVING new_addresses >= 100
"