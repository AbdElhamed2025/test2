export default defineNuxtConfig({
  ssr: true,
  devtools: { enabled: true },
  app: {
    head: {
      title: "Ahmed El Sallab — Headless Storefront",
      meta: [{ name: "viewport", content: "width=device-width, initial-scale=1" }],
    },
  },
  runtimeConfig: {
    public: {
      middlewareUrl:
        process.env.NUXT_PUBLIC_MIDDLEWARE_URL ??
        "http://localhost:4000/magento",
    },
  },
});

