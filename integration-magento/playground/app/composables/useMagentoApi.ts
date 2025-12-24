type AnyRecord = Record<string, any>;

export function useMagentoApi() {
  const config = useRuntimeConfig();

  const base = computed(() => String(config.public.middlewareUrl).replace(/\/$/, ""));

  async function call<TResponse = any>(
    method: string,
    params?: AnyRecord
  ): Promise<TResponse> {
    const res = await $fetch<any>(`${base.value}/${method}`, {
      method: "POST",
      body: params ?? {},
      credentials: "include",
    });

    // VSF middleware may wrap results in `{ data: ... }`.
    return (res?.data ?? res) as TResponse;
  }

  return { call };
}

