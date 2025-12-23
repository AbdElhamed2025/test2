import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type GetCartParams = {
  cartId: string;
};

type GetCartQuery = {
  cart: {
    id: string;
    email?: string | null;
    total_quantity?: number;
    items?: Array<{
      id: number;
      quantity: number;
      product: {
        sku: string;
        name: string;
        thumbnail?: { url: string } | null;
        price_range?: {
          minimum_price?: {
            final_price?: { value: number; currency: string };
            regular_price?: { value: number; currency: string };
          };
        };
      };
      prices?: {
        price?: { value: number; currency: string };
        row_total?: { value: number; currency: string };
      } | null;
    }> | null;
    prices?: {
      grand_total?: { value: number; currency: string };
      subtotal_excluding_tax?: { value: number; currency: string };
      subtotal_including_tax?: { value: number; currency: string };
    } | null;
    shipping_addresses?: Array<{
      available_shipping_methods?: Array<{
        carrier_code: string;
        method_code: string;
        carrier_title?: string | null;
        method_title?: string | null;
        amount?: { value: number; currency: string };
      }> | null;
      selected_shipping_method?: {
        carrier_code: string;
        method_code: string;
        carrier_title?: string | null;
        method_title?: string | null;
        amount?: { value: number; currency: string };
      } | null;
    }> | null;
    available_payment_methods?: Array<{
      code: string;
      title: string;
    }> | null;
    selected_payment_method?: { code: string; title: string } | null;
  };
};

export const getCart = async (
  context: MagentoIntegrationContext,
  params: GetCartParams
) => {
  const query = /* GraphQL */ `
    query GetCart($cartId: String!) {
      cart(cart_id: $cartId) {
        id
        email
        total_quantity
        items {
          id
          quantity
          product {
            sku
            name
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
          prices {
            price {
              value
              currency
            }
            row_total {
              value
              currency
            }
          }
        }
        prices {
          grand_total {
            value
            currency
          }
          subtotal_excluding_tax {
            value
            currency
          }
          subtotal_including_tax {
            value
            currency
          }
        }
        shipping_addresses {
          selected_shipping_method {
            carrier_code
            method_code
            carrier_title
            method_title
            amount {
              value
              currency
            }
          }
          available_shipping_methods {
            carrier_code
            method_code
            carrier_title
            method_title
            amount {
              value
              currency
            }
          }
        }
        available_payment_methods {
          code
          title
        }
        selected_payment_method {
          code
          title
        }
      }
    }
  `;

  return graphqlRequest<GetCartQuery>(context.client, query, {
    cartId: params.cartId,
  });
};
