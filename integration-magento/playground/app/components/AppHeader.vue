<template>
  <header class="header">
    <div class="container headerInner">
      <div class="brand">
        <NuxtLink to="/" class="brandLink">{{ storeName }}</NuxtLink>
        <span class="brandTag muted">Headless</span>
      </div>

      <form class="search" @submit.prevent="goSearch">
        <input
          v-model="q"
          class="input"
          type="search"
          placeholder="Search products…"
        />
      </form>

      <div class="actions">
        <NuxtLink to="/cart" class="btn">
          Cart
          <span v-if="cartQty" class="pill">{{ cartQty }}</span>
        </NuxtLink>
      </div>
    </div>

    <div class="container navRow" v-if="menuItems.length">
      <NuxtLink
        v-for="c in menuItems"
        :key="c.id"
        class="navLink"
        :to="`/category/${c.id}`"
      >
        {{ c.name }}
      </NuxtLink>
    </div>
  </header>
</template>

<script setup lang="ts">
const router = useRouter();
const q = ref("");

const { call } = useMagentoApi();
const { cart, refresh } = useCart();

const { data: storeConfig } = await useAsyncData("storeConfig", async () => {
  try {
    return await call<{ storeConfig: { store_name?: string } }>("getStoreConfig");
  } catch {
    return { storeConfig: { store_name: "Store" } };
  }
});

const { data: categoryTree } = await useAsyncData("categoryTree", async () => {
  try {
    return await call<any>("getCategoryTree", { rootId: 2 });
  } catch {
    return null;
  }
});

const storeName = computed(
  () => storeConfig.value?.storeConfig?.store_name ?? "Store"
);

const menuItems = computed(() => {
  const children = categoryTree.value?.category?.children ?? [];
  return (children as any[])
    .filter((c) => c?.include_in_menu !== 0)
    .slice(0, 10);
});

const cartQty = computed(() => cart.value?.total_quantity ?? 0);

onMounted(() => {
  // Keep cart badge updated on client.
  refresh().catch(() => {});
});

function goSearch() {
  if (!q.value.trim()) return;
  router.push({ path: "/search", query: { q: q.value.trim() } });
}
</script>

<style scoped>
.header {
  position: sticky;
  top: 0;
  z-index: 10;
  backdrop-filter: blur(10px);
  background: rgba(11, 15, 25, 0.75);
  border-bottom: 1px solid var(--border);
}
.headerInner {
  display: grid;
  grid-template-columns: 220px 1fr auto;
  gap: 12px;
  align-items: center;
}
.brand {
  display: flex;
  gap: 10px;
  align-items: baseline;
}
.brandLink {
  font-weight: 800;
  letter-spacing: 0.2px;
}
.brandTag {
  font-size: 12px;
}
.search {
  width: 100%;
}
.actions {
  display: flex;
  gap: 10px;
  align-items: center;
}
.pill {
  margin-left: 8px;
  padding: 2px 8px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.12);
  border: 1px solid var(--border);
}
.navRow {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding-bottom: 10px;
}
.navLink {
  padding: 8px 10px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: rgba(255, 255, 255, 0.03);
  white-space: nowrap;
  font-size: 13px;
}
</style>

