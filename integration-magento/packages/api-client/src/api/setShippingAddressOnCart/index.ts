import { MagentoIntegrationContext } from "../../types";
import { graphqlRequest } from "../../helpers/graphql";

export type CartAddress = {
  firstname: string;
  lastname: string;
  street: string[];
  city: string;
  region?: string;
  postcode: string;
  country_code: string;
  telephone: string;
};

export type SetShippingAddressOnCartParams = {
  cartId: string;
  address: CartAddress;
};

type SetShippingAddressOnCartMutation = {
  setShippingAddressesOnCart: {
    cart: { id: string };
  };
};

export const setShippingAddressOnCart = async (
  context: MagentoIntegrationContext,
  params: SetShippingAddressOnCartParams
) => {
  const mutation = /* GraphQL */ `
    mutation SetShippingAddressOnCart(
      $input: SetShippingAddressesOnCartInput!
    ) {
      setShippingAddressesOnCart(input: $input) {
        cart {
          id
        }
      }
    }
  `;

  return graphqlRequest<SetShippingAddressOnCartMutation>(
    context.client,
    mutation,
    {
      input: {
        cart_id: params.cartId,
        shipping_addresses: [
          {
            address: {
              firstname: params.address.firstname,
              lastname: params.address.lastname,
              street: params.address.street,
              city: params.address.city,
              region: params.address.region,
              postcode: params.address.postcode,
              country_code: params.address.country_code,
              telephone: params.address.telephone,
              save_in_address_book: false,
            },
          },
        ],
      },
    }
  );
};
