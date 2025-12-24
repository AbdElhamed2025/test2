import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type SetPaymentMethodOnCartParams = {
  cartId: string;
  paymentMethodCode: string;
};

type SetPaymentMethodOnCartMutation = {
  setPaymentMethodOnCart: {
    cart: { id: string };
  };
};

export const setPaymentMethodOnCart = async (
  context: MagentoIntegrationContext,
  params: SetPaymentMethodOnCartParams
) => {
  const mutation = /* GraphQL */ `
    mutation SetPaymentMethodOnCart($input: SetPaymentMethodOnCartInput!) {
      setPaymentMethodOnCart(input: $input) {
        cart {
          id
        }
      }
    }
  `;

  return graphqlRequest<SetPaymentMethodOnCartMutation>(
    context.client,
    mutation,
    {
      input: {
        cart_id: params.cartId,
        payment_method: { code: params.paymentMethodCode },
      },
    }
  );
};
