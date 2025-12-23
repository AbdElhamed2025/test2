<template>
  <span class="price">
    <span v-if="!price" class="muted">—</span>
    <span v-else>{{ formatted }}</span>
  </span>
</template>

<script setup lang="ts">
const props = defineProps<{ price: any }>();

const formatted = computed(() => {
  const value = Number(props.price?.value ?? 0);
  const currency = String(props.price?.currency ?? "USD");
  try {
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency,
      maximumFractionDigits: 2,
    }).format(value);
  } catch {
    return `${value.toFixed(2)} ${currency}`;
  }
});
</script>

<style scoped>
.price {
  font-weight: 700;
}
</style>

