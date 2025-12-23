# Magento headless storefront (Vue Storefront middleware + GraphQL)

This repo contains a **Vue Storefront integration middleware** (built from [`vuestorefront/integration-boilerplate`](https://github.com/vuestorefront/integration-boilerplate)) connected to the Magento store at `https://www.ahmedelsallab.com/` via **GraphQL**, plus a **Nuxt 3 storefront** consuming that middleware.

## Run locally

```bash
cd /workspace/integration-magento
cp .env.example .env
yarn
yarn dev
```

- **Storefront**: `http://localhost:3000`
- **Middleware**: `http://localhost:4000`

## What’s included

- **Catalog**: home, category pages, product page, search
- **Cart**: create cart, add/update/remove items
- **Checkout**: guest email + shipping address + shipping method + payment method + place order (via Magento GraphQL)