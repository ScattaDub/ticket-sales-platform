-- =============================================================================
-- Ticket Sales Platform — Seed data (DML)
-- PostgreSQL
--
-- Run after schema.sql:
--   psql "$DATABASE_URL" -f db/schema.sql
--   psql "$DATABASE_URL" -f db/seed.sql
--
-- Idempotent: every table is truncated and identity sequences restart, so
-- repeated runs always produce the same state instead of piling up duplicates.
--
-- Primary keys are GENERATED ALWAYS AS IDENTITY, so ids cannot be written
-- explicitly and must not be guessed. Foreign keys are therefore resolved by
-- natural keys (email, slug, title) via INSERT ... SELECT, or by chaining
-- CTEs with RETURNING where no natural key exists (orders).
-- =============================================================================

BEGIN;

TRUNCATE tickets,
         order_items,
         orders,
         ticket_types,
         event_categories,
         events,
         categories,
         venues,
         users
    RESTART IDENTITY CASCADE;

-- -----------------------------------------------------------------------------
-- users
-- -----------------------------------------------------------------------------
-- Passwords are hashed with pgcrypto so that no plaintext is ever stored,
-- even in seed data. Every account below uses the password 'password123'.
INSERT INTO users (email, password_hash, full_name, role)
VALUES ('admin@example.com',     crypt('password123', gen_salt('bf')), 'Alice Morgan',  'admin'),
       ('organizer@example.com', crypt('password123', gen_salt('bf')), 'Paul Turner',   'organizer'),
       ('promo@example.com',     crypt('password123', gen_salt('bf')), 'Maria Vega',    'organizer'),
       ('anna@example.com',      crypt('password123', gen_salt('bf')), 'Anna Kim',      'visitor'),
       ('boris@example.com',     crypt('password123', gen_salt('bf')), 'Ben Hollis',    'visitor');

-- -----------------------------------------------------------------------------
-- venues
-- -----------------------------------------------------------------------------
-- Names are unique here on purpose: they act as the natural key that events
-- below join against.
INSERT INTO venues (name, address, city, capacity)
VALUES ('Riverside Arena',    '20 Harbour Road',      'Manchester',  6200),
       ('The Glasshouse Club', '14 Kiln Street',      'Bristol',      500),
       ('Ice Palace',         '1 Olympic Way',        'Leeds',      12300),
       ('Loft Space',         '74 Canal Embankment',  'Bristol',      300);

-- -----------------------------------------------------------------------------
-- categories
-- -----------------------------------------------------------------------------
INSERT INTO categories (name, slug)
VALUES ('Concerts',    'concerts'),
       ('Theatre',     'theatre'),
       ('Sport',       'sport'),
       ('Conferences', 'conferences'),
       ('Festivals',   'festivals');

-- -----------------------------------------------------------------------------
-- events
-- -----------------------------------------------------------------------------
-- Dates are relative to now() so the seed stays meaningful whenever it runs:
-- upcoming events stay upcoming, the completed one stays in the past.
-- All four statuses are represented, including a draft with no published_at.
INSERT INTO events (organizer_id, venue_id, title, description, status, starts_at, ends_at, published_at)
SELECT u.id,
       v.id,
       e.title,
       e.description,
       e.status,
       e.starts_at,
       e.ends_at,
       e.published_at
FROM (
         VALUES ('organizer@example.com', 'Riverside Arena', 'Rock Symphony',
                 'A symphony orchestra plays rock classics.',
                 'published', now() + interval '30 days', now() + interval '30 days 3 hours',
                 now() - interval '20 days'),

                ('organizer@example.com', 'The Glasshouse Club', 'Indie Fest: Three Stages',
                 'Twelve bands, three stages, one day.',
                 'published', now() + interval '14 days', now() + interval '14 days 9 hours',
                 now() - interval '30 days'),

                ('promo@example.com', 'Ice Palace', 'Hockey: Regular Season Final',
                 'The closing match of the regular season.',
                 'published', now() + interval '45 days', now() + interval '45 days 2 hours',
                 now() - interval '10 days'),

                ('promo@example.com', 'Loft Space', 'Silent Film Retrospective',
                 'Screenings with live piano. Programme still being finalised.',
                 'draft', now() + interval '60 days', now() + interval '60 days 4 hours',
                 NULL),

                ('organizer@example.com', 'The Glasshouse Club', 'Jazz Evenings',
                 'Three nights of contemporary jazz.',
                 'completed', now() - interval '40 days', now() - interval '40 days' + interval '3 hours',
                 now() - interval '80 days'),

                ('promo@example.com', 'Loft Space', 'Standup Marathon',
                 'Cancelled because of venue issues.',
                 'cancelled', now() + interval '10 days', now() + interval '10 days 5 hours',
                 now() - interval '25 days')
     ) AS e(organizer_email, venue_name, title, description, status, starts_at, ends_at, published_at)
         JOIN users u ON u.email = e.organizer_email
         JOIN venues v ON v.name = e.venue_name;

-- -----------------------------------------------------------------------------
-- event_categories (M:N)
-- -----------------------------------------------------------------------------
INSERT INTO event_categories (event_id, category_id)
SELECT ev.id, c.id
FROM (
         VALUES ('Rock Symphony',                'concerts'),
                ('Indie Fest: Three Stages',     'concerts'),
                ('Indie Fest: Three Stages',     'festivals'),
                ('Hockey: Regular Season Final', 'sport'),
                ('Silent Film Retrospective',    'festivals'),
                ('Jazz Evenings',                'concerts'),
                ('Standup Marathon',             'theatre')
     ) AS ec(event_title, category_slug)
         JOIN events ev ON ev.title = ec.event_title
         JOIN categories c ON c.slug = ec.category_slug;

-- -----------------------------------------------------------------------------
-- ticket_types
-- -----------------------------------------------------------------------------
-- The draft event deliberately has no ticket types: nothing is on sale yet.
-- 'VIP Box' is deliberately tiny (20 seats, 19 of them sold below) — it is the
-- fixture for the week 4 concurrent-purchase exercise on quantity_sold.
INSERT INTO ticket_types (event_id, name, price_cents, quantity_total, sales_start_at, sales_end_at)
SELECT ev.id,
       tt.name,
       tt.price_cents,
       tt.quantity_total,
       tt.sales_start_at,
       tt.sales_end_at
FROM (
         VALUES ('Rock Symphony',                'Stalls',   450000,  800, now() - interval '20 days', now() + interval '29 days'),
                ('Rock Symphony',                'Balcony',  250000, 1200, now() - interval '20 days', now() + interval '29 days'),
                ('Indie Fest: Three Stages',     'Standard', 180000,  400, now() - interval '30 days', now() + interval '13 days'),
                ('Indie Fest: Three Stages',     'VIP Box',  500000,   20, now() - interval '30 days', now() + interval '13 days'),
                ('Hockey: Regular Season Final', 'Stand A',  300000, 5000, now() - interval '10 days', now() + interval '44 days'),
                ('Hockey: Regular Season Final', 'Stand B',  200000, 6000, now() - interval '10 days', now() + interval '44 days'),
                ('Jazz Evenings',                'Entry',    150000,  300, now() - interval '90 days', now() - interval '41 days'),
                ('Standup Marathon',             'General',  200000,  250, now() - interval '25 days', now() + interval '9 days')
     ) AS tt(event_title, name, price_cents, quantity_total, sales_start_at, sales_end_at)
         JOIN events ev ON ev.title = tt.event_title;

-- -----------------------------------------------------------------------------
-- orders + order_items
-- -----------------------------------------------------------------------------
-- Orders have no natural key (the same user may place several), so each order
-- is inserted with a CTE and its generated id is piped straight into its items
-- via RETURNING — one statement, no guessing at sequence values.
-- total_cents is filled in afterwards from the items, so the header can never
-- disagree with its own lines.

-- Order 1 — Anna, paid.
WITH new_order AS (
    INSERT INTO orders (user_id, status, total_cents)
        SELECT id, 'paid', 0 FROM users WHERE email = 'anna@example.com'
        RETURNING id
),
     items(event_title, ticket_type_name, quantity) AS (
         VALUES ('Rock Symphony', 'Stalls', 2),
                ('Rock Symphony', 'Balcony', 1)
     )
INSERT
INTO order_items (order_id, ticket_type_id, quantity, unit_price_cents)
SELECT o.id, tt.id, i.quantity, tt.price_cents
FROM new_order o
         CROSS JOIN items i
         JOIN events ev ON ev.title = i.event_title
         JOIN ticket_types tt ON tt.event_id = ev.id AND tt.name = i.ticket_type_name;

-- Order 2 — Ben, paid. Takes 19 of the 20 VIP seats.
WITH new_order AS (
    INSERT INTO orders (user_id, status, total_cents)
        SELECT id, 'paid', 0 FROM users WHERE email = 'boris@example.com'
        RETURNING id
),
     items(event_title, ticket_type_name, quantity) AS (
         VALUES ('Indie Fest: Three Stages', 'VIP Box', 19)
     )
INSERT
INTO order_items (order_id, ticket_type_id, quantity, unit_price_cents)
SELECT o.id, tt.id, i.quantity, tt.price_cents
FROM new_order o
         CROSS JOIN items i
         JOIN events ev ON ev.title = i.event_title
         JOIN ticket_types tt ON tt.event_id = ev.id AND tt.name = i.ticket_type_name;

-- Order 3 — Anna, paid, for the event that has already happened.
WITH new_order AS (
    INSERT INTO orders (user_id, status, total_cents)
        SELECT id, 'paid', 0 FROM users WHERE email = 'anna@example.com'
        RETURNING id
),
     items(event_title, ticket_type_name, quantity) AS (
         VALUES ('Jazz Evenings', 'Entry', 2)
     )
INSERT
INTO order_items (order_id, ticket_type_id, quantity, unit_price_cents)
SELECT o.id, tt.id, i.quantity, tt.price_cents
FROM new_order o
         CROSS JOIN items i
         JOIN events ev ON ev.title = i.event_title
         JOIN ticket_types tt ON tt.event_id = ev.id AND tt.name = i.ticket_type_name;

-- Order 4 — Anna, pending. Reserved but not paid: must NOT count as sold.
WITH new_order AS (
    INSERT INTO orders (user_id, status, total_cents)
        SELECT id, 'pending', 0 FROM users WHERE email = 'anna@example.com'
        RETURNING id
),
     items(event_title, ticket_type_name, quantity) AS (
         VALUES ('Hockey: Regular Season Final', 'Stand A', 3)
     )
INSERT
INTO order_items (order_id, ticket_type_id, quantity, unit_price_cents)
SELECT o.id, tt.id, i.quantity, tt.price_cents
FROM new_order o
         CROSS JOIN items i
         JOIN events ev ON ev.title = i.event_title
         JOIN ticket_types tt ON tt.event_id = ev.id AND tt.name = i.ticket_type_name;

-- Order 5 — Ben, cancelled. Also must NOT count as sold.
WITH new_order AS (
    INSERT INTO orders (user_id, status, total_cents)
        SELECT id, 'cancelled', 0 FROM users WHERE email = 'boris@example.com'
        RETURNING id
),
     items(event_title, ticket_type_name, quantity) AS (
         VALUES ('Indie Fest: Three Stages', 'Standard', 2)
     )
INSERT
INTO order_items (order_id, ticket_type_id, quantity, unit_price_cents)
SELECT o.id, tt.id, i.quantity, tt.price_cents
FROM new_order o
         CROSS JOIN items i
         JOIN events ev ON ev.title = i.event_title
         JOIN ticket_types tt ON tt.event_id = ev.id AND tt.name = i.ticket_type_name;

-- Order totals are derived, never typed in by hand.
UPDATE orders o
SET total_cents = agg.total
FROM (
         SELECT order_id, SUM(quantity * unit_price_cents) AS total
         FROM order_items
         GROUP BY order_id
     ) AS agg
WHERE agg.order_id = o.id;

-- -----------------------------------------------------------------------------
-- tickets
-- -----------------------------------------------------------------------------
-- One physical ticket per unit bought: generate_series expands an order item of
-- quantity N into N rows. Only paid orders produce tickets.
-- The code is random, not sequential — it is a public identifier and must not
-- be guessable from a neighbouring ticket.
INSERT INTO tickets (order_item_id, ticket_type_id, owner_id, code)
SELECT oi.id,
       oi.ticket_type_id,
       o.user_id,
       upper(encode(gen_random_bytes(6), 'hex'))
FROM order_items oi
         JOIN orders o ON o.id = oi.order_id
         CROSS JOIN LATERAL generate_series(1, oi.quantity)
WHERE o.status = 'paid';

-- Tickets for an event that already took place were checked in at the door.
UPDATE tickets t
SET status = 'used'
FROM ticket_types tt
         JOIN events ev ON ev.id = tt.event_id
WHERE t.ticket_type_id = tt.id
  AND ev.status = 'completed';

-- -----------------------------------------------------------------------------
-- ticket_types.quantity_sold
-- -----------------------------------------------------------------------------
-- Derived from paid orders rather than hardcoded, so the seed can never start
-- life violating CHECK (quantity_sold <= quantity_total). Types with no paid
-- orders keep their DEFAULT 0.
UPDATE ticket_types tt
SET quantity_sold = agg.sold
FROM (
         SELECT oi.ticket_type_id, SUM(oi.quantity) AS sold
         FROM order_items oi
                  JOIN orders o ON o.id = oi.order_id
         WHERE o.status = 'paid'
         GROUP BY oi.ticket_type_id
     ) AS agg
WHERE agg.ticket_type_id = tt.id;

COMMIT;

-- -----------------------------------------------------------------------------
-- Summary
-- -----------------------------------------------------------------------------
SELECT 'users' AS table_name, count(*) FROM users
UNION ALL SELECT 'venues', count(*) FROM venues
UNION ALL SELECT 'categories', count(*) FROM categories
UNION ALL SELECT 'events', count(*) FROM events
UNION ALL SELECT 'event_categories', count(*) FROM event_categories
UNION ALL SELECT 'ticket_types', count(*) FROM ticket_types
UNION ALL SELECT 'orders', count(*) FROM orders
UNION ALL SELECT 'order_items', count(*) FROM order_items
UNION ALL SELECT 'tickets', count(*) FROM tickets
ORDER BY table_name;
