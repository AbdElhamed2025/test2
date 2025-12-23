/**
 * Settings to be provided in the `middleware.config.js` file.
 */
export interface MiddlewareConfig {
  /**
   * Magento GraphQL endpoint.
   * Example: https://www.ahmedelsallab.com/graphql
   */
  graphqlEndpoint: string;

  /**
   * Optional Magento store view code (sent as the `Store` header).
   * Example: "default" or a specific store view code.
   */
  storeCode?: string;
}
