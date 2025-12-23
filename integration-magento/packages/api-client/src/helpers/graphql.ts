import type { AxiosInstance } from "axios";

type GraphqlResponse<TData> = {
  data?: TData;
  errors?: Array<{ message: string; extensions?: unknown }>;
};

export class MagentoGraphQLError extends Error {
  public readonly errors?: GraphqlResponse<unknown>["errors"];

  constructor(message: string, errors?: GraphqlResponse<unknown>["errors"]) {
    super(message);
    this.name = "MagentoGraphQLError";
    this.errors = errors;
  }
}

export async function graphqlRequest<TData>(
  client: AxiosInstance,
  query: string,
  variables?: Record<string, unknown>
): Promise<TData> {
  const res = await client.post<GraphqlResponse<TData>>("", {
    query,
    variables,
  });

  if (res.data?.errors?.length) {
    const message = res.data.errors.map((e) => e.message).join("; ");
    throw new MagentoGraphQLError(message, res.data.errors);
  }

  if (!res.data?.data) {
    throw new MagentoGraphQLError("Empty GraphQL response from Magento.");
  }

  return res.data.data;
}
