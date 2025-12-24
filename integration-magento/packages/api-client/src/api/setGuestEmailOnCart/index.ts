import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type SetGuestEmailOnCartParams = {
  cartId: string;
  email: string;
};

type SetGuestEmailOnCartMutation = {
  setGuestEmailOnCart: { cart: { id: string; email?: string | null } };
};

export const setGuestEmailOnCart = async (
  context: MagentoIntegrationContext,
  params: SetGuestEmailOnCartParams
) => {
  const mutation = /* GraphQL */ `
    mutation SetGuestEmailOnCart($input: SetGuestEmailOnCartInput!) {
      setGuestEmailOnCart(input: $input) {
        cart {
          id
          email
        }
      }
    }
  `;

  return graphqlRequest<SetGuestEmailOnCartMutation>(context.client, mutation, {
    input: { cart_id: params.cartId, email: params.email },
  });
};
