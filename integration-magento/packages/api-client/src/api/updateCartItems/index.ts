import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type UpdateCartItemsParams = {
  cartId: string;
  items: Array<{ cartItemId: number; quantity: number }>;
};

type UpdateCartItemsMutation = {
  updateCartItems: {
    cart: { id: string; total_quantity?: number };
    user_errors: Array<{ code: string; message: string }>;
  };
};

export const updateCartItems = async (
  context: MagentoIntegrationContext,
  params: UpdateCartItemsParams
) => {
  const mutation = /* GraphQL */ `
    mutation UpdateCartItems($input: UpdateCartItemsInput!) {
      updateCartItems(input: $input) {
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

  return graphqlRequest<UpdateCartItemsMutation>(context.client, mutation, {
    input: {
      cart_id: params.cartId,
      cart_items: params.items.map((i) => ({
        cart_item_id: i.cartItemId,
        quantity: i.quantity,
      })),
    },
  });
};
