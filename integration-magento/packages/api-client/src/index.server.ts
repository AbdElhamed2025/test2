import axios from "axios";
import { apiClientFactory } from "@vue-storefront/middleware";
import { MiddlewareConfig } from "./index";
import * as apiEndpoints from "./api";

/**
 * In here you should create the client you'll use to communicate with the backend.
 * Axios is just an example.
 */
const buildClient = (settings: MiddlewareConfig) => {
  const axiosInstance = axios.create({
    baseURL: settings.graphqlEndpoint,
    headers: {
      "Content-Type": "application/json",
      ...(settings.storeCode ? { Store: settings.storeCode } : {}),
    },
    timeout: 30_000,
  });
  return axiosInstance;
};

const onCreate = (settings: MiddlewareConfig) => {
  const client = buildClient(settings);

  return {
    config: settings,
    client,
  };
};

const { createApiClient } = apiClientFactory<any, any>({
  onCreate,
  api: apiEndpoints,
});

export { createApiClient };
