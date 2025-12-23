<template>
  <section class="panel section">
    <div class="head">
      <h1 class="title">Checkout</h1>
      <NuxtLink class="btn" to="/cart">Back to cart</NuxtLink>
    </div>

    <div v-if="loading" class="muted">Loading…</div>
    <div v-else-if="cartError" class="muted">{{ cartError }}</div>
    <div v-else-if="!hasItems" class="muted">Cart is empty.</div>

    <div v-else class="grid">
      <div class="panel form">
        <h2 class="h">Contact</h2>
        <label class="label muted">Email</label>
        <input v-model="email" class="input" type="email" placeholder="you@example.com" />

        <h2 class="h">Shipping address</h2>
        <div class="two">
          <div>
            <label class="label muted">First name</label>
            <input v-model="address.firstname" class="input" />
          </div>
          <div>
            <label class="label muted">Last name</label>
            <input v-model="address.lastname" class="input" />
          </div>
        </div>
        <label class="label muted">Street</label>
        <input v-model="street1" class="input" />
        <div class="two">
          <div>
            <label class="label muted">City</label>
            <input v-model="address.city" class="input" />
          </div>
          <div>
            <label class="label muted">Region</label>
            <input v-model="address.region" class="input" />
          </div>
        </div>
        <div class="two">
          <div>
            <label class="label muted">Postcode</label>
            <input v-model="address.postcode" class="input" />
          </div>
          <div>
            <label class="label muted">Country code</label>
            <input v-model="address.country_code" class="input" placeholder="EG" />
          </div>
        </div>
        <label class="label muted">Phone</label>
        <input v-model="address.telephone" class="input" />

        <button class="btn btnPrimary" @click="applyAddress" :disabled="busy">
          {{ busy ? "Saving…" : "Save & load shipping methods" }}
        </button>
      </div>

      <div class="panel side">
        <h2 class="h">Shipping</h2>
        <div v-if="shippingMethods.length === 0" class="muted">
          Enter an address to load shipping methods.
        </div>
        <div v-else class="radios">
          <label v-for="m in shippingMethods" :key="m.key" class="radio">
            <input type="radio" name="ship" v-model="shippingKey" :value="m.key" />
            <div class="radioBody">
              <div>{{ m.label }}</div>
              <Price :price="m.amount" />
            </div>
          </label>
          <button class="btn" @click="applyShipping" :disabled="busy || !shippingKey">
            Apply shipping method
          </button>
        </div>

        <h2 class="h">Payment</h2>
        <div v-if="paymentMethods.length === 0" class="muted">
          Apply shipping method to load payment methods.
        </div>
        <div v-else class="radios">
          <label v-for="p in paymentMethods" :key="p.code" class="radio">
            <input type="radio" name="pay" v-model="paymentCode" :value="p.code" />
            <div class="radioBody">
              <div>{{ p.title }}</div>
              <div class="muted">{{ p.code }}</div>
            </div>
          </label>
          <button class="btn" @click="applyPayment" :disabled="busy || !paymentCode">
            Apply payment method
          </button>
        </div>

        <h2 class="h">Order</h2>
        <div class="sumRow">
          <span class="muted">Total</span>
          <Price :price="cart?.prices?.grand_total" />
        </div>
        <button class="btn btnPrimary" @click="place" :disabled="busy || !canPlace">
          {{ busy ? "Placing…" : "Place order" }}
        </button>

        <div v-if="err" class="muted">{{ err }}</div>
        <div v-if="orderNumber" class="success">
          Order placed: <strong>{{ orderNumber }}</strong>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const { call } = useMagentoApi();
const { cart, loading, error: cartError, refresh, ensureCartId, clear } = useCart();

await useAsyncData("checkout_cart", async () => {
  await refresh();
  return true;
});

const hasItems = computed(() => (cart.value?.items?.length ?? 0) > 0);

const email = ref("");
const street1 = ref("");
const address = reactive({
  firstname: "",
  lastname: "",
  street: [] as string[],
  city: "",
  region: "",
  postcode: "",
  country_code: "EG",
  telephone: "",
});

const shippingMethods = computed(() => {
  const methods =
    cart.value?.shipping_addresses?.[0]?.available_shipping_methods ?? [];
  return (methods as any[])
    .filter(Boolean)
    .map((m) => ({
      key: `${m.carrier_code}::${m.method_code}`,
      carrier_code: m.carrier_code,
      method_code: m.method_code,
      label: `${m.carrier_title || m.carrier_code} — ${m.method_title || m.method_code}`,
      amount: m.amount,
    }));
});

const paymentMethods = computed(() => cart.value?.available_payment_methods ?? []);

const shippingKey = ref<string | null>(null);
const paymentCode = ref<string | null>(null);

const busy = ref(false);
const err = ref<string | null>(null);
const orderNumber = ref<string | null>(null);

const canPlace = computed(() => Boolean(shippingKey.value && paymentCode.value && email.value));

async function applyAddress() {
  err.value = null;
  busy.value = true;
  try {
    const id = await ensureCartId();
    await call("setGuestEmailOnCart", { cartId: id, email: email.value.trim() });
    await call("setShippingAddressOnCart", {
      cartId: id,
      address: {
        ...address,
        street: [street1.value].filter(Boolean),
      },
    });
    await refresh();
  } catch (e: any) {
    err.value = e?.message ?? String(e);
  } finally {
    busy.value = false;
  }
}

async function applyShipping() {
  if (!shippingKey.value) return;
  err.value = null;
  busy.value = true;
  try {
    const [carrierCode, methodCode] = shippingKey.value.split("::");
    const id = await ensureCartId();
    await call("setShippingMethodOnCart", { cartId: id, carrierCode, methodCode });
    await refresh();
  } catch (e: any) {
    err.value = e?.message ?? String(e);
  } finally {
    busy.value = false;
  }
}

async function applyPayment() {
  if (!paymentCode.value) return;
  err.value = null;
  busy.value = true;
  try {
    const id = await ensureCartId();
    await call("setPaymentMethodOnCart", { cartId: id, paymentMethodCode: paymentCode.value });
    await refresh();
  } catch (e: any) {
    err.value = e?.message ?? String(e);
  } finally {
    busy.value = false;
  }
}

async function place() {
  err.value = null;
  orderNumber.value = null;
  busy.value = true;
  try {
    const id = await ensureCartId();
    const res = await call<any>("placeOrder", { cartId: id });
    orderNumber.value = res?.placeOrder?.order?.order_number ?? "—";
    clear();
  } catch (e: any) {
    err.value = e?.message ?? String(e);
  } finally {
    busy.value = false;
  }
}
</script>

<style scoped>
.section {
  padding: 18px;
}
.head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 14px;
}
.title {
  margin: 0;
  font-size: 22px;
}
.grid {
  display: grid;
  gap: 12px;
}
@media (min-width: 900px) {
  .grid {
    grid-template-columns: 1fr 360px;
    align-items: start;
  }
}
.form {
  padding: 14px;
  display: grid;
  gap: 10px;
}
.side {
  padding: 14px;
  display: grid;
  gap: 12px;
}
.h {
  margin: 6px 0 0;
  font-size: 16px;
}
.label {
  font-size: 12px;
}
.two {
  display: grid;
  gap: 10px;
}
@media (min-width: 700px) {
  .two {
    grid-template-columns: 1fr 1fr;
  }
}
.radios {
  display: grid;
  gap: 8px;
}
.radio {
  display: grid;
  grid-template-columns: 18px 1fr;
  gap: 10px;
  align-items: start;
  padding: 10px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.03);
}
.radioBody {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  align-items: baseline;
}
.sumRow {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  padding-top: 8px;
  border-top: 1px solid var(--border);
}
.success {
  padding: 10px;
  border-radius: 14px;
  border: 1px solid rgba(91, 140, 255, 0.5);
  background: rgba(91, 140, 255, 0.12);
}
</style>

