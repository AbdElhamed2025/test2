import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type RemoveFromCartParams = {
  cartId: string;
  cartItemId: number;
};

type RemoveFromCartMutation = {
  removeItemFromCart: {
    cart: { id: string; total_quantity?: number };
  };
};

export const removeFromCart = async (
  context: MagentoIntegrationContext,
  params: RemoveFromCartParams
) => {
  const mutation = /* GraphQL */ `
    mutation RemoveFromCart($input: RemoveItemFromCartInput!) {
      removeItemFromCart(input: $input) {
        cart {
          id
          total_quantity
        }
      }
    }
  `;

  return graphqlRequest<RemoveFromCartMutation>(context.client, mutation, {
    input: { cart_id: params.cartId, cart_item_id: params.cartItemId },
  });
};
