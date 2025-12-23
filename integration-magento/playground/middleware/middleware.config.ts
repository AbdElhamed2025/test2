export const integrations = {
  magento: {
    location: "@vue-storefront/integration-magento-api/server",
    configuration: {
      graphqlEndpoint:
        process.env.MAGENTO_GRAPHQL_ENDPOINT ??
        "https://www.ahmedelsallab.com/graphql",
      storeCode: process.env.MAGENTO_STORE_CODE ?? "ar",
    },
  },
};
