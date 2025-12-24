<template>
  <div class="panel card">
    <NuxtLink :to="`/product/${product.sku}`" class="imgWrap">
      <img
        v-if="img"
        class="img"
        :src="img"
        :alt="product.name"
        loading="lazy"
      />
      <div v-else class="imgFallback muted">No image</div>
    </NuxtLink>

    <div class="content">
      <NuxtLink :to="`/product/${product.sku}`" class="name">
        {{ product.name }}
      </NuxtLink>
      <div class="row">
        <Price :price="price" />
        <button class="btn btnPrimary" @click="addToCart" :disabled="adding">
          {{ adding ? "Adding…" : "Add" }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  product: any;
}>();

const adding = ref(false);
const { add } = useCart();

const img = computed(
  () => props.product?.thumbnail?.url || props.product?.small_image?.url || null
);
const price = computed(() => {
  const min = props.product?.price_range?.minimum_price;
  return min?.final_price || min?.regular_price || null;
});

async function addToCart() {
  adding.value = true;
  try {
    await add(props.product.sku, 1);
  } finally {
    adding.value = false;
  }
}
</script>

<style scoped>
.card {
  overflow: hidden;
}
.imgWrap {
  display: block;
  aspect-ratio: 1 / 1;
  background: rgba(255, 255, 255, 0.03);
  border-bottom: 1px solid var(--border);
}
.img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}
.imgFallback {
  display: grid;
  place-items: center;
  height: 100%;
}
.content {
  padding: 12px;
  display: grid;
  gap: 10px;
}
.name {
  font-weight: 650;
  line-height: 1.2;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 2.4em;
}
.row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}
</style>

