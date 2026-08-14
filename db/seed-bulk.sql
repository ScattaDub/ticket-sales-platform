-- =============================================================================
-- Ticket Sales Platform — Bulk seed data (DML, optional)
-- PostgreSQL
--
-- Run after seed.sql:
--   psql "$DATABASE_URL" -f db/schema.sql
--   psql "$DATABASE_URL" -f db/seed.sql
--   psql "$DATABASE_URL" -f db/seed-bulk.sql
--
-- Adds 10 000 tickets on top of the base seed. The base seed is deliberately
-- small so it stays readable; this file exists because the week 2 streaming
-- experiments (cursor reads, backpressure, CSV export) only show anything
-- interesting on a dataset that does not fit comfortably in memory.
--
-- Everything it creates hangs off a single ticket type named 'Bulk Entry',
-- which is also how the script cleans up after itself and stays idempotent.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- Clean up a previous bulk run
-- -----------------------------------------------------------------------------
-- Deleted in FK order: tickets -> order_items -> orders -> ticket_types.
-- All of it is reachable from the 'Bulk Entry' ticket type, so nothing from the
-- base seed is ever touched. A first run deletes nothing and that is fine.
DELETE
FROM tickets
WHERE ticket_type_id IN (SELECT id FROM ticket_types WHERE name = 'Bulk Entry');

-- The orders are identified by the items being removed, so both deletes happen
-- in one statement: DELETE ... RETURNING feeds the outer DELETE.
WITH removed_items AS (
    DELETE FROM order_items
        WHERE ticket_type_id IN (SELECT id FROM ticket_types WHERE name = 'Bulk Entry')
        RETURNING order_id
)
DELETE
FROM orders
WHERE id IN (SELECT order_id FROM removed_items);

DELETE FROM ticket_types WHERE name = 'Bulk Entry';

-- -----------------------------------------------------------------------------
-- Bulk ticket type
-- -----------------------------------------------------------------------------
-- Attached to an existing event rather than a new one, so the M:N categories
-- and the event list stay exactly as the base seed left them.
-- 12 000 seats at a venue with capacity 12 300.
INSERT INTO ticket_types (event_id, name, price_cents, quantity_total, sales_start_at, sales_end_at)
SELECT id,
       'Bulk Entry',
       120000,
       12000,
       now() - interval '10 days',
       now() + interval '44 days'
FROM events
WHERE title = 'Hockey: Regular Season Final';

-- -----------------------------------------------------------------------------
-- One large paid order per user
-- -----------------------------------------------------------------------------
-- 5 users x 2 000 tickets = 10 000, comfortably inside quantity_total.
-- Spreading them over every user keeps the exported CSV varied instead of
-- repeating a single name ten thousand times.
WITH new_orders AS (
    INSERT INTO orders (user_id, status, total_cents)
        SELECT id, 'paid', 0 FROM users
        RETURNING id, user_id
)
INSERT
INTO order_items (order_id, ticket_type_id, quantity, unit_price_cents)
SELECT o.id, tt.id, 2000, tt.price_cents
FROM new_orders o
         CROSS JOIN ticket_types tt
WHERE tt.name = 'Bulk Entry';

-- -----------------------------------------------------------------------------
-- Tickets
-- -----------------------------------------------------------------------------
-- generate_series expands each item of quantity N into N ticket rows.
INSERT INTO tickets (order_item_id, ticket_type_id, owner_id, code)
SELECT oi.id,
       oi.ticket_type_id,
       o.user_id,
       upper(encode(gen_random_bytes(6), 'hex'))
FROM order_items oi
         JOIN orders o ON o.id = oi.order_id
         JOIN ticket_types tt ON tt.id = oi.ticket_type_id
         CROSS JOIN LATERAL generate_series(1, oi.quantity)
WHERE tt.name = 'Bulk Entry';

-- -----------------------------------------------------------------------------
-- Re-derive the aggregates
-- -----------------------------------------------------------------------------
-- Same rule as in seed.sql: totals and quantity_sold are computed, never typed.
UPDATE orders o
SET total_cents = agg.total
FROM (
         SELECT order_id, SUM(quantity * unit_price_cents) AS total
         FROM order_items
         GROUP BY order_id
     ) AS agg
WHERE agg.order_id = o.id;

UPDATE ticket_types tt
SET quantity_sold = COALESCE(agg.sold, 0)
FROM (
         SELECT tt2.id AS ticket_type_id,
                (SELECT SUM(oi.quantity)
                 FROM order_items oi
                          JOIN orders o ON o.id = oi.order_id
                 WHERE oi.ticket_type_id = tt2.id
                   AND o.status = 'paid') AS sold
         FROM ticket_types tt2
     ) AS agg
WHERE agg.ticket_type_id = tt.id;

COMMIT;

-- -----------------------------------------------------------------------------
-- Summary
-- -----------------------------------------------------------------------------
SELECT 'tickets' AS table_name, count(*) FROM tickets
UNION ALL SELECT 'orders', count(*) FROM orders
UNION ALL SELECT 'order_items', count(*) FROM order_items
ORDER BY table_name;
