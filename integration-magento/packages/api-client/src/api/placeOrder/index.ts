import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type PlaceOrderParams = {
  cartId: string;
};

type PlaceOrderMutation = {
  placeOrder: {
    order: { order_number: string };
  };
};

export const placeOrder = async (
  context: MagentoIntegrationContext,
  params: PlaceOrderParams
) => {
  const mutation = /* GraphQL */ `
    mutation PlaceOrder($input: PlaceOrderInput!) {
      placeOrder(input: $input) {
        order {
          order_number
        }
      }
    }
  `;

  return graphqlRequest<PlaceOrderMutation>(context.client, mutation, {
    input: { cart_id: params.cartId },
  });
};
