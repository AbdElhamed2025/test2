import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

type StoreConfigQuery = {
  storeConfig: {
    store_code?: string;
    store_name?: string;
    root_category_id?: number;
    base_currency_code?: string;
    default_display_currency_code?: string;
    locale?: string;
    timezone?: string;
    secure_base_media_url?: string;
    secure_base_url?: string;
  };
};

export const getStoreConfig = async (context: MagentoIntegrationContext) => {
  const query = /* GraphQL */ `
    query GetStoreConfig {
      storeConfig {
        store_code
        store_name
        root_category_id
        base_currency_code
        default_display_currency_code
        locale
        timezone
        secure_base_media_url
        secure_base_url
      }
    }
  `;

  return graphqlRequest<StoreConfigQuery>(context.client, query);
};
