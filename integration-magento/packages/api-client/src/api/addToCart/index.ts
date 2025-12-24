import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type AddToCartParams = {
  cartId: string;
  sku: string;
  quantity: number;
  /**
   * Base64-encoded selected options for configurable products.
   * (Magento expects these values as returned by `configurable_options` / `variants` resolution.)
   */
  selectedOptions?: string[];
};

type AddToCartMutation = {
  addProductsToCart: {
    cart: { id: string; total_quantity?: number };
    user_errors: Array<{ code: string; message: string }>;
  };
};

export const addToCart = async (
  context: MagentoIntegrationContext,
  params: AddToCartParams
) => {
  const mutation = /* GraphQL */ `
    mutation AddToCart($cartId: String!, $cartItems: [CartItemInput!]!) {
      addProductsToCart(cartId: $cartId, cartItems: $cartItems) {
        cart {
          id
          total_quantity
        }
        user_errors {
          code
          message
        }
      }
    }
  `;

  return graphqlRequest<AddToCartMutation>(context.client, mutation, {
    cartId: params.cartId,
    cartItems: [
      {
        sku: params.sku,
        quantity: params.quantity,
        ...(params.selectedOptions?.length
          ? { selected_options: params.selectedOptions }
          : {}),
      },
    ],
  });
};
