<template>
  <section class="panel section" v-if="product">
    <div class="grid">
      <div class="gallery">
        <img v-if="mainImg" class="mainImg" :src="mainImg" :alt="product.name" />
        <div v-else class="mainImg fallback muted">No image</div>

        <div class="thumbs" v-if="images.length > 1">
          <button
            v-for="img in images"
            :key="img.url"
            class="thumbBtn"
            @click="mainImg = img.url"
          >
            <img class="thumb" :src="img.url" :alt="img.label || product.name" />
          </button>
        </div>
      </div>

      <div class="info">
        <h1 class="title">{{ product.name }}</h1>
        <div class="sku muted">SKU: {{ product.sku }}</div>
        <Price :price="price" />

        <div v-if="isConfigurable && options.length" class="opts">
          <div v-for="opt in options" :key="opt.attribute_code" class="opt">
            <label class="muted">{{ opt.label }}</label>
            <select class="input" v-model.number="selected[opt.attribute_code]">
              <option :value="undefined" disabled>Select…</option>
              <option v-for="v in opt.values" :key="v.value_index" :value="v.value_index">
                {{ v.label || v.value_index }}
              </option>
            </select>
          </div>
          <div class="muted" v-if="isConfigurable && !selectedVariantSku">
            Select options to choose a variant.
          </div>
        </div>

        <div class="row">
          <input class="input qty" type="number" min="1" v-model.number="qty" />
          <button class="btn btnPrimary" @click="addNow" :disabled="adding || !canAdd">
            {{ adding ? "Adding…" : "Add to cart" }}
          </button>
          <NuxtLink to="/cart" class="btn">Go to cart</NuxtLink>
        </div>

        <div v-if="err" class="muted">{{ err }}</div>

        <div class="desc" v-if="product.description?.html" v-html="product.description.html" />
      </div>
    </div>
  </section>

  <section v-else class="panel section">
    <div class="muted" v-if="pending">Loading…</div>
    <div class="muted" v-else-if="errorMsg">{{ errorMsg }}</div>
  </section>
</template>

<script setup lang="ts">
const route = useRoute();
const { call } = useMagentoApi();
const { add } = useCart();

const sku = computed(() => String(route.params.sku));

const { data, pending, error } = await useAsyncData(
  () => `product:${sku.value}`,
  async () => call<any>("getProduct", { sku: sku.value })
);

const product = computed(() => data.value?.products?.items?.[0] ?? null);
const errorMsg = computed(() => (error.value as any)?.message ?? "");

const images = computed(() => (product.value?.media_gallery ?? []).filter(Boolean));
const mainImg = ref<string | null>(null);

watchEffect(() => {
  const img =
    product.value?.thumbnail?.url ||
    product.value?.small_image?.url ||
    images.value?.[0]?.url ||
    null;
  mainImg.value = img;
});

const price = computed(() => {
  const min = product.value?.price_range?.minimum_price;
  return min?.final_price || min?.regular_price || null;
});

const isConfigurable = computed(() => product.value?.__typename === "ConfigurableProduct");
const options = computed(() => product.value?.configurable_options ?? []);
const variants = computed(() => product.value?.variants ?? []);

const selected = reactive<Record<string, number | undefined>>({});
const selectedVariantSku = computed(() => {
  if (!isConfigurable.value) return product.value?.sku ?? null;
  const requiredCodes = (options.value as any[]).map((o) => o.attribute_code);
  if (requiredCodes.some((code) => !selected[code])) return null;

  const match = (variants.value as any[]).find((v) => {
    const attrs: Array<{ code: string; value_index: number }> = v.attributes ?? [];
    return requiredCodes.every((code) =>
      attrs.some((a) => a.code === code && a.value_index === selected[code])
    );
  });

  return match?.product?.sku ?? null;
});

const qty = ref(1);
const adding = ref(false);
const err = ref<string | null>(null);

const canAdd = computed(() => {
  if (!product.value) return false;
  if (isConfigurable.value) return Boolean(selectedVariantSku.value);
  return true;
});

async function addNow() {
  err.value = null;
  adding.value = true;
  try {
    const skuToAdd = selectedVariantSku.value || product.value?.sku;
    if (!skuToAdd) throw new Error("Missing product SKU.");
    await add(skuToAdd, qty.value);
  } catch (e: any) {
    err.value = e?.message ?? String(e);
  } finally {
    adding.value = false;
  }
}
</script>

<style scoped>
.section {
  padding: 18px;
}
.grid {
  display: grid;
  gap: 16px;
}
@media (min-width: 900px) {
  .grid {
    grid-template-columns: 420px 1fr;
    align-items: start;
  }
}
.gallery {
  display: grid;
  gap: 10px;
}
.mainImg {
  width: 100%;
  aspect-ratio: 1 / 1;
  object-fit: contain;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--border);
  border-radius: 14px;
}
.fallback {
  display: grid;
  place-items: center;
}
.thumbs {
  display: flex;
  gap: 8px;
  overflow-x: auto;
}
.thumbBtn {
  padding: 0;
  border: 1px solid var(--border);
  background: rgba(255, 255, 255, 0.03);
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
}
.thumb {
  width: 78px;
  height: 78px;
  object-fit: contain;
  display: block;
}
.info {
  display: grid;
  gap: 12px;
}
.title {
  margin: 0;
  font-size: 22px;
}
.sku {
  font-size: 13px;
}
.row {
  display: flex;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
}
.qty {
  width: 90px;
}
.opts {
  display: grid;
  gap: 10px;
  padding: 12px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.03);
}
.opt {
  display: grid;
  gap: 6px;
}
.desc {
  border-top: 1px solid var(--border);
  padding-top: 12px;
}
</style>

