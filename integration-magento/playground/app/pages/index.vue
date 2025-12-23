<template>
  <div class="grid">
    <section class="panel hero">
      <h1 class="title">Headless storefront for Ahmed El Sallab</h1>
      <p class="muted">
        This UI is powered by Vue Storefront middleware + Magento GraphQL.
      </p>
      <div class="heroActions">
        <NuxtLink class="btn btnPrimary" to="/search?q=ceramic">Search “ceramic”</NuxtLink>
        <NuxtLink class="btn" to="/cart">View cart</NuxtLink>
      </div>
    </section>

    <section class="panel section">
      <div class="sectionHead">
        <h2 class="sectionTitle">Featured products</h2>
        <span class="muted" v-if="featuredCategory">
          from {{ featuredCategory.name }}
        </span>
      </div>

      <div v-if="pending" class="muted">Loading…</div>
      <div v-else-if="errorMsg" class="muted">{{ errorMsg }}</div>

      <div v-else class="cards">
        <ProductCard v-for="p in products" :key="p.sku" :product="p" />
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
const { call } = useMagentoApi();

const { data, pending, error } = await useAsyncData("homeFeatured", async () => {
  const tree = await call<any>("getCategoryTree", { rootId: 2 });
  const firstChild = tree?.category?.children?.[0];
  if (!firstChild?.id) return { featuredCategory: null, products: [] };
  const cat = await call<any>("getCategory", { categoryId: Number(firstChild.id), pageSize: 12, currentPage: 1 });
  return { featuredCategory: cat?.category, products: cat?.category?.products?.items ?? [] };
});

const featuredCategory = computed(() => data.value?.featuredCategory ?? null);
const products = computed(() => data.value?.products ?? []);
const errorMsg = computed(() => (error.value as any)?.message ?? "");
</script>

<style scoped>
.grid {
  display: grid;
  gap: 16px;
}
.hero {
  padding: 18px;
}
.title {
  margin: 0 0 8px;
  font-size: 28px;
  letter-spacing: -0.2px;
}
.heroActions {
  display: flex;
  gap: 10px;
  margin-top: 14px;
  flex-wrap: wrap;
}
.section {
  padding: 18px;
}
.sectionHead {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: baseline;
  margin-bottom: 14px;
}
.sectionTitle {
  margin: 0;
  font-size: 18px;
}
.cards {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}
@media (min-width: 800px) {
  .cards {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}
</style>

