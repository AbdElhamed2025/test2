# Shopify-like DB schema (PostgreSQL)

This folder contains a **Shopify-inspired relational schema** you can use to:

- build a commerce backend with Shopify-like primitives, or
- sync Shopify API data (REST/GraphQL) into a normalized database.

## Files

- `shopify_like_postgres.sql`: creates schema `commerce` and core tables.

## How to apply

Run against a PostgreSQL database (v12+ recommended):

```bash
psql "$DATABASE_URL" -f schema/shopify_like_postgres.sql
```

## Mapping to Shopify API resources (high level)

- **Shop**
  - `commerce.shops`
- **Customer / Address**
  - `commerce.customers`, `commerce.customer_addresses`
- **Product / Variant / Image**
  - `commerce.products`, `commerce.product_variants`, `commerce.product_images`, `commerce.product_options`
- **Collection**
  - `commerce.collections`, `commerce.collection_products`
- **Locations / Inventory**
  - `commerce.locations`, `commerce.inventory_items`, `commerce.inventory_levels`
- **Orders**
  - `commerce.orders`
  - Line items: `commerce.order_line_items`
  - Shipping lines: `commerce.order_shipping_lines`
  - Tax lines: `commerce.order_tax_lines`
  - Discounts: `commerce.order_discounts`
- **Fulfillment**
  - `commerce.fulfillments`, `commerce.fulfillment_line_items`
- **Payments / Transactions**
  - `commerce.order_transactions`
- **Refunds**
  - `commerce.refunds`, `commerce.refund_line_items`
- **Discount codes (optional management object)**
  - `commerce.discount_codes`
- **Metafields**
  - `commerce.metafield_definitions`, `commerce.metafields`

## Design notes

- **Multi-tenant**: almost every object is scoped by `shop_id`.
- **Shopify sync support**: each core table has optional `shopify_*_id` columns you can populate when importing.
- **Metafields**: stored with `(shop_id, owner_type, owner_id, namespace, key)` unique constraint; values can be stored in `value_text` or `value_json`.
- **Order addresses**: stored as JSON snapshots (`billing_address`, `shipping_address`) like Shopify order payloads.

