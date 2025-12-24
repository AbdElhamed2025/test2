FROM node:18-bullseye-slim AS build

WORKDIR /app

# Yarn classic (this repo uses Yarn v1 workspaces)
RUN npm i -g yarn@1.22.22

# Copy manifests first for better layer caching
COPY integration-magento/package.json integration-magento/yarn.lock integration-magento/turbo.json integration-magento/vsf.mjs ./integration-magento/
COPY integration-magento/packages/api-client/package.json ./integration-magento/packages/api-client/package.json
COPY integration-magento/playground/middleware/package.json ./integration-magento/playground/middleware/package.json
COPY integration-magento/playground/app/package.json ./integration-magento/playground/app/package.json

WORKDIR /app/integration-magento
RUN yarn install --frozen-lockfile

# Copy the rest of the source
COPY integration-magento/ /app/integration-magento/

# Build integration API client (rollup), compile middleware TS, build Nuxt app
RUN yarn workspace @vue-storefront/integration-magento-api build \
  && npx tsc -p playground/middleware/tsconfig.json \
  && yarn workspace magento-headless-storefront build

FROM node:18-bullseye-slim AS runtime

WORKDIR /app/integration-magento
RUN npm i -g yarn@1.22.22

COPY --from=build /app/integration-magento /app/integration-magento

ENV API_PORT=4000
ENV NUXT_PUBLIC_MIDDLEWARE_URL=http://localhost:4000/magento
ENV MAGENTO_GRAPHQL_ENDPOINT=https://www.ahmedelsallab.com/graphql
ENV MAGENTO_STORE_CODE=ar

EXPOSE 3000 4000

# Run middleware (background) + Nuxt server (foreground)
CMD ["bash", "-lc", "node playground/middleware/lib/src/index.js & node playground/app/.output/server/index.mjs"]

