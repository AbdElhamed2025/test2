-- Shopify-like commerce schema (PostgreSQL)
-- Focus: core objects surfaced via Shopify API (products, inventory, customers, orders, fulfillments, payments/refunds, discounts, metafields)
-- Notes:
-- - This is not Shopify's internal schema; it's a practical normalized model for building a Shopify-like backend or syncing Shopify data.
-- - Most tables are multi-tenant via shop_id.
-- - "shopify_*" columns are optional but helpful if you sync from Shopify (REST/GraphQL ids).

BEGIN;

CREATE SCHEMA IF NOT EXISTS commerce;
SET search_path = commerce, public;

-- Extensions used by this schema.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";

-- ---------- Common enums ----------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'currency_code') THEN
    CREATE TYPE currency_code AS ENUM (
      'USD','CAD','AUD','NZD','GBP','EUR','JPY','CHF','SEK','NOK','DKK','PLN','CZK','HUF','RON','BGN','TRY','ILS','AED','SAR','QAR','KWD','OMR','INR','SGD','HKD','TWD','KRW','CNY','THB','MYR','IDR','PHP','VND','ZAR','BRL','MXN','CLP','COP','PEN','ARS'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_financial_status') THEN
    CREATE TYPE order_financial_status AS ENUM (
      'pending','authorized','partially_paid','paid','partially_refunded','refunded','voided'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_fulfillment_status') THEN
    CREATE TYPE order_fulfillment_status AS ENUM (
      'unfulfilled','partially_fulfilled','fulfilled','restocked'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_kind') THEN
    CREATE TYPE transaction_kind AS ENUM (
      'authorization','capture','sale','void','refund'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_status') THEN
    CREATE TYPE transaction_status AS ENUM (
      'pending','success','failure','error'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'discount_target_type') THEN
    CREATE TYPE discount_target_type AS ENUM ('order','shipping','line_item');
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'discount_value_type') THEN
    CREATE TYPE discount_value_type AS ENUM ('percentage','fixed_amount','free_shipping');
  END IF;
END$$;

-- ---------- Core tenants ----------
CREATE TABLE IF NOT EXISTS shops (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- Optional Shopify sync fields
  shopify_shop_id         bigint,
  shopify_domain          text,

  name                    text NOT NULL,
  primary_domain          text NOT NULL,
  email                   citext,
  currency                currency_code NOT NULL DEFAULT 'USD',
  timezone                text,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  deleted_at              timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS shops_primary_domain_uidx ON shops (lower(primary_domain));
CREATE UNIQUE INDEX IF NOT EXISTS shops_shopify_shop_id_uidx ON shops (shopify_shop_id) WHERE shopify_shop_id IS NOT NULL;

-- ---------- Customers ----------
CREATE TABLE IF NOT EXISTS customers (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id                 uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,

  -- Optional Shopify sync fields
  shopify_customer_id     bigint,

  email                   citext,
  phone                   text,
  first_name              text,
  last_name               text,
  state                   text NOT NULL DEFAULT 'enabled', -- enabled/disabled/invited/etc (keep flexible)
  accepts_marketing       boolean NOT NULL DEFAULT false,

  tags                    text[] NOT NULL DEFAULT '{}',
  note                    text,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  deleted_at              timestamptz,

  CONSTRAINT customers_email_unique_per_shop UNIQUE (shop_id, email),
  CONSTRAINT customers_shopify_customer_unique_per_shop UNIQUE (shop_id, shopify_customer_id)
);

CREATE INDEX IF NOT EXISTS customers_shop_id_idx ON customers (shop_id);
CREATE INDEX IF NOT EXISTS customers_email_idx ON customers (email);

CREATE TABLE IF NOT EXISTS customer_addresses (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id             uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  is_default              boolean NOT NULL DEFAULT false,

  name                    text,
  company                 text,
  phone                   text,

  address1                text,
  address2                text,
  city                    text,
  province                text,
  province_code           text,
  country                 text,
  country_code            text,
  zip                     text,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS customer_addresses_customer_id_idx ON customer_addresses(customer_id);

-- ---------- Products / Catalog ----------
CREATE TABLE IF NOT EXISTS products (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id                 uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,

  -- Optional Shopify sync fields
  shopify_product_id      bigint,

  title                   text NOT NULL,
  handle                  text NOT NULL,
  status                  text NOT NULL DEFAULT 'active', -- active/draft/archived (flexible)
  vendor                  text,
  product_type            text,

  description_html        text,

  tags                    text[] NOT NULL DEFAULT '{}',

  published_at            timestamptz,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  deleted_at              timestamptz,

  CONSTRAINT products_handle_unique_per_shop UNIQUE (shop_id, handle),
  CONSTRAINT products_shopify_product_unique_per_shop UNIQUE (shop_id, shopify_product_id)
);

CREATE INDEX IF NOT EXISTS products_shop_id_idx ON products (shop_id);
CREATE INDEX IF NOT EXISTS products_status_idx ON products (status);

CREATE TABLE IF NOT EXISTS product_options (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id              uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  position                int NOT NULL,
  name                    text NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS product_options_unique_per_product ON product_options(product_id, position);

CREATE TABLE IF NOT EXISTS product_variants (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id              uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,

  -- Optional Shopify sync fields
  shopify_variant_id      bigint,

  title                   text NOT NULL,
  sku                     text,
  barcode                 text,

  option1                 text,
  option2                 text,
  option3                 text,

  price_amount            numeric(12,2) NOT NULL DEFAULT 0,
  compare_at_amount       numeric(12,2),

  taxable                 boolean NOT NULL DEFAULT true,
  requires_shipping       boolean NOT NULL DEFAULT true,

  weight                  numeric(12,3),
  weight_unit             text, -- g/kg/lb/oz etc

  inventory_item_id       uuid, -- FK added after inventory_items defined
  position                int,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  deleted_at              timestamptz,

  CONSTRAINT variants_shopify_variant_unique_per_product UNIQUE (product_id, shopify_variant_id)
);

CREATE INDEX IF NOT EXISTS product_variants_product_id_idx ON product_variants(product_id);
CREATE INDEX IF NOT EXISTS product_variants_sku_idx ON product_variants(sku);

CREATE TABLE IF NOT EXISTS product_images (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id              uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,

  -- Optional Shopify sync fields
  shopify_image_id        bigint,

  position                int,
  alt                     text,
  src                     text NOT NULL,
  width                   int,
  height                  int,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT product_images_shopify_image_unique_per_product UNIQUE (product_id, shopify_image_id)
);

CREATE INDEX IF NOT EXISTS product_images_product_id_idx ON product_images(product_id);

-- Collections (manual or smart collections)
CREATE TABLE IF NOT EXISTS collections (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id                 uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,

  shopify_collection_id   bigint,

  title                   text NOT NULL,
  handle                  text NOT NULL,
  collection_type         text NOT NULL DEFAULT 'custom', -- custom/smart
  description_html        text,
  published_at            timestamptz,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  deleted_at              timestamptz,

  CONSTRAINT collections_handle_unique_per_shop UNIQUE (shop_id, handle),
  CONSTRAINT collections_shopify_collection_unique_per_shop UNIQUE (shop_id, shopify_collection_id)
);

CREATE TABLE IF NOT EXISTS collection_products (
  collection_id           uuid NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  product_id              uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  position                int,
  created_at              timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (collection_id, product_id)
);

-- ---------- Inventory ----------
CREATE TABLE IF NOT EXISTS locations (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id                 uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,

  shopify_location_id     bigint,

  name                    text NOT NULL,
  is_active               boolean NOT NULL DEFAULT true,

  address1                text,
  address2                text,
  city                    text,
  province                text,
  province_code           text,
  country                 text,
  country_code            text,
  zip                     text,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT locations_shopify_location_unique_per_shop UNIQUE (shop_id, shopify_location_id)
);

CREATE INDEX IF NOT EXISTS locations_shop_id_idx ON locations(shop_id);

CREATE TABLE IF NOT EXISTS inventory_items (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id                 uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,

  shopify_inventory_item_id bigint,

  sku                     text,
  tracked                 boolean NOT NULL DEFAULT true,
  requires_shipping       boolean NOT NULL DEFAULT true,
  cost_amount             numeric(12,2),
  country_code_of_origin  text,
  hs_code                 text,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT inventory_items_shopify_inventory_item_unique_per_shop UNIQUE (shop_id, shopify_inventory_item_id)
);

CREATE INDEX IF NOT EXISTS inventory_items_shop_id_idx ON inventory_items(shop_id);
CREATE INDEX IF NOT EXISTS inventory_items_sku_idx ON inventory_items(sku);

ALTER TABLE product_variants
  ADD CONSTRAINT product_variants_inventory_item_fk
  FOREIGN KEY (inventory_item_id) REFERENCES inventory_items(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS inventory_levels (
  inventory_item_id       uuid NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  location_id             uuid NOT NULL REFERENCES locations(id) ON DELETE CASCADE,

  -- Shopify-ish counters (you can derive some, but explicit counters simplify APIs)
  available               int NOT NULL DEFAULT 0,
  committed               int NOT NULL DEFAULT 0,
  reserved                int NOT NULL DEFAULT 0,

  updated_at              timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (inventory_item_id, location_id),

  CONSTRAINT inventory_levels_nonnegative CHECK (available >= 0 AND committed >= 0 AND reserved >= 0)
);

CREATE INDEX IF NOT EXISTS inventory_levels_location_idx ON inventory_levels(location_id);

-- ---------- Orders ----------
CREATE TABLE IF NOT EXISTS orders (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id                 uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  customer_id             uuid REFERENCES customers(id) ON DELETE SET NULL,

  -- Optional Shopify sync fields
  shopify_order_id        bigint,

  order_number            bigint NOT NULL, -- per-shop order sequence
  name                    text,           -- e.g. "#1001"

  email                   citext,
  phone                   text,
  currency                currency_code NOT NULL DEFAULT 'USD',

  financial_status        order_financial_status NOT NULL DEFAULT 'pending',
  fulfillment_status      order_fulfillment_status NOT NULL DEFAULT 'unfulfilled',

  subtotal_amount         numeric(12,2) NOT NULL DEFAULT 0,
  shipping_amount         numeric(12,2) NOT NULL DEFAULT 0,
  tax_amount              numeric(12,2) NOT NULL DEFAULT 0,
  discount_amount         numeric(12,2) NOT NULL DEFAULT 0,
  total_amount            numeric(12,2) NOT NULL DEFAULT 0,

  processed_at            timestamptz,
  cancelled_at            timestamptz,
  cancel_reason           text,

  -- snapshot addresses (Shopify stores address snapshots on the order)
  shipping_address        jsonb,
  billing_address         jsonb,

  tags                    text[] NOT NULL DEFAULT '{}',
  note                    text,
  note_attributes         jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT orders_order_number_unique_per_shop UNIQUE (shop_id, order_number),
  CONSTRAINT orders_shopify_order_unique_per_shop UNIQUE (shop_id, shopify_order_id),
  CONSTRAINT orders_amounts_nonnegative CHECK (
    subtotal_amount >= 0 AND shipping_amount >= 0 AND tax_amount >= 0 AND discount_amount >= 0 AND total_amount >= 0
  )
);

CREATE INDEX IF NOT EXISTS orders_shop_id_idx ON orders(shop_id);
CREATE INDEX IF NOT EXISTS orders_customer_id_idx ON orders(customer_id);
CREATE INDEX IF NOT EXISTS orders_created_at_idx ON orders(created_at);
CREATE INDEX IF NOT EXISTS orders_financial_status_idx ON orders(financial_status);
CREATE INDEX IF NOT EXISTS orders_fulfillment_status_idx ON orders(fulfillment_status);

CREATE TABLE IF NOT EXISTS order_line_items (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id                uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,

  -- Optional Shopify sync fields
  shopify_line_item_id    bigint,

  product_id              uuid REFERENCES products(id) ON DELETE SET NULL,
  variant_id              uuid REFERENCES product_variants(id) ON DELETE SET NULL,
  inventory_item_id       uuid REFERENCES inventory_items(id) ON DELETE SET NULL,

  title                   text NOT NULL,
  sku                     text,
  vendor                  text,

  quantity                int NOT NULL DEFAULT 1,
  price_amount            numeric(12,2) NOT NULL DEFAULT 0,
  compare_at_amount       numeric(12,2),

  taxable                 boolean NOT NULL DEFAULT true,
  requires_shipping       boolean NOT NULL DEFAULT true,
  fulfillment_service     text,

  properties              jsonb NOT NULL DEFAULT '[]'::jsonb, -- Shopify line item properties array

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT order_line_items_qty_positive CHECK (quantity > 0),
  CONSTRAINT order_line_items_shopify_line_item_unique_per_order UNIQUE (order_id, shopify_line_item_id)
);

CREATE INDEX IF NOT EXISTS order_line_items_order_id_idx ON order_line_items(order_id);
CREATE INDEX IF NOT EXISTS order_line_items_variant_id_idx ON order_line_items(variant_id);

-- Shipping lines (shipping rates selected on an order)
CREATE TABLE IF NOT EXISTS order_shipping_lines (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id                uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  title                   text NOT NULL,
  carrier_identifier      text,
  code                    text,
  price_amount            numeric(12,2) NOT NULL DEFAULT 0,
  tax_amount              numeric(12,2) NOT NULL DEFAULT 0,
  created_at              timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS order_shipping_lines_order_id_idx ON order_shipping_lines(order_id);

-- Taxes captured per line (optional; can also be represented by tax_amount totals)
CREATE TABLE IF NOT EXISTS order_tax_lines (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id                uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  title                   text NOT NULL,
  rate                    numeric(8,6) NOT NULL DEFAULT 0,
  price_amount            numeric(12,2) NOT NULL DEFAULT 0,
  created_at              timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT order_tax_lines_rate_range CHECK (rate >= 0 AND rate <= 1)
);

CREATE INDEX IF NOT EXISTS order_tax_lines_order_id_idx ON order_tax_lines(order_id);

-- Discounts applied at order-level (codes, automatic discounts, etc.)
CREATE TABLE IF NOT EXISTS order_discounts (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id                uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  code                    text,
  title                   text,
  target_type             discount_target_type NOT NULL DEFAULT 'order',
  value_type              discount_value_type NOT NULL DEFAULT 'fixed_amount',
  value_amount            numeric(12,2),
  value_percentage        numeric(8,4),
  allocation_method       text, -- across/each (flexible)
  created_at              timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT order_discounts_value_check CHECK (
    (value_type = 'percentage' AND value_percentage IS NOT NULL AND value_percentage >= 0 AND value_percentage <= 100)
    OR (value_type = 'fixed_amount' AND value_amount IS NOT NULL AND value_amount >= 0)
    OR (value_type = 'free_shipping')
  )
);

CREATE INDEX IF NOT EXISTS order_discounts_order_id_idx ON order_discounts(order_id);

-- ---------- Fulfillment ----------
CREATE TABLE IF NOT EXISTS fulfillments (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id                uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  location_id             uuid REFERENCES locations(id) ON DELETE SET NULL,

  -- Optional Shopify sync fields
  shopify_fulfillment_id  bigint,

  status                  text NOT NULL DEFAULT 'success', -- pending/success/cancelled/error (flexible)
  tracking_company        text,
  tracking_number         text,
  tracking_url            text,

  shipped_at              timestamptz,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT fulfillments_shopify_fulfillment_unique_per_order UNIQUE (order_id, shopify_fulfillment_id)
);

CREATE INDEX IF NOT EXISTS fulfillments_order_id_idx ON fulfillments(order_id);
CREATE INDEX IF NOT EXISTS fulfillments_location_id_idx ON fulfillments(location_id);

CREATE TABLE IF NOT EXISTS fulfillment_line_items (
  fulfillment_id          uuid NOT NULL REFERENCES fulfillments(id) ON DELETE CASCADE,
  order_line_item_id      uuid NOT NULL REFERENCES order_line_items(id) ON DELETE CASCADE,
  quantity                int NOT NULL DEFAULT 1,
  PRIMARY KEY (fulfillment_id, order_line_item_id),
  CONSTRAINT fulfillment_line_items_qty_positive CHECK (quantity > 0)
);

-- ---------- Payments / Transactions ----------
CREATE TABLE IF NOT EXISTS order_transactions (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id                uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,

  -- Optional Shopify sync fields
  shopify_transaction_id  bigint,

  kind                    transaction_kind NOT NULL,
  status                  transaction_status NOT NULL DEFAULT 'pending',
  gateway                 text,

  amount                  numeric(12,2) NOT NULL DEFAULT 0,
  currency                currency_code NOT NULL DEFAULT 'USD',

  authorization           text,
  processed_at            timestamptz,
  message                 text,

  raw                     jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT order_transactions_amount_nonnegative CHECK (amount >= 0),
  CONSTRAINT order_transactions_shopify_transaction_unique_per_order UNIQUE (order_id, shopify_transaction_id)
);

CREATE INDEX IF NOT EXISTS order_transactions_order_id_idx ON order_transactions(order_id);
CREATE INDEX IF NOT EXISTS order_transactions_status_idx ON order_transactions(status);

-- ---------- Refunds ----------
CREATE TABLE IF NOT EXISTS refunds (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id                uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,

  shopify_refund_id       bigint,

  note                    text,
  total_refunded_amount   numeric(12,2) NOT NULL DEFAULT 0,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT refunds_total_nonnegative CHECK (total_refunded_amount >= 0),
  CONSTRAINT refunds_shopify_refund_unique_per_order UNIQUE (order_id, shopify_refund_id)
);

CREATE INDEX IF NOT EXISTS refunds_order_id_idx ON refunds(order_id);

CREATE TABLE IF NOT EXISTS refund_line_items (
  refund_id               uuid NOT NULL REFERENCES refunds(id) ON DELETE CASCADE,
  order_line_item_id      uuid NOT NULL REFERENCES order_line_items(id) ON DELETE CASCADE,
  quantity                int NOT NULL DEFAULT 1,
  subtotal_amount         numeric(12,2) NOT NULL DEFAULT 0,
  tax_amount              numeric(12,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (refund_id, order_line_item_id),
  CONSTRAINT refund_line_items_qty_positive CHECK (quantity > 0),
  CONSTRAINT refund_line_items_amounts_nonnegative CHECK (subtotal_amount >= 0 AND tax_amount >= 0)
);

-- ---------- Discount objects (optional; for managing codes/rules) ----------
CREATE TABLE IF NOT EXISTS discount_codes (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id                 uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,

  shopify_discount_id     bigint,

  code                    text NOT NULL,
  value_type              discount_value_type NOT NULL,
  value_amount            numeric(12,2),
  value_percentage        numeric(8,4),
  target_type             discount_target_type NOT NULL DEFAULT 'order',

  starts_at               timestamptz,
  ends_at                 timestamptz,
  usage_limit             int,
  usage_count             int NOT NULL DEFAULT 0,
  is_active               boolean NOT NULL DEFAULT true,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT discount_codes_value_check CHECK (
    (value_type = 'percentage' AND value_percentage IS NOT NULL AND value_percentage >= 0 AND value_percentage <= 100)
    OR (value_type = 'fixed_amount' AND value_amount IS NOT NULL AND value_amount >= 0)
    OR (value_type = 'free_shipping')
  )
);

CREATE INDEX IF NOT EXISTS discount_codes_shop_id_idx ON discount_codes(shop_id);
CREATE UNIQUE INDEX IF NOT EXISTS discount_codes_code_uidx ON discount_codes (shop_id, lower(code));

-- ---------- Metafields (Shopify-style extensibility) ----------
-- Owner types commonly used in Shopify: shop, product, variant, customer, order, collection, location, inventory_item
CREATE TABLE IF NOT EXISTS metafield_definitions (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id                 uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,

  owner_type              text NOT NULL,
  namespace               text NOT NULL,
  key                     text NOT NULL,
  value_type              text NOT NULL DEFAULT 'single_line_text_field',
  description             text,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT metafield_definitions_unique_per_shop UNIQUE (shop_id, owner_type, namespace, key)
);

CREATE TABLE IF NOT EXISTS metafields (
  id                      uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id                 uuid NOT NULL REFERENCES shops(id) ON DELETE CASCADE,

  owner_type              text NOT NULL,
  owner_id                uuid NOT NULL,

  namespace               text NOT NULL,
  key                     text NOT NULL,

  value_type              text NOT NULL DEFAULT 'single_line_text_field',
  value_text              text,
  value_json              jsonb,

  description             text,

  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT metafields_unique_per_owner UNIQUE (shop_id, owner_type, owner_id, namespace, key),
  CONSTRAINT metafields_value_present CHECK (value_text IS NOT NULL OR value_json IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS metafields_owner_lookup_idx ON metafields(shop_id, owner_type, owner_id);

-- ---------- Helpful updated_at trigger ----------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT quote_ident(n.nspname) AS schemaname, quote_ident(c.relname) AS tablename
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid
    WHERE n.nspname = 'commerce'
      AND c.relkind = 'r'
      AND a.attname = 'updated_at'
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at ON %s.%s;', r.schemaname, r.tablename);
    EXECUTE format('CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON %s.%s FOR EACH ROW EXECUTE FUNCTION set_updated_at();', r.schemaname, r.tablename);
  END LOOP;
END$$;

COMMIT;

