import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type SearchProductsParams = {
  search: string;
  pageSize?: number;
  currentPage?: number;
};

type SearchProductsQuery = {
  products: {
    total_count: number;
    page_info: { current_page: number; page_size: number; total_pages: number };
    items: Array<{
      __typename: string;
      id: number;
      sku: string;
      name: string;
      url_key?: string;
      small_image?: { url: string } | null;
      thumbnail?: { url: string } | null;
      price_range?: {
        minimum_price?: {
          final_price?: { value: number; currency: string };
          regular_price?: { value: number; currency: string };
        };
      };
    }>;
  };
};

export const searchProducts = async (
  context: MagentoIntegrationContext,
  params: SearchProductsParams
) => {
  const query = /* GraphQL */ `
    query SearchProducts(
      $search: String!
      $pageSize: Int!
      $currentPage: Int!
    ) {
      products(
        search: $search
        pageSize: $pageSize
        currentPage: $currentPage
      ) {
        total_count
        page_info {
          current_page
          page_size
          total_pages
        }
        items {
          __typename
          id
          sku
          name
          url_key
          small_image {
            url
          }
          thumbnail {
            url
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
        }
      }
    }
  `;

  return graphqlRequest<SearchProductsQuery>(context.client, query, {
    search: params.search,
    pageSize: params.pageSize ?? 24,
    currentPage: params.currentPage ?? 1,
  });
};
