<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../services/api'

const recipes = ref([])
const loading = ref(true)
// Track the recipe being published, unpublished or deleted to disable only its controls.
const busyId = ref(null)

async function loadRecipes() {
  // Reload after each mutation so published status remains server-authoritative.
  loading.value = true
  try {
    recipes.value = await api.getMyRecipes()
  } finally {
    loading.value = false
  }
}

async function togglePublication(recipe) {
  // One API method switches between Draft and Published based on current server data.
  busyId.value = recipe.id
  try {
    await api.toggleRecipePublication(recipe.id)
    await loadRecipes()
  } finally {
    busyId.value = null
  }
}

async function removeRecipe(recipe) {
  // Confirm a destructive action before permanently deleting a contributor recipe.
  if (!window.confirm(`Delete “${recipe.title}”?`)) return
  busyId.value = recipe.id
  try {
    await api.deleteMyRecipe(recipe.id)
    await loadRecipes()
  } finally {
    busyId.value = null
  }
}

onMounted(loadRecipes)
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div
        class="d-flex flex-column flex-md-row justify-content-between align-items-md-end gap-3 mb-4"
      >
        <div>
          <p class="eyebrow">Recipe contributor</p>
          <h1 class="page-title">My recipes.</h1>
          <p class="page-subtitle">
            Create, revise and control whether your recipes are visible to students.
          </p>
        </div>
        <RouterLink class="btn btn-primary rounded-pill px-4" to="/submit-recipe"
          >Add a recipe</RouterLink
        >
      </div>
      <div v-if="loading" class="py-5 text-center text-secondary">Loading your recipes...</div>
      <div v-else-if="!recipes.length" class="empty-state p-5 text-center">
        <h2 class="h4 fw-bold">No recipes yet</h2>
        <p class="text-secondary">Share your first student-friendly recipe.</p>
        <RouterLink class="btn btn-primary rounded-pill" to="/submit-recipe"
          >Create recipe</RouterLink
        >
      </div>
      <div v-else class="row g-4">
        <!-- Each recipe card exposes the contributor's three lifecycle actions. -->
        <article v-for="recipe in recipes" :key="recipe.id" class="col-md-6 col-xl-4">
          <div class="surface-card h-100 overflow-hidden">
            <img
              class="recipe-image contributor-image"
              :src="recipe.imageUrl"
              :alt="recipe.title"
            />
            <div class="p-4">
              <div class="d-flex justify-content-between gap-2">
                <span class="soft-badge">{{ recipe.cuisine }}</span
                ><span
                  class="status"
                  :class="recipe.status === 'Published' ? 'published' : 'draft'"
                  >{{ recipe.status || 'Published' }}</span
                >
              </div>
              <h2 class="contributor-title mt-3">{{ recipe.title }}</h2>
              <p class="text-secondary small">
                {{ recipe.ingredients.length }} ingredients ·
                {{ recipe.prepTime + recipe.cookTime }} min
              </p>
              <div class="d-flex flex-wrap gap-2 mt-3">
                <!-- Reuse the submission form with an edit query parameter. -->
                <RouterLink
                  class="btn btn-outline-primary btn-sm rounded-pill"
                  :to="`/submit-recipe?edit=${recipe.id}`"
                  >Edit</RouterLink
                >
                <!-- Publishing changes whether students can discover the recipe. -->
                <button
                  class="btn btn-outline-primary btn-sm rounded-pill"
                  :disabled="busyId === recipe.id"
                  @click="togglePublication(recipe)"
                >
                  {{ recipe.status === 'Published' ? 'Unpublish' : 'Publish' }}</button
                >
                <!-- Delete uses a confirmation dialog before making the irreversible request. -->
                <button
                  class="btn btn-link btn-sm text-danger"
                  :disabled="busyId === recipe.id"
                  @click="removeRecipe(recipe)"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        </article>
      </div>
    </div>
  </section>
</template>

<style scoped>
.contributor-image {
  /* Fixed card image height keeps contributor recipe cards aligned in their grid. */
  height: 11rem;
}
.contributor-title {
  /* Recipe titles use the primary content hierarchy within each contributor card. */
  color: var(--um-ink);
  font-size: 1.3rem;
  font-weight: 800;
}
.status {
  /* Status pills distinguish published recipes from private drafts. */
  border-radius: 99px;
  padding: 0.3rem 0.55rem;
  font-size: 0.72rem;
  font-weight: 800;
}
.published {
  color: var(--um-green);
  background: var(--um-green-light);
}
.draft {
  color: #9c5a0c;
  background: #fff0d7;
}
</style>
