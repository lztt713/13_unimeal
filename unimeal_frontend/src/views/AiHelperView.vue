<script setup>
import { ref } from 'vue'
import RecipeCard from '../components/RecipeCard.vue'
import { api } from '../services/api'

const query = ref('')
const result = ref(null)
const loading = ref(false)
const error = ref('')
const examples = [
  'Vegetarian meals under $5',
  'Quick dinners with rice',
  'High protein meals under 30 minutes',
]
async function ask() {
  if (!query.value.trim()) return
  error.value = ''
  loading.value = true
  try {
    result.value = await api.getAiRecommendation(query.value)
  } catch {
    error.value = 'The assistant could not prepare a suggestion. Please try again.'
  } finally {
    loading.value = false
  }
}

function useExample(example) {
  query.value = example
  ask()
}
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div class="ai-intro text-center mx-auto">
        <p class="eyebrow">UniMeal AI helper</p>
        <h1 class="page-title">Tell us what you need.</h1>
        <p class="page-subtitle">
          Describe your budget, ingredients, dietary preferences or available time in everyday
          language.
        </p>
      </div>
      <form class="ai-search surface-card p-2 p-md-3 mt-4" @submit.prevent="ask">
        <div class="input-group">
          <input
            v-model="query"
            class="form-control border-0 shadow-none py-2"
            placeholder="e.g. Vegetarian meals under $5 with rice"
            aria-label="Ask the AI helper"
          /><button class="btn btn-primary rounded-pill px-4" :disabled="loading">
            {{ loading ? 'Thinking...' : 'Ask UniMeal' }}
          </button>
        </div>
      </form>
      <div class="d-flex flex-wrap justify-content-center gap-2 mt-3">
        <button
          v-for="example in examples"
          :key="example"
          class="example-chip"
          type="button"
          @click="useExample(example)"
        >
          {{ example }}
        </button>
      </div>
      <div v-if="error" class="alert alert-danger mx-auto mt-4 ai-content">{{ error }}</div>
      <div v-else-if="loading" class="py-5 text-center text-secondary">
        Preparing a student-friendly suggestion...
      </div>
      <section v-else-if="result" class="ai-content mt-5">
        <article class="surface-card p-4 p-md-5">
          <div class="d-flex flex-column flex-md-row justify-content-between gap-3">
            <div>
              <p class="eyebrow">Recipe suggestions</p>
              <h2 class="ai-heading">Your meal ideas</h2>
              <p class="text-secondary mb-0">{{ result.summary }}</p>
            </div>
            <span class="soft-badge align-self-md-start">UniMeal helper</span>
          </div>
          <div class="row g-4 mt-2">
            <div v-for="recipe in result.recipes" :key="recipe.id" class="col-md-6 col-xl-4">
              <RecipeCard :recipe="recipe" />
            </div>
          </div>
        </article>
        <article class="ai-caution surface-card p-4 mt-4">
          <h2 class="ai-heading">Before you decide</h2>
          <ul class="mb-0">
            <li v-for="caution in result.cautions" :key="caution">{{ caution }}</li>
          </ul>
        </article>
      </section>
      <section v-else class="empty-state ai-empty p-5 mt-5 mx-auto">
        <h2 class="h4 fw-bold">Need a meal idea?</h2>
        <p class="mb-0">
          Try describing a dietary need, budget, ingredient or available cooking time.
        </p>
      </section>
    </div>
  </section>
</template>

<style scoped>
.ai-intro {
  max-width: 46rem;
}
.ai-search {
  max-width: 50rem;
  margin-inline: auto;
}
.ai-search .form-control {
  min-width: 0;
}
.example-chip {
  border: 1px solid #d4dfd0;
  border-radius: 99px;
  padding: 0.45rem 0.75rem;
  color: var(--um-green);
  background: #fff;
  font-size: 0.8rem;
  font-weight: 700;
}
.example-chip:hover {
  background: var(--um-green-light);
}
.ai-content {
  max-width: 72rem;
  margin-inline: auto;
}
.ai-heading {
  color: var(--um-ink);
  font-size: 1.55rem;
  font-weight: 800;
}
.ai-caution {
  border-left: 4px solid var(--um-coral);
}
.ai-caution li {
  color: var(--um-muted);
  margin-top: 0.4rem;
}
.ai-empty {
  max-width: 42rem;
}
</style>
