<script setup>
import { computed, onMounted, ref } from 'vue'
import RecipeCard from '../components/RecipeCard.vue'
import { api } from '../services/api'

const recipes = ref([])
const currentUser = ref(null)
const loading = ref(true)
const search = ref('')
const filters = ref({
  price: 'all',
  cuisine: 'all',
  difficulty: 'all',
  dietary: 'all',
  cookTime: 'all',
})
const filterOpen = ref(false)
const cuisines = computed(() => [...new Set(recipes.value.map((recipe) => recipe.cuisine))])
const filteredRecipes = computed(() =>
  recipes.value.filter((recipe) => {
    const needle = search.value.trim().toLowerCase()
    const searchable = [recipe.title, recipe.cuisine, ...recipe.ingredients, ...recipe.dietaryTags]
      .join(' ')
      .toLowerCase()
    const priceMatch =
      filters.value.price === 'all' ||
      (filters.value.price === 'under-4' ? recipe.estimatedCost < 4 : recipe.estimatedCost < 6)
    const timeMatch =
      filters.value.cookTime === 'all' ||
      (filters.value.cookTime === 'under-20' ? recipe.cookTime < 20 : recipe.cookTime <= 30)
    return (
      (!needle || searchable.includes(needle)) &&
      priceMatch &&
      (filters.value.cuisine === 'all' || recipe.cuisine === filters.value.cuisine) &&
      (filters.value.difficulty === 'all' || recipe.difficulty === filters.value.difficulty) &&
      (filters.value.dietary === 'all' || recipe.dietaryTags.includes(filters.value.dietary)) &&
      timeMatch
    )
  }),
)
const clearFilters = () => {
  search.value = ''
  filters.value = {
    price: 'all',
    cuisine: 'all',
    difficulty: 'all',
    dietary: 'all',
    cookTime: 'all',
  }
}
function allergyWarnings(recipe) {
  const allergies = currentUser.value?.allergies || []
  return (recipe.allergenTags || []).filter((tag) =>
    allergies.some((allergy) => allergy.toLowerCase() === tag.toLowerCase()),
  )
}
onMounted(async () => {
  try {
    const [recipeData, user] = await Promise.all([api.getRecipes(), api.getCurrentUser()])
    recipes.value = recipeData
    currentUser.value = user
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div class="text-center mx-auto intro mb-4 mb-md-5">
        <p class="eyebrow">Recipe library</p>
        <h1 class="page-title">Find your next favourite.</h1>
        <p class="page-subtitle">Affordable ideas made for busy student schedules.</p>
      </div>
      <div class="search-panel surface-card p-2 p-md-3 mb-4">
        <div class="input-group">
          <span class="input-group-text bg-transparent border-0 ps-3" aria-hidden="true">⌕</span
          ><input
            v-model="search"
            class="form-control border-0 shadow-none py-2"
            type="search"
            placeholder="Search recipes, ingredients or cuisines"
            aria-label="Search recipes"
          /><RouterLink
            v-if="currentUser?.role === 'contributor'"
            class="btn btn-primary rounded-pill px-4"
            to="/submit-recipe"
            >Add recipe</RouterLink
          >
        </div>
      </div>
      <button
        class="btn btn-outline-primary d-lg-none w-100 mb-3"
        type="button"
        :aria-expanded="filterOpen"
        @click="filterOpen = !filterOpen"
      >
        {{ filterOpen ? 'Hide filters' : 'Show filters' }}
      </button>
      <div class="row g-4">
        <aside class="col-lg-3" :class="{ 'd-none d-lg-block': !filterOpen }">
          <div class="surface-card filter-card p-4">
            <div class="d-flex justify-content-between align-items-center mb-4">
              <h2>Filters</h2>
              <button class="btn btn-link p-0 clear-button" type="button" @click="clearFilters">
                Clear all
              </button>
            </div>
            <label class="form-label">Price per serving</label
            ><select v-model="filters.price" class="form-select mb-4">
              <option value="all">Any price</option>
              <option value="under-4">Under $4</option>
              <option value="under-6">Under $6</option></select
            ><label class="form-label">Cuisine</label
            ><select v-model="filters.cuisine" class="form-select mb-4">
              <option value="all">All cuisines</option>
              <option v-for="cuisine in cuisines" :key="cuisine" :value="cuisine">
                {{ cuisine }}
              </option></select
            ><label class="form-label">Difficulty</label
            ><select v-model="filters.difficulty" class="form-select">
              <option value="all">Any difficulty</option>
              <option>Easy</option>
              <option>Medium</option>
            </select>
            <label class="form-label mt-4">Dietary preference</label>
            <select v-model="filters.dietary" class="form-select">
              <option value="all">Any preference</option>
              <option>Vegetarian</option>
              <option>Vegan</option>
              <option>Gluten Free</option>
              <option>High Protein</option>
            </select>
            <label class="form-label mt-4">Cooking time</label>
            <select v-model="filters.cookTime" class="form-select">
              <option value="all">Any time</option>
              <option value="under-20">Under 20 minutes</option>
              <option value="under-30">30 minutes or less</option>
            </select>
          </div>
        </aside>
        <div class="col-lg-9">
          <div class="d-flex justify-content-between align-items-center mb-3">
            <p class="results-count mb-0">
              {{ filteredRecipes.length }} recipe{{ filteredRecipes.length === 1 ? '' : 's' }} found
            </p>
            <span class="soft-badge">Student-friendly</span>
          </div>
          <div v-if="loading" class="py-5 text-center text-secondary">Loading recipes…</div>
          <div v-else-if="filteredRecipes.length" class="row g-4">
            <div v-for="recipe in filteredRecipes" :key="recipe.id" class="col-md-6 col-xl-4">
              <RecipeCard :recipe="recipe" :allergy-warnings="allergyWarnings(recipe)" />
            </div>
          </div>
          <div v-else class="empty-state p-5">
            <h2 class="h5 fw-bold mb-2">No recipes match that search.</h2>
            <p class="mb-3">Try a broader keyword or clear your filters.</p>
            <button
              class="btn btn-outline-primary rounded-pill px-4"
              type="button"
              @click="clearFilters"
            >
              Clear filters
            </button>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.intro {
  max-width: 44rem;
}

.search-panel {
  max-width: 52rem;
  margin-inline: auto;
}

.input-group-text {
  color: var(--um-green);
  font-size: 1.35rem;
}

.form-control:focus {
  box-shadow: none;
}

.filter-card h2 {
  margin: 0;
  color: var(--um-ink);
  font-size: 1.1rem;
  font-weight: 800;
}

.form-label {
  color: var(--um-ink);
  font-size: 0.82rem;
  font-weight: 750;
}

.form-select {
  border-color: var(--um-line);
  border-radius: 0.7rem;
  color: #526050;
  font-size: 0.9rem;
  padding: 0.65rem 0.8rem;
}

.form-select:focus {
  border-color: var(--um-green);
  box-shadow: 0 0 0 0.2rem rgba(49, 87, 44, 0.12);
}

.clear-button {
  color: var(--um-coral);
  font-size: 0.78rem;
  font-weight: 750;
  text-decoration: none;
}

.results-count {
  color: var(--um-muted);
  font-size: 0.9rem;
  font-weight: 650;
}
</style>
