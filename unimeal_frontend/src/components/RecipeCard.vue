<script setup>
defineProps({ recipe: { type: Object, required: true } })
</script>

<template>
  <article class="surface-card recipe-card h-100">
    <div class="recipe-card-image position-relative">
      <img class="recipe-image" :src="recipe.imageUrl" :alt="recipe.title" />
      <span class="price-pill">${{ recipe.estimatedCost.toFixed(2) }}</span>
    </div>
    <div class="p-3 p-md-4">
      <div class="d-flex align-items-center justify-content-between gap-2 mb-2">
        <span class="soft-badge">{{ recipe.cuisine }}</span>
        <span class="rating">★ {{ recipe.rating }} <small>({{ recipe.reviewCount }})</small></span>
      </div>
      <h2 class="recipe-card-title">{{ recipe.title }}</h2>
      <div class="d-flex gap-3 mt-3 recipe-meta"><span>{{ recipe.cookTime }} min</span><span>{{ recipe.difficulty }}</span></div>
      <div class="mt-3 d-flex flex-wrap gap-1"><span v-for="tag in recipe.dietaryTags" :key="tag" class="diet-tag">{{ tag }}</span></div>
      <RouterLink class="stretched-link" :to="`/recipes/${recipe.id}`"><span class="visually-hidden">View {{ recipe.title }}</span></RouterLink>
    </div>
  </article>
</template>

<style scoped>
.recipe-card { transition: transform .2s ease, box-shadow .2s ease; }
.recipe-card:hover { transform: translateY(-4px); box-shadow: 0 15px 35px rgba(50,68,47,.12); }
.recipe-card-image { height: 11.5rem; overflow: hidden; }
.price-pill { position: absolute; top: .75rem; right: .75rem; border-radius: 99px; padding: .32rem .6rem; color: #fff; background: rgba(36,48,36,.88); font-size: .78rem; font-weight: 800; }
.recipe-card-title { margin: 0; color: var(--um-ink); font-size: 1.08rem; font-weight: 800; letter-spacing: -.025em; }
.rating { color: #a65f10; font-size: .82rem; font-weight: 750; } .rating small { color: var(--um-muted); font-weight: 600; }
.recipe-meta { color: var(--um-muted); font-size: .83rem; font-weight: 650; }
.diet-tag { border-radius: 99px; padding: .2rem .48rem; color: #6b7167; background: #f2f0ea; font-size: .7rem; font-weight: 700; }
</style>
