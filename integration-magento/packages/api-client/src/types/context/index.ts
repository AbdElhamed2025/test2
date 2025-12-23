import { AxiosInstance } from "axios";
import { IntegrationContext } from "@vue-storefront/middleware";
import { MiddlewareConfig, Endpoints } from "../index";

/**
 * Runtime integration context, which includes API client instance, settings, and endpoints that will be passed via middleware server.
 * This interface name is starting with `Magento`, reflecting the integration name.
 * */
export type MagentoIntegrationContext = IntegrationContext<
  AxiosInstance,
  MiddlewareConfig,
  Endpoints
>;

/**
 * Global context of the application which includes runtime integration context.
 * */
export interface Context {
  $magento: MagentoIntegrationContext;
}
