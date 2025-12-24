import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type SetShippingMethodOnCartParams = {
  cartId: string;
  carrierCode: string;
  methodCode: string;
};

type SetShippingMethodOnCartMutation = {
  setShippingMethodsOnCart: {
    cart: { id: string };
  };
};

export const setShippingMethodOnCart = async (
  context: MagentoIntegrationContext,
  params: SetShippingMethodOnCartParams
) => {
  const mutation = /* GraphQL */ `
    mutation SetShippingMethodOnCart($input: SetShippingMethodsOnCartInput!) {
      setShippingMethodsOnCart(input: $input) {
        cart {
          id
        }
      }
    }
  `;

  return graphqlRequest<SetShippingMethodOnCartMutation>(
    context.client,
    mutation,
    {
      input: {
        cart_id: params.cartId,
        shipping_methods: [
          { carrier_code: params.carrierCode, method_code: params.methodCode },
        ],
      },
    }
  );
};
