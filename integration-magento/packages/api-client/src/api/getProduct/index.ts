import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type GetProductParams = {
  sku: string;
};

type GetProductQuery = {
  products: {
    items: Array<{
      __typename: string;
      id: number;
      sku: string;
      name: string;
      url_key?: string;
      description?: { html?: string } | null;
      short_description?: { html?: string } | null;
      stock_status?: string;
      thumbnail?: { url: string } | null;
      small_image?: { url: string } | null;
      media_gallery?: Array<{ url: string; label?: string | null }> | null;
      price_range?: {
        minimum_price?: {
          regular_price?: { value: number; currency: string };
          final_price?: { value: number; currency: string };
        };
      };
      configurable_options?: Array<{
        attribute_code: string;
        label: string;
        values: Array<{
          value_index: number;
          label?: string | null;
        }>;
      }>;
      variants?: Array<{
        product: {
          sku: string;
          stock_status?: string;
          thumbnail?: { url: string } | null;
        };
        attributes?: Array<{ code: string; value_index: number }>;
      }>;
    }>;
  };
};

export const getProduct = async (
  context: MagentoIntegrationContext,
  params: GetProductParams
) => {
  const query = /* GraphQL */ `
    query GetProduct($sku: String!) {
      products(filter: { sku: { eq: $sku } }) {
        items {
          __typename
          id
          sku
          name
          url_key
          stock_status
          description {
            html
          }
          short_description {
            html
          }
          thumbnail {
            url
          }
          small_image {
            url
          }
          media_gallery {
            url
            label
          }
          price_range {
            minimum_price {
              regular_price {
                value
                currency
              }
              final_price {
                value
                currency
              }
            }
          }
          ... on ConfigurableProduct {
            configurable_options {
              attribute_code
              label
              values {
                value_index
                label
              }
            }
            variants {
              attributes {
                code
                value_index
              }
              product {
                sku
                stock_status
                thumbnail {
                  url
                }
              }
            }
          }
        }
      }
    }
  `;

  return graphqlRequest<GetProductQuery>(context.client, query, {
    sku: params.sku,
  });
};
