<script setup>
import { computed, onMounted, ref } from 'vue'
import RecipeCard from '../components/RecipeCard.vue'
import { api } from '../services/api'

const data = ref(null)
const loading = ref(true)
const error = ref(false)

const budgetPercent = computed(() => data.value ? Math.min(100, (data.value.spent / data.value.weeklyBudget) * 100) : 0)
const remaining = computed(() => data.value ? data.value.weeklyBudget - data.value.spent : 0)

onMounted(async () => {
  try { data.value = await api.getDashboard() } catch { error.value = true } finally { loading.value = false }
})
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div class="d-flex flex-column flex-md-row align-items-md-end justify-content-between gap-3 mb-4 mb-md-5">
        <div>
          <p class="eyebrow">Your student kitchen</p>
          <h1 class="page-title">Good evening<span v-if="data">, {{ data.student.name }}</span>.</h1>
          <p class="page-subtitle">A calm plan for delicious meals and a happier wallet.</p>
        </div>
        <RouterLink class="btn btn-primary rounded-pill px-4 py-2" to="/calendar">Plan my week</RouterLink>
      </div>

      <div v-if="loading" class="py-5 text-center text-secondary">Loading your meal plan…</div>
      <div v-else-if="error" class="empty-state p-5">We could not load your dashboard. Please try again.</div>
      <template v-else>
        <div class="row g-4 align-items-stretch">
          <div class="col-lg-8">
            <article class="surface-card dinner-card h-100">
              <div class="row g-0 h-100">
                <div class="col-md-6 dinner-image-wrap"><img class="recipe-image" :src="data.tonight.imageUrl" :alt="data.tonight.title" /></div>
                <div class="col-md-6 p-4 p-xl-5 d-flex flex-column justify-content-center">
                  <p class="eyebrow">Tonight's dinner</p>
                  <h2>{{ data.tonight.title }}</h2>
                  <p class="text-muted mb-4">A tasty, low-stress dinner that fits your plan.</p>
                  <div class="d-flex flex-wrap gap-2 mb-4"><span class="soft-badge">{{ data.tonight.cookTime }} min</span><span class="soft-badge">${{ data.tonight.estimatedCost.toFixed(2) }}</span><span class="soft-badge">{{ data.tonight.difficulty }}</span></div>
                  <div class="d-flex flex-wrap gap-2"><RouterLink class="btn btn-primary rounded-pill px-4" :to="`/recipes/${data.tonight.id}`">View recipe</RouterLink><button class="btn btn-outline-primary rounded-pill px-4" type="button">Replace</button></div>
                </div>
              </div>
            </article>
          </div>
          <div class="col-lg-4">
            <article class="surface-card budget-card h-100 p-4 p-xl-5">
              <div class="d-flex justify-content-between align-items-start mb-4"><div><p class="eyebrow">Weekly budget</p><h2 class="mb-0">${{ remaining.toFixed(2) }} <span>left</span></h2></div><span class="budget-icon" aria-hidden="true">$</span></div>
              <div class="d-flex justify-content-between small fw-semibold mb-2"><span>${{ data.spent.toFixed(2) }} spent</span><span>${{ data.weeklyBudget.toFixed(2) }} budget</span></div>
              <div class="progress mb-4" role="progressbar" aria-label="Weekly budget used" :aria-valuenow="budgetPercent" aria-valuemin="0" aria-valuemax="100"><div class="progress-bar" :style="{ width: `${budgetPercent}%` }"></div></div>
              <p class="budget-note mb-0">You have {{ Math.round(100 - budgetPercent) }}% of your weekly food budget remaining.</p>
            </article>
          </div>
        </div>

        <section class="mt-5 pt-2">
          <div class="d-flex align-items-end justify-content-between mb-4"><div><p class="eyebrow">Keep cooking</p><h2 class="section-title">Recent favourites</h2></div><RouterLink class="text-link" to="/recipes">Explore recipes →</RouterLink></div>
          <div v-if="data.favourites.length" class="row g-4"><div v-for="recipe in data.favourites" :key="recipe.id" class="col-sm-6 col-lg-4"><RecipeCard :recipe="recipe" /></div></div>
          <div v-else class="empty-state p-5">Save a recipe and it will appear here.</div>
        </section>
      </template>
    </div>
  </section>
</template>

<style scoped>
.dinner-card { min-height: 22rem; } .dinner-image-wrap { min-height: 14rem; } .dinner-card h2, .budget-card h2, .section-title { color: var(--um-ink); font-weight: 800; letter-spacing: -.045em; } .dinner-card h2 { font-size: clamp(1.7rem, 3vw, 2.3rem); } .budget-card h2 { font-size: 2.25rem; } .budget-card h2 span { color: var(--um-muted); font-size: 1rem; font-weight: 650; letter-spacing: 0; } .budget-icon { display: grid; width: 2.5rem; height: 2.5rem; place-items: center; border-radius: 50%; color: var(--um-green); background: var(--um-green-light); font-size: 1.2rem; font-weight: 800; } .progress { height: .6rem; border-radius: 99px; background: #e9ece5; } .progress-bar { border-radius: 99px; background: var(--um-coral); } .budget-note { color: var(--um-muted); font-size: .9rem; line-height: 1.55; } .section-title { margin: 0; font-size: 1.65rem; } .text-link { color: var(--um-green); font-size: .9rem; font-weight: 800; } .text-link:hover { color: var(--um-coral); } @media (max-width: 767.98px) { .dinner-image-wrap { height: 13rem; } }
</style>
