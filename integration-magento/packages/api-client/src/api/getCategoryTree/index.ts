import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type GetCategoryTreeParams = {
  /** Magento root category id (often 2). */
  rootId?: number;
  /**
   * Fallback seed search used when the root category is not queryable
   * (some Magento instances hide root categories from GraphQL).
   */
  seedSearch?: string;
  /** How many products to scan for categories in fallback mode. */
  seedPageSize?: number;
};

type CategoryTreeQuery = {
  category: {
    id: number;
    name: string;
    url_path?: string;
    include_in_menu?: number;
    children?: Array<{
      id: number;
      name: string;
      url_path?: string;
      include_in_menu?: number;
      children_count?: string;
      children?: Array<{
        id: number;
        name: string;
        url_path?: string;
        include_in_menu?: number;
      }>;
    }>;
  } | null;
};

export const getCategoryTree = async (
  context: MagentoIntegrationContext,
  params: GetCategoryTreeParams = {}
) => {
  const rootId = params.rootId ?? 2;
  const seedSearch = params.seedSearch ?? "PRPRO";
  const seedPageSize = params.seedPageSize ?? 50;

  const query = /* GraphQL */ `
    query CategoryTree($id: Int!) {
      category(id: $id) {
        id
        name
        url_path
        include_in_menu
        children {
          id
          name
          url_path
          include_in_menu
          children_count
          children {
            id
            name
            url_path
            include_in_menu
          }
        }
      }
    }
  `;

  try {
    return await graphqlRequest<CategoryTreeQuery>(context.client, query, {
      id: rootId,
    });
  } catch {
    /**
     * Fallback: build a "menu" from categories observed on products.
     * This keeps the storefront usable even when root categories are not exposed.
     */
    const seedQuery = /* GraphQL */ `
      query CategorySeed($search: String!, $pageSize: Int!) {
        products(search: $search, pageSize: $pageSize, currentPage: 1) {
          items {
            categories {
              id
              name
              url_path
              include_in_menu
            }
          }
        }
      }
    `;

    const seed = await graphqlRequest<{
      products: {
        items: Array<{
          categories?: Array<{
            id: number;
            name: string;
            url_path?: string;
            include_in_menu?: number;
          }> | null;
        }>;
      };
    }>(context.client, seedQuery, {
      search: seedSearch,
      pageSize: seedPageSize,
    });

    const byId = new Map<number, any>();
    for (const item of seed.products.items) {
      for (const c of item.categories ?? []) {
        if (c?.id && !byId.has(c.id)) {
          byId.set(c.id, {
            id: c.id,
            name: c.name,
            url_path: c.url_path,
            include_in_menu: c.include_in_menu ?? 1,
            children_count: "0",
            children: [],
          });
        }
      }
    }

    return {
      category: {
        id: rootId,
        name: "Catalog",
        url_path: "",
        include_in_menu: 1,
        children: Array.from(byId.values()),
      },
    };
  }
};
