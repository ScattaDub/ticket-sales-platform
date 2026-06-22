-- =============================================================================
-- Ticket Sales Platform — Database Schema (DDL)
-- PostgreSQL
--
-- Tables are created in dependency order:
--   users, venues, categories
--   -> events -> event_categories
--   -> ticket_types
--   -> orders -> order_items -> tickets
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Extensions
-- -----------------------------------------------------------------------------
-- pgcrypto provides crypt()/gen_salt() used to hash seed passwords.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------------------------
-- Enum types
-- -----------------------------------------------------------------------------
-- The set of roles is small and stable, so a native enum is a good fit.
-- (Status fields below intentionally use text + CHECK instead, which is easier
-- to evolve when the set of allowed values changes.)
CREATE TYPE user_role AS ENUM ('visitor', 'organizer', 'admin');

-- -----------------------------------------------------------------------------
-- users
-- -----------------------------------------------------------------------------
CREATE TABLE users (
                       id            bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                       email         text        NOT NULL,
                       password_hash text        NOT NULL,
                       full_name     text        NOT NULL,
                       role          user_role   NOT NULL DEFAULT 'visitor',
                       created_at    timestamptz NOT NULL DEFAULT now(),
                       updated_at    timestamptz NOT NULL DEFAULT now()
);

-- Case-insensitive email uniqueness: Foo@x.com and foo@x.com are the same person.
-- A functional unique index on lower(email) handles this without the citext extension.
CREATE UNIQUE INDEX users_email_unique ON users (lower(email));

-- -----------------------------------------------------------------------------
-- venues
-- -----------------------------------------------------------------------------
CREATE TABLE venues (
                        id         bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                        name       text        NOT NULL,
                        address    text        NOT NULL,
                        city       text        NOT NULL,
                        capacity   integer     NOT NULL CHECK (capacity > 0),
                        created_at timestamptz NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- categories
-- -----------------------------------------------------------------------------
CREATE TABLE categories (
                            id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                            name text   NOT NULL,
                            slug text   NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
    );

-- -----------------------------------------------------------------------------
-- events
-- -----------------------------------------------------------------------------
CREATE TABLE events (
                        id           bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                        organizer_id bigint      NOT NULL REFERENCES users(id)  ON DELETE RESTRICT,
                        venue_id     bigint      NOT NULL REFERENCES venues(id) ON DELETE RESTRICT,
                        title        text        NOT NULL,
                        description  text,
                        status       text        NOT NULL DEFAULT 'draft'
                            CHECK (status IN ('draft', 'published', 'cancelled', 'completed')),
                        starts_at    timestamptz NOT NULL,
                        ends_at      timestamptz NOT NULL,
                        published_at timestamptz,
                        created_at   timestamptz NOT NULL DEFAULT now(),
                        updated_at   timestamptz NOT NULL DEFAULT now(),

                        CONSTRAINT events_time_valid CHECK (ends_at > starts_at)
);

-- Foreign keys are NOT indexed automatically in Postgres.
-- Indexes for typical queries: organizer's events, venue's events,
-- filtering by status, and sorting/filtering by start date.
CREATE INDEX events_organizer_id_idx ON events (organizer_id);
CREATE INDEX events_venue_id_idx     ON events (venue_id);
CREATE INDEX events_status_idx       ON events (status);
CREATE INDEX events_starts_at_idx    ON events (starts_at);

-- -----------------------------------------------------------------------------
-- event_categories (M:N between events and categories)
-- -----------------------------------------------------------------------------
CREATE TABLE event_categories (
                                  event_id    bigint NOT NULL REFERENCES events(id)     ON DELETE RESTRICT,
                                  category_id bigint NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,

    -- Composite primary key: prevents duplicate (event, category) pairs and
    -- indexes the event_id side of the relationship.
                                  PRIMARY KEY (event_id, category_id)
);

-- Index the other side of the M:N relationship (category -> events lookups).
CREATE INDEX event_categories_category_id_idx ON event_categories (category_id);

-- -----------------------------------------------------------------------------
-- ticket_types
-- -----------------------------------------------------------------------------
CREATE TABLE ticket_types (
                              id             bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                              event_id       bigint      NOT NULL REFERENCES events(id) ON DELETE RESTRICT,
                              name           text        NOT NULL,
                              price_cents    integer     NOT NULL CHECK (price_cents >= 0),
                              quantity_total integer     NOT NULL CHECK (quantity_total > 0),
                              quantity_sold  integer     NOT NULL DEFAULT 0 CHECK (quantity_sold >= 0),
                              sales_start_at timestamptz NOT NULL,
                              sales_end_at   timestamptz NOT NULL,

                              CONSTRAINT ticket_types_sold_within_total  CHECK (quantity_sold <= quantity_total),
                              CONSTRAINT ticket_types_sales_window_valid CHECK (sales_end_at > sales_start_at)
);

CREATE INDEX ticket_types_event_id_idx ON ticket_types (event_id);

-- -----------------------------------------------------------------------------
-- orders
-- -----------------------------------------------------------------------------
CREATE TABLE orders (
                        id          bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                        user_id     bigint      NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
                        status      text        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'paid', 'cancelled', 'refunded')),
                        total_cents integer     NOT NULL CHECK (total_cents >= 0),
                        created_at  timestamptz NOT NULL DEFAULT now(),
                        updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX orders_user_id_idx ON orders (user_id);

-- -----------------------------------------------------------------------------
-- order_items
-- -----------------------------------------------------------------------------
CREATE TABLE order_items (
                             id               bigint  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                             order_id         bigint  NOT NULL REFERENCES orders(id)       ON DELETE RESTRICT,
                             ticket_type_id   bigint  NOT NULL REFERENCES ticket_types(id) ON DELETE RESTRICT,
                             quantity         integer NOT NULL CHECK (quantity > 0),
                             unit_price_cents integer NOT NULL CHECK (unit_price_cents >= 0)
);

CREATE INDEX order_items_order_id_idx       ON order_items (order_id);
CREATE INDEX order_items_ticket_type_id_idx ON order_items (ticket_type_id);

-- -----------------------------------------------------------------------------
-- tickets
-- -----------------------------------------------------------------------------
CREATE TABLE tickets (
                         id             bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         order_item_id  bigint      NOT NULL REFERENCES order_items(id)  ON DELETE RESTRICT,
                         ticket_type_id bigint      NOT NULL REFERENCES ticket_types(id) ON DELETE RESTRICT,
                         owner_id       bigint      NOT NULL REFERENCES users(id)        ON DELETE RESTRICT,
                         code           text        NOT NULL UNIQUE,
                         status         text        NOT NULL DEFAULT 'valid'
                             CHECK (status IN ('valid', 'used', 'refunded')),
                         issued_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX tickets_order_item_id_idx  ON tickets (order_item_id);
CREATE INDEX tickets_ticket_type_id_idx ON tickets (ticket_type_id);
CREATE INDEX tickets_owner_id_idx       ON tickets (owner_id);
