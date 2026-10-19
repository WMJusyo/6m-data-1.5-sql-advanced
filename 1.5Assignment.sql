
-- CTE 1 here establishes the average claim amount for each car type according to the market and compares it with each claim record. 
-- This information tells us which claims are above or below the market average for their respective car types
WITH market_comparison AS (
    SELECT
c.id, cl.client_id, cl.claim_amt, c.car_type, AVG(cl.claim_amt) OVER (PARTITION BY car_type) AS avg_claim_by_car_type
FROM car c
join claim cl ON cl.car_id = c.id
),
-- CTE 2 expands on CTE 1 by calculating the total claim amount for each client and car type combination. which allows for CTE 3 to associate each client with their total claim amount.
client_totals AS (
    SELECT client_id, car_type, SUM(claim_amt) AS total_claimed
    FROM market_comparison
    GROUP BY client_id, car_type
),
-- CTE 3 associates each claim with the client with their total claim amount
-- From here, we can identify which clients have the highest total claim amounts within their respective states (with CTE 4).
    SELECT
        client_id,
        cli.first_name || ' ' || cli.last_name AS client_name,
        a.state,
        ct.car_type,
        ct.total_claimed
    FROM client_totals ct
    INNER JOIN client cli ON ct.client_id = cli.id
    INNER JOIN address a ON cli.address_id = a.id
),
-- with CTE 3, now we create CTE 4, ranked_clients, to rank them within their state.
ranked_clients AS (
    SELECT *,
        RANK() OVER (PARTITION BY state ORDER BY total_claimed DESC) AS state_rank
    FROM client_details
)
-- Finally, we select the top 2 clients from each state based on their total claimed amount. Each column is renamed for clarity.
SELECT
    client_name AS "Client Name",
    state       AS "State",
    car_type    AS "Car Type",
    ROUND(total_claimed, 2) AS "Total Claimed",
    state_rank  AS "State Rank"
FROM ranked_clients
WHERE state_rank <= 2
ORDER BY state, state_rank;
SELECT * FROM client_details LIMIT 10;