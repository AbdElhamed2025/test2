<template>
  <section class="panel section">
    <div class="head">
      <h1 class="title">Search</h1>
      <div class="muted" v-if="q">“{{ q }}”</div>
    </div>

    <div v-if="pending" class="muted">Searching…</div>
    <div v-else-if="errorMsg" class="muted">{{ errorMsg }}</div>

    <div v-else class="cards">
      <ProductCard v-for="p in items" :key="p.sku" :product="p" />
    </div>
  </section>
</template>

<script setup lang="ts">
const route = useRoute();
const { call } = useMagentoApi();

const q = computed(() => String(route.query.q ?? "").trim());

const { data, pending, error } = await useAsyncData(
  () => `search:${q.value}`,
  async () => {
    if (!q.value) return { products: { items: [] } };
    return call<any>("searchProducts", { search: q.value, pageSize: 24, currentPage: 1 });
  }
);

const items = computed(() => data.value?.products?.items ?? []);
const errorMsg = computed(() => (error.value as any)?.message ?? "");
</script>

<style scoped>
.section {
  padding: 18px;
}
.head {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: baseline;
  margin-bottom: 14px;
}
.title {
  margin: 0;
  font-size: 22px;
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

