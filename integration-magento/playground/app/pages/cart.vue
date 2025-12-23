<template>
  <section class="panel section">
    <div class="head">
      <h1 class="title">Cart</h1>
      <NuxtLink class="btn btnPrimary" to="/checkout" v-if="hasItems">Checkout</NuxtLink>
    </div>

    <div v-if="loading" class="muted">Loading cart…</div>
    <div v-else-if="error" class="muted">{{ error }}</div>

    <div v-else-if="!hasItems" class="empty">
      <div class="muted">Your cart is empty.</div>
      <NuxtLink class="btn btnPrimary" to="/">Browse products</NuxtLink>
    </div>

    <div v-else class="cartGrid">
      <div class="items">
        <div class="item" v-for="item in cart.items" :key="item.id">
          <img
            v-if="item.product?.thumbnail?.url"
            class="thumb"
            :src="item.product.thumbnail.url"
            :alt="item.product.name"
          />
          <div v-else class="thumb fallback muted">—</div>

          <div class="meta">
            <div class="name">{{ item.product.name }}</div>
            <div class="muted">SKU: {{ item.product.sku }}</div>
            <Price :price="item.prices?.price" />
          </div>

          <div class="qtyCol">
            <div class="qtyRow">
              <button class="btn" @click="dec(item)" :disabled="busy">-</button>
              <input
                class="input qty"
                type="number"
                min="1"
                :value="item.quantity"
                @change="onQtyInput(item, $event)"
              />
              <button class="btn" @click="inc(item)" :disabled="busy">+</button>
            </div>
            <button class="btn" @click="removeItem(item)" :disabled="busy">
              Remove
            </button>
          </div>
        </div>
      </div>

      <div class="summary panel">
        <div class="sumRow">
          <span class="muted">Subtotal</span>
          <Price :price="cart.prices?.subtotal_including_tax || cart.prices?.subtotal_excluding_tax" />
        </div>
        <div class="sumRow total">
          <span>Total</span>
          <Price :price="cart.prices?.grand_total" />
        </div>
        <NuxtLink class="btn btnPrimary" to="/checkout">Checkout</NuxtLink>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const { cart, loading, error, refresh, remove, update } = useCart();
const busy = ref(false);

await useAsyncData("cart", async () => {
  await refresh();
  return true;
});

const hasItems = computed(() => (cart.value?.items?.length ?? 0) > 0);

function toInt(v: any, fallback = 1) {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : fallback;
}

async function inc(item: any) {
  busy.value = true;
  try {
    await update(item.id, toInt(item.quantity) + 1);
  } finally {
    busy.value = false;
  }
}

async function dec(item: any) {
  busy.value = true;
  try {
    const next = Math.max(1, toInt(item.quantity) - 1);
    await update(item.id, next);
  } finally {
    busy.value = false;
  }
}

async function onQtyInput(item: any, ev: Event) {
  const target = ev.target as HTMLInputElement;
  const next = Math.max(1, toInt(target.value));
  busy.value = true;
  try {
    await update(item.id, next);
  } finally {
    busy.value = false;
  }
}

async function removeItem(item: any) {
  busy.value = true;
  try {
    await remove(item.id);
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
.empty {
  display: grid;
  gap: 12px;
  justify-items: start;
}
.cartGrid {
  display: grid;
  gap: 12px;
}
@media (min-width: 900px) {
  .cartGrid {
    grid-template-columns: 1fr 320px;
    align-items: start;
  }
}
.items {
  display: grid;
  gap: 10px;
}
.item {
  display: grid;
  grid-template-columns: 72px 1fr auto;
  gap: 12px;
  align-items: center;
  padding: 12px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.03);
}
.thumb {
  width: 72px;
  height: 72px;
  object-fit: contain;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: rgba(255, 255, 255, 0.03);
}
.fallback {
  display: grid;
  place-items: center;
}
.meta {
  display: grid;
  gap: 4px;
}
.name {
  font-weight: 650;
}
.qtyCol {
  display: grid;
  gap: 8px;
  justify-items: end;
}
.qtyRow {
  display: flex;
  gap: 8px;
  align-items: center;
}
.qty {
  width: 80px;
}
.summary {
  padding: 14px;
  display: grid;
  gap: 12px;
}
.sumRow {
  display: flex;
  justify-content: space-between;
  gap: 12px;
}
.total {
  padding-top: 10px;
  border-top: 1px solid var(--border);
  font-weight: 800;
}
</style>

