# Ticket Sales Platform

A portfolio project: a ticket sales / event booking platform built to demonstrate
production-minded backend and database design. **Work in progress** — the database
layer is complete and the REST API is being built resource by resource.

> ⚠️ **Status:** Active development. Schema, seed data and two API resources
> (`venues`, `categories`) are done; `events`, auth and the ordering flow are next.
> The repo is intentionally public so the design can be reviewed as it grows.

## Stack

- **Backend:** NestJS (Node.js, TypeScript with `strict`)
- **Database:** PostgreSQL — schema written by hand, queried with raw SQL through
  the `pg` driver. No ORM yet: Prisma is deliberately deferred so the trade-off
  against hand-written SQL is felt rather than assumed.
- **Validation:** zod for environment variables (fails fast at boot),
  class-validator for request bodies
- **Frontend:** Next.js (planned)
- **Tooling:** Claude Code as part of an AI-first development workflow

## Domain model

Nine tables covering the core domain:

| Table | Purpose |
|---|---|
| `users` | Customers, organizers and admins (native `user_role` enum) |
| `venues` | Physical locations and capacity |
| `categories` | Event categories, addressed publicly by `slug` |
| `events` | Sellable events with a time window and lifecycle status |
| `event_categories` | M:N between events and categories |
| `ticket_types` | Pricing tiers per event, with inventory counters |
| `orders` | Purchase records and order lifecycle |
| `order_items` | Line items linking orders to ticket types |
| `tickets` | Individual issued tickets with public, unguessable codes |

### Design decisions worth calling out

- **Money is integer cents** (`price_cents`, `total_cents`) — never floating point.
- **All timestamps are `timestamptz`**, never bare `timestamp`.
- **Statuses are `text` + `CHECK`**, not native enums, so the allowed set can
  evolve without a migration on the type. The one exception is `users.role`,
  where the set of values is genuinely frozen.
- **Email uniqueness is a functional index** on `lower(email)`, so `Foo@x.com`
  and `foo@x.com` are the same person without needing the `citext` extension.
- **Ticket codes are random**, not sequential — a public identifier should not be
  guessable from its neighbours.
- **Foreign keys pointing at `events` use `ON DELETE RESTRICT`**: an event with
  sold tickets must not disappear quietly.
- **Indexes on foreign keys are created explicitly** — Postgres does not add them
  automatically, unlike primary keys.
- **`ticket_types.quantity_sold` vs `quantity_total` is the project's hot spot.**
  Selling the last ticket under concurrent load is the central problem: a
  `CHECK (quantity_sold <= quantity_total)` is the last line of defence, but the
  real fix is row-level locking inside a transaction, covered by a race-condition
  test later on.

## API

Implemented so far. Every endpoint validates its input; unknown body properties
are rejected rather than silently dropped.

| Method | Route | Notes |
|---|---|---|
| `GET` | `/venues`, `/categories` | list |
| `GET` | `/venues/:id`, `/categories/:id` | `404` when missing |
| `POST` | `/venues`, `/categories` | `201`; category `slug` is generated from `name` |
| `PATCH` | `/venues/:id`, `/categories/:id` | partial update; an empty body is a `400` |
| `DELETE` | `/venues/:id`, `/categories/:id` | `204`, or `404` when missing |

A category's `slug` is generated once on creation and is **not** recalculated when
the category is renamed: it is part of the public URL, which makes it an
identifier rather than a display name.

## Repository structure

```
.
├── db/
│   ├── schema.sql        # Tables, types, indexes
│   ├── seed.sql          # Sample data (idempotent)
│   ├── seed-bulk.sql     # +10k tickets for the streaming exercises (idempotent)
│   └── queries.sql       # Example analytical queries
├── experiments/          # Standalone scripts: streams, CSV export, PDF generation
└── server/               # NestJS application
```

## Running locally

Requires Node.js 20+ and a running PostgreSQL 14+.

```bash
# 1. Database
createdb ticket_sales
psql -d ticket_sales -f db/schema.sql
psql -d ticket_sales -f db/seed.sql
psql -d ticket_sales -f db/seed-bulk.sql   # optional: bulk data for stream demos

# 2. API
cd server
cp .env.example .env                        # then fill in the connection details
npm install
npm run start:dev
```

The application validates its environment on boot and refuses to start if a
variable is missing or malformed, so a typo in `.env` surfaces immediately rather
than on the first query.

```bash
curl localhost:3000/venues
```

## Roadmap

- [x] Database schema design
- [x] Data-integrity constraints
- [x] SQL test scenarios on local PostgreSQL
- [x] NestJS module structure, configuration and connection pooling
- [x] REST API for `venues` and `categories`, with request validation
- [ ] REST API for `events` (foreign keys, status lifecycle, date ranges)
- [ ] Postgres error mapping (constraint violations → `409` instead of `500`)
- [ ] OpenAPI/Swagger documentation
- [ ] Authentication & authorization
- [ ] Orders / checkout flow with concurrency-safe inventory
- [ ] Test suite (unit + e2e)
- [ ] Next.js frontend
- [ ] Deployment (public demo link)

---

*This is a learning + portfolio project, developed openly. Feedback welcome.*
