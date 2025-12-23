import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type GetCategoryParams = {
  categoryId: number;
  pageSize?: number;
  currentPage?: number;
};

type CategoryQuery = {
  category: {
    id: number;
    name: string;
    description?: string;
    url_path?: string;
    image?: string;
    products: {
      total_count: number;
      page_info: {
        current_page: number;
        page_size: number;
        total_pages: number;
      };
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
  } | null;
};

export const getCategory = async (
  context: MagentoIntegrationContext,
  params: GetCategoryParams
) => {
  const query = /* GraphQL */ `
    query GetCategory($id: Int!, $pageSize: Int!, $currentPage: Int!) {
      category(id: $id) {
        id
        name
        description
        url_path
        image
        products(pageSize: $pageSize, currentPage: $currentPage) {
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
    }
  `;

  return graphqlRequest<CategoryQuery>(context.client, query, {
    id: params.categoryId,
    pageSize: params.pageSize ?? 24,
    currentPage: params.currentPage ?? 1,
  });
};
