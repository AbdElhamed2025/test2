<template>
  <section class="panel section">
    <div class="head">
      <div>
        <h1 class="title">{{ category?.name ?? "Category" }}</h1>
        <p v-if="category?.description" class="muted" v-html="category.description" />
      </div>
      <div class="muted" v-if="totalCount">
        {{ totalCount }} products
      </div>
    </div>

    <div v-if="pending" class="muted">Loading…</div>
    <div v-else-if="errorMsg" class="muted">{{ errorMsg }}</div>

    <div v-else class="cards">
      <ProductCard v-for="p in products" :key="p.sku" :product="p" />
    </div>

    <div v-if="totalPages > 1" class="pager">
      <NuxtLink class="btn" :to="pageLink(currentPage - 1)" :aria-disabled="currentPage <= 1">
        Prev
      </NuxtLink>
      <span class="muted">Page {{ currentPage }} / {{ totalPages }}</span>
      <NuxtLink class="btn" :to="pageLink(currentPage + 1)" :aria-disabled="currentPage >= totalPages">
        Next
      </NuxtLink>
    </div>
  </section>
</template>

<script setup lang="ts">
const route = useRoute();
const { call } = useMagentoApi();

const categoryId = computed(() => Number(route.params.id));
const currentPage = computed(() => Number(route.query.page ?? 1));

const { data, pending, error } = await useAsyncData(
  () => `category:${categoryId.value}:${currentPage.value}`,
  async () => {
    return call<any>("getCategory", {
      categoryId: categoryId.value,
      pageSize: 24,
      currentPage: currentPage.value,
    });
  }
);

const category = computed(() => data.value?.category ?? null);
const products = computed(() => category.value?.products?.items ?? []);
const totalCount = computed(() => category.value?.products?.total_count ?? 0);
const totalPages = computed(() => category.value?.products?.page_info?.total_pages ?? 1);
const errorMsg = computed(() => (error.value as any)?.message ?? "");

function pageLink(page: number) {
  if (page < 1) page = 1;
  if (page > totalPages.value) page = totalPages.value;
  return { path: route.path, query: { ...route.query, page } };
}
</script>

<style scoped>
.section {
  padding: 18px;
}
.head {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: flex-start;
  margin-bottom: 14px;
}
.title {
  margin: 0 0 8px;
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
.pager {
  margin-top: 18px;
  display: flex;
  gap: 12px;
  align-items: center;
  justify-content: center;
}
</style>

