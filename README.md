# Ticket Sales Platform

A portfolio project: a ticket sales / event booking platform built to demonstrate
production-minded backend and database design. **Work in progress** — the database
layer is complete and the REST API is being built resource by resource.

> ⚠️ **Status:** Active development. Schema, seed data and three API resources
> (`venues`, `categories`, `events`) are done; error handling, auth and the
> ordering flow are next. The repo is intentionally public so the design can be
> reviewed as it grows.

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

Three resources — `/venues`, `/categories`, `/events` — all follow the same shape:

| Method | Route | Notes |
|---|---|---|
| `GET` | `/{resource}` | list |
| `GET` | `/{resource}/:id` | `404` when missing, `400` for a non-numeric id |
| `POST` | `/{resource}` | `201` |
| `PATCH` | `/{resource}/:id` | partial update; an empty body is a `400` |
| `DELETE` | `/{resource}/:id` | `204`, or `404` when missing |

A category's `slug` is generated once on creation and is **not** recalculated when
the category is renamed: it is part of the public URL, which makes it an
identifier rather than a display name.

### `/events`

The first resource complex enough to need more than a straight column mapping.

- **Server-owned fields are not writable.** `status` cannot be set at creation —
  every event starts as a `draft` — and `published_at` is rejected outright,
  because a client should not get to decide when something was published.
- **`published_at` is stamped on the first transition to `published` only.**
  Publishing again, or unpublishing and publishing once more, leaves the original
  date alone. It is written as `published_at = COALESCE(published_at, now())`:
  the right-hand side of an `UPDATE` reads the old row, so there is no window
  between reading the value and writing it.
- **`PATCH` builds its `UPDATE` from the fields actually sent**, rather than
  `COALESCE($n, column)` for every column. That is what makes
  `{"description": null}` mean *clear this field* instead of *leave it as it was* —
  the two are indistinguishable once a missing field and an explicit `null` are
  collapsed into the same parameter.
- **Timestamps must carry a UTC offset.** `2026-12-01T19:00:00` is rejected;
  `2026-12-01T19:00:00Z` is accepted. An instant without an offset is ambiguous,
  and guessing the server's zone is how events end up three hours off.
- **The time window is validated as a pair.** `endsAt` must be strictly later
  than `startsAt`, and sending only one of the two is a `400`: shifting the end
  of an event without knowing its start is not a partial update, it is a
  half-formed one.

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
- [x] REST API for `events` (foreign keys, status lifecycle, date ranges)
- [ ] Postgres error mapping (constraint violations → `409` instead of `500`)
      and field-keyed validation errors
- [ ] OpenAPI/Swagger documentation
- [ ] Authentication & authorization
- [ ] Orders / checkout flow with concurrency-safe inventory
- [ ] Test suite (unit + e2e)
- [ ] Next.js frontend
- [ ] Deployment (public demo link)

---

*This is a learning + portfolio project, developed openly. Feedback welcome.*
