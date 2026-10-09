<script setup>
import { computed, onMounted, ref } from 'vue'
import RecipeCard from '../components/RecipeCard.vue'
import { api } from '../services/api'

const query = ref('')  // 用户输入的查询文字
const result = ref(null)
const loading = ref(false)
const error = ref('')
const profile = ref(null)
const examples = [
  'Vegetarian meals under $5',
  'Quick dinners with rice',
  'High protein meals under 30 minutes',
]
// 把用户的饮食偏好和菜系拼成一个数组，展示在页面下方
const savedPreferences = computed(() => [
  ...(profile.value?.dietaryPreferences || []),
  ...(profile.value?.favouriteCuisines || []).map((cuisine) => `Likes ${cuisine}`),
])

onMounted(async () => {
  try {
    profile.value = await api.getCurrentUser()
  } catch {
    profile.value = null
  }
})
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

async function smartSearch() {
  if (!query.value.trim()) return

  error.value = ''
  loading.value = true

  try {
    const recipes = await api.smartSearch(query.value)

    result.value = {
      query: query.value,
      mode: 'smart-search',
      summary: `Found ${recipes.length} recipe(s) matching your request.`,
      recipes,
      cautions: [
        'Smart search uses your budget, dietary tag, cooking time and ingredient keywords.',
      ],
    }
  } catch {
    error.value = 'Smart search could not find recipes. Please try another request.'
  } finally {
    loading.value = false
  }
}

function useExample(example) {
  query.value = example  // 填充输入框
  ask()  // 立即搜索
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
          /><button
            type="button"
            class="btn btn-outline-primary rounded-pill px-3"
            :disabled="loading"
            @click="smartSearch"
          >
            Smart search
          </button>

          <button type="submit" class="btn btn-primary rounded-pill px-4" :disabled="loading">
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
      <!-- 已保存偏好展示 -->
      <p v-if="savedPreferences.length" class="text-secondary small text-center mt-3 mb-0">
        Saved preferences: {{ savedPreferences.join(' · ') }}
      </p>
      <div v-if="error" class="alert alert-danger mx-auto mt-4 ai-content">{{ error }}</div>
      <div v-else-if="loading" class="py-5 text-center text-secondary">
        Preparing a student-friendly suggestion...
      </div>
      <!-- 有结果 -->
      <section v-else-if="result" class="ai-content mt-5">
        <!-- 推荐卡片 + 注意事项 -->
        <article class="surface-card p-4 p-md-5">
          <div class="d-flex flex-column flex-md-row justify-content-between gap-3">
            <div>
              <p class="eyebrow">
                {{
                  result.mode === 'live'
                    ? 'Live AI recommendation'
                    : result.mode === 'smart-search'
                      ? 'Smart recipe search'
                      : result.mode === 'rule-based'
                        ? 'Rule-based recommendation'
                        : 'Database recommendation'
                }}
              </p>
              <h2 class="ai-heading">Your meal ideas</h2>
              <p class="text-secondary mb-0">{{ result.summary }}</p>
            </div>
            <span class="soft-badge align-self-md-start">
              {{
                result.mode === 'live'
                  ? 'Gemini'
                  : result.mode === 'smart-search'
                    ? 'Rule-based search'
                    : result.mode === 'rule-based'
                      ? 'Personalised ranking'
                      : 'Database fallback'
              }}
            </span>
          </div>
          <div v-if="result.recipes.length" class="row g-4 mt-2">
            <div v-for="recipe in result.recipes" :key="recipe.id" class="col-md-6 col-xl-4">
              <RecipeCard :recipe="recipe" />
            </div>
          </div>
          <div v-else class="ai-no-results mt-4">
            <h3 class="h5 fw-bold">No matching recipes yet.</h3>
            <p class="text-secondary mb-3">Try a broader request, or adjust the saved preferences that are filtering your results.</p>
            <RouterLink class="btn btn-outline-primary rounded-pill px-4" to="/profile">Edit preferences</RouterLink>
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
/* 搜索框容器 */
.ai-search {
  max-width: 50rem;
  margin-inline: auto;
}
.ai-search .form-control {
  min-width: 0;
}
/* 3 个示例胶囊。悬停时背景变浅绿 */
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
.ai-no-results {
  padding: 1.25rem;
  border-radius: 0.6rem;
  background: var(--um-green-light);
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
