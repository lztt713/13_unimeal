<script setup>
defineProps({ title: { type: String, default: 'Coming soon' }, description: { type: String, default: 'This UniMeal feature is being prepared.' } })
</script>

<template>
  <section class="page-shell"><div class="container"><div class="empty-state placeholder-card p-5 mx-auto"><div class="placeholder-mark mb-3" aria-hidden="true">✦</div><p class="eyebrow">UniMeal in progress</p><h1 class="page-title">{{ title }}</h1><p class="page-subtitle mx-auto">{{ description }}</p><RouterLink class="btn btn-primary rounded-pill px-4 mt-4" to="/dashboard">Back to dashboard</RouterLink></div></div></section>
</template>

<style scoped>
.placeholder-card { max-width: 42rem; margin-top: 3rem; } .placeholder-mark { display: grid; width: 3.4rem; height: 3.4rem; place-items: center; border-radius: 50%; color: var(--um-coral); background: #fff0ea; font-size: 1.5rem; margin-inline: auto; } .placeholder-card .page-subtitle { max-width: 32rem; }
</style>
