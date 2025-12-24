export type Cart = any;

export function useCart() {
  const { call } = useMagentoApi();

  const cartId = useCookie<string | null>("magento_cart_id", {
    sameSite: "lax",
  });

  const cart = useState<Cart | null>("cart", () => null);
  const loading = useState<boolean>("cart_loading", () => false);
  const error = useState<string | null>("cart_error", () => null);

  async function ensureCartId() {
    if (cartId.value) return cartId.value;
    const res = await call<{ createEmptyCart: string }>("createCart");
    cartId.value = res.createEmptyCart;
    return cartId.value;
  }

  async function refresh() {
    error.value = null;
    loading.value = true;
    try {
      const id = await ensureCartId();
      const res = await call<{ cart: any }>("getCart", { cartId: id });
      cart.value = res.cart;
    } catch (e: any) {
      error.value = e?.message ?? String(e);
    } finally {
      loading.value = false;
    }
  }

  async function add(sku: string, quantity = 1, selectedOptions?: string[]) {
    const id = await ensureCartId();
    const res = await call<any>("addToCart", {
      cartId: id,
      sku,
      quantity,
      selectedOptions,
    });
    const userErrors: Array<{ message: string }> | undefined =
      res?.addProductsToCart?.user_errors;
    if (userErrors?.length) throw new Error(userErrors[0]?.message);
    await refresh();
  }

  async function remove(cartItemId: number) {
    const id = await ensureCartId();
    await call("removeFromCart", { cartId: id, cartItemId });
    await refresh();
  }

  async function update(cartItemId: number, quantity: number) {
    const id = await ensureCartId();
    const res = await call<any>("updateCartItems", {
      cartId: id,
      items: [{ cartItemId, quantity }],
    });
    const userErrors: Array<{ message: string }> | undefined =
      res?.updateCartItems?.user_errors;
    if (userErrors?.length) throw new Error(userErrors[0]?.message);
    await refresh();
  }

  function clear() {
    cartId.value = null;
    cart.value = null;
  }

  return { cartId, cart, loading, error, ensureCartId, refresh, add, remove, update, clear };
}

