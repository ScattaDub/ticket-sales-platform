-- =============================================================================
-- Ticket Sales Platform — Example Analytical Queries
-- Read-only reporting queries. Run after schema.sql + seed.sql.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Top events by revenue
-- Aggregation across orders -> order_items -> ticket_types -> events.
-- -----------------------------------------------------------------------------
SELECT e.title,
       SUM(oi.quantity * oi.unit_price_cents) AS revenue_cents
FROM events e
         JOIN ticket_types tt ON tt.event_id = e.id
         JOIN order_items  oi ON oi.ticket_type_id = tt.id
GROUP BY e.id, e.title
ORDER BY revenue_cents DESC
    LIMIT 5;

-- -----------------------------------------------------------------------------
-- Tickets sold per event
-- -----------------------------------------------------------------------------
SELECT tt.event_id,
       COUNT(t.id) AS tickets_sold
FROM tickets t
         JOIN ticket_types tt ON tt.id = t.ticket_type_id
GROUP BY tt.event_id;

-- -----------------------------------------------------------------------------
-- Events with their categories (M:N join)
-- -----------------------------------------------------------------------------
SELECT e.title,
       c.name AS category
FROM events e
         JOIN event_categories ec ON ec.event_id = e.id
         JOIN categories       c  ON c.id = ec.category_id
ORDER BY e.title;

-- -----------------------------------------------------------------------------
-- Tickets sold per category
-- LEFT JOIN from categories so categories with zero sales still appear.
-- -----------------------------------------------------------------------------
SELECT c.name AS category,
       COUNT(t.id) AS tickets_sold
FROM categories c
         JOIN event_categories ec ON ec.category_id = c.id
         JOIN events       e  ON e.id  = ec.event_id
         JOIN ticket_types tt ON tt.event_id = e.id
         LEFT JOIN tickets t  ON t.ticket_type_id = tt.id
GROUP BY c.id, c.name
ORDER BY tickets_sold DESC;

-- -----------------------------------------------------------------------------
-- Top event per organizer (window function)
-- row_number() partitioned by organizer, ranked by revenue.
-- -----------------------------------------------------------------------------
SELECT organizer_id, title, revenue_cents
FROM (
         SELECT e.organizer_id,
                e.title,
                SUM(oi.quantity * oi.unit_price_cents) AS revenue_cents,
                ROW_NUMBER() OVER (
               PARTITION BY e.organizer_id
               ORDER BY SUM(oi.quantity * oi.unit_price_cents) DESC
           ) AS rn
         FROM events e
                  JOIN ticket_types tt ON tt.event_id = e.id
                  JOIN order_items  oi ON oi.ticket_type_id = tt.id
         GROUP BY e.id, e.title, e.organizer_id
     ) ranked
WHERE rn = 1;

-- -----------------------------------------------------------------------------
-- Events sold more than 80% of capacity
-- Aggregates sold/total across all ticket types of an event.
-- -----------------------------------------------------------------------------
SELECT e.title,
       SUM(tt.quantity_sold)  AS sold,
       SUM(tt.quantity_total) AS total,
       ROUND(SUM(tt.quantity_sold)::numeric / SUM(tt.quantity_total), 4) AS ratio
FROM events e
         JOIN ticket_types tt ON tt.event_id = e.id
GROUP BY e.id, e.title
HAVING SUM(tt.quantity_sold)::numeric / SUM(tt.quantity_total) > 0.8;