<template>
  <div class="appShell">
    <AppHeader />
    <main class="container">
      <NuxtPage />
    </main>
  </div>
</template>

<style>
:root {
  --bg: #0b0f19;
  --panel: #121a2b;
  --text: #e8eefc;
  --muted: #a8b3cf;
  --border: rgba(255, 255, 255, 0.1);
  --accent: #5b8cff;
}
html,
body {
  background: var(--bg);
  color: var(--text);
  margin: 0;
  font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica,
    Arial, "Apple Color Emoji", "Segoe UI Emoji";
}
a {
  color: inherit;
  text-decoration: none;
}
.container {
  max-width: 1100px;
  margin: 0 auto;
  padding: 18px;
}
.panel {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 14px;
}
.btn {
  appearance: none;
  border: 1px solid var(--border);
  background: rgba(255, 255, 255, 0.06);
  color: var(--text);
  border-radius: 12px;
  padding: 10px 12px;
  cursor: pointer;
}
.btnPrimary {
  background: var(--accent);
  border-color: transparent;
  color: #081022;
  font-weight: 650;
}
.input {
  width: 100%;
  box-sizing: border-box;
  border: 1px solid var(--border);
  background: rgba(255, 255, 255, 0.05);
  color: var(--text);
  border-radius: 12px;
  padding: 10px 12px;
}
.muted {
  color: var(--muted);
}
</style>

