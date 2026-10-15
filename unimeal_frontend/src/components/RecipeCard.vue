<script setup>
defineProps({
  recipe: { type: Object, required: true },
  allergyWarnings: { type: Array, default: () => [] },
})
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
        <span class="rating"
          >★ {{ recipe.rating }} <small>({{ recipe.reviewCount }})</small></span
        >
      </div>
      <h2 class="recipe-card-title">{{ recipe.title }}</h2>
      <div class="d-flex gap-3 mt-3 recipe-meta">
        <span>{{ recipe.cookTime }} min</span><span>{{ recipe.difficulty }}</span>
      </div>
      <div class="mt-3 d-flex flex-wrap gap-1">
        <span v-for="tag in recipe.dietaryTags" :key="tag" class="diet-tag">{{ tag }}</span>
      </div>
      <p v-if="allergyWarnings.length" class="allergy-warning mb-0 mt-3">
        Allergy warning: contains {{ allergyWarnings.join(', ') }}
      </p>
      <RouterLink class="stretched-link" :to="`/recipes/${recipe.id}`"
        ><span class="visually-hidden">View {{ recipe.title }}</span></RouterLink
      >
    </div>
  </article>
</template>

<style scoped>
/* Position the stretched detail link over the whole card and animate hover feedback. */
.recipe-card {
  position: relative;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
}

.recipe-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 15px 35px rgba(50, 68, 47, 0.12);
}

/* Reserve a fixed image area so recipe cards align in the grid. */
.recipe-card-image {
  height: 11.5rem;
  overflow: hidden;
}

/* Keep the estimated cost visible in the top-right corner of the image. */
.price-pill {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  border-radius: 99px;
  padding: 0.32rem 0.6rem;
  color: #fff;
  background: rgba(36, 48, 36, 0.88);
  font-size: 0.78rem;
  font-weight: 800;
}

/* Recipe title and rating metadata use the primary visual hierarchy. */
.recipe-card-title {
  margin: 0;
  color: var(--um-ink);
  font-size: 1.08rem;
  font-weight: 800;
  letter-spacing: -0.025em;
}

.rating {
  color: #a65f10;
  font-size: 0.82rem;
  font-weight: 750;
}

.rating small {
  color: var(--um-muted);
  font-weight: 600;
}

/* Time and difficulty form the compact cooking metadata row. */
.recipe-meta {
  color: var(--um-muted);
  font-size: 0.83rem;
  font-weight: 650;
}

/* Dietary tags appear as neutral pill labels below recipe metadata. */
.diet-tag {
  border-radius: 99px;
  padding: 0.2rem 0.48rem;
  color: #6b7167;
  background: #f2f0ea;
  font-size: 0.7rem;
  font-weight: 700;
}

.allergy-warning {
  color: #8a4b08;
  font-size: 0.78rem;
  font-weight: 700;
}
</style>
