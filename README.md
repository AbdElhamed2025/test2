# Shopify-like DB schema (PostgreSQL)

This repo contains a **Shopify-inspired database schema** based on Shopify’s public API concepts (Products, Variants, Inventory, Customers, Orders, Fulfillments, Transactions, Refunds, Discounts, Metafields).

- Schema DDL: `schema/shopify_like_postgres.sql`
- Notes / mapping: `schema/README.md`

To apply:

```bash
psql "$DATABASE_URL" -f schema/shopify_like_postgres.sql
```