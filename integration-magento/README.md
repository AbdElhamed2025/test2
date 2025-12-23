# Magento headless storefront (Alokai / Vue Storefront integration-boilerplate)

This project is based on [`vuestorefront/integration-boilerplate`](https://github.com/vuestorefront/integration-boilerplate) and connects to the Magento store at `https://www.ahmedelsallab.com/` using **Magento GraphQL** (`/graphql`).

It contains:

- `packages/api-client` (`@vue-storefront/integration-magento-api`): Magento GraphQL integration exposed through Alokai middleware endpoints
- `playground/middleware`: Alokai middleware server (Node) exposing the integration endpoints
- `playground/app`: Nuxt 3 storefront consuming the middleware

## Run locally

```bash
cp .env.example .env
yarn
yarn dev
```

- **Storefront**: `http://localhost:3000`
- **Middleware**: `http://localhost:4000`

## Environment variables

- `MAGENTO_GRAPHQL_ENDPOINT`: defaults to `https://www.ahmedelsallab.com/graphql`
- `MAGENTO_STORE_CODE` (optional): sent as the `Store` header
- `NUXT_PUBLIC_MIDDLEWARE_URL`: defaults to `http://localhost:4000/magento`

## Middleware endpoints (used by the storefront)

Base URL: `http://localhost:4000/magento`

- Requests are `POST` with a JSON body containing the method parameters (no wrapper object).
  Example: `POST /getProduct` with body `{ "sku": "PRPRO002068" }`.

- `POST /getStoreConfig`
- `POST /getCategoryTree`
- `POST /getCategory`
- `POST /searchProducts`
- `POST /getProduct`
- `POST /createCart`
- `POST /getCart`
- `POST /addToCart`
- `POST /removeFromCart`
- `POST /updateCartItems`
- `POST /setGuestEmailOnCart`
- `POST /setShippingAddressOnCart`
- `POST /setShippingMethodOnCart`
- `POST /setPaymentMethodOnCart`
- `POST /placeOrder`
- `packages/api-client` - The service the middleware uses. It contains an `exampleEndpoint` that can be used as an example for the other API endpoints,
- `packages/sdk`- Think of the SDK Connector as a communication layer between the storefront and the middleware. It contains an `exampleMethod` with example documentation, unit & integration tests, that can be used as an example for the rest SDK connector methods.
- `docs` - VuePress documentation with configured API extractor, to create an API Reference based on the `api-client` and `sdk` methods & interfaces.

## Getting started

```bash
yarn
```

5. Build the packages,

```bash
yarn build
```

6. Test the packages,

```bash
yarn test
```

7.  That's it. Now you can start the developing your contribution,
8.  Enjoy.
