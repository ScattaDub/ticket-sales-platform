# Ticket Sales Platform

A portfolio project: a ticket sales / event booking platform built to demonstrate
production-minded backend and database design. **Work in progress** — currently at
the database design stage.

> ⚠️ **Status:** Active development. The database layer is implemented and being
> validated; the API, services, and frontend are next on the roadmap. This repo is
> intentionally public so the design and code can be reviewed as the project grows.

## Stack (planned)

- **Backend:** NestJS (Node.js, TypeScript)
- **Database:** PostgreSQL
- **Frontend:** Next.js (React, TypeScript)
- **Tooling:** Claude Code as part of an AI-first development workflow

## What's done so far

- **Database schema design** — normalized relational model for the core domain
  (events, venues, ticket types, orders, seats/inventory, users).
- **Constraints & data integrity** — primary/foreign keys, unique constraints, and
  checks to keep the model consistent (e.g. no overselling, valid order states).
- **Test scenarios** — SQL queries and integrity scenarios run against a local
  PostgreSQL instance to validate the schema under realistic conditions.

## Domain model (overview)

> Adjust table names below to match your actual schema.

| Entity | Purpose |
|--------|---------|
| `users` | Customers and organizers |
| `events` | Sellable events with date/time and status |
| `venues` | Physical locations and capacity |
| `ticket_types` | Pricing tiers per event (e.g. standard, VIP) |
| `orders` | Purchase records and order lifecycle |
| `order_items` | Line items linking orders to ticket types |
| `tickets` / `inventory` | Issued tickets / available stock per type |

## Roadmap

- [x] Database schema design
- [x] Data-integrity constraints
- [x] SQL test scenarios on local PostgreSQL
- [ ] NestJS module structure and entities
- [ ] REST API (with validation and OpenAPI/Swagger docs)
- [ ] Authentication & authorization
- [ ] Orders / checkout flow with concurrency-safe inventory
- [ ] Test suite (unit + e2e)
- [ ] Next.js frontend
- [ ] Deployment (public demo link)

## Repository structure

```
.
├── db/
│   └── schema.sql        # Database schema (current focus)
└── README.md
```

## Running the schema locally

```bash
# Create a database and apply the schema
createdb ticket_sales
psql -d ticket_sales -f db/schema.sql
```

---

*This is a learning + portfolio project, developed openly. Feedback welcome.*