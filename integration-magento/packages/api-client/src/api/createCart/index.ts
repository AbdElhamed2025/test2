import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

type CreateCartMutation = {
  createEmptyCart: string;
};

export const createCart = async (context: MagentoIntegrationContext) => {
  const mutation = /* GraphQL */ `
    mutation CreateCart {
      createEmptyCart
    }
  `;

  return graphqlRequest<CreateCartMutation>(context.client, mutation);
};
