<script setup>
import { computed, onMounted, ref } from 'vue'
import RecipeCard from '../components/RecipeCard.vue'
import { api } from '../services/api'

const data = ref(null)
const loading = ref(true)
const error = ref(false)
const recipes = ref([])
const currentUser = ref(null)
const replaceOpen = ref(false)
const selectedRecipeId = ref('')

const budgetPercent = computed(() =>
  data.value ? Math.min(100, (data.value.spent / data.value.weeklyBudget) * 100) : 0,
)
const remaining = computed(() => (data.value ? data.value.weeklyBudget - data.value.spent : 0))
const quickLinks = [
  {
    title: 'Browse recipes',
    description: 'Search and filter recipes by cost, cuisine, and difficulty.',
    to: '/recipes',
    action: 'Find recipes',
  },
  {
    title: 'Meal calendar',
    description: 'Add, replace, or remove meals from your weekly plan.',
    to: '/calendar',
    action: 'Open calendar',
  },
  {
    title: 'Shopping list',
    description: 'See combined ingredients and mark items as purchased.',
    to: '/shopping-list',
    action: 'Open list',
  },
  {
    title: 'Budget summary',
    description: 'Compare your weekly budget with planned spending.',
    to: '/budget',
    action: 'View budget',
  },
  {
    title: 'AI helper',
    description: 'Ask for a meal suggestion based on your needs.',
    to: '/ai-helper',
    action: 'Ask AI helper',
  },
  {
    title: 'My profile',
    description: 'Update your budget, dietary preferences, and kitchen details.',
    to: '/profile',
    action: 'Edit profile',
  },
]

onMounted(async () => {
  try {
    ;[data.value, recipes.value, currentUser.value] = await Promise.all([
      api.getDashboard(),
      api.getRecipes(),
      api.getCurrentUser(),
    ])
  } catch {
    error.value = true
  } finally {
    loading.value = false
  }
})

async function replaceDinner() {
  if (!selectedRecipeId.value) return
  const now = new Date()
  const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
  await api.saveMealPlanEntry({
    plannedDate: today,
    mealType: 'Dinner',
    recipeId: Number(selectedRecipeId.value),
    plannedServings: 2,
  })
  data.value = await api.getDashboard()
  replaceOpen.value = false
  selectedRecipeId.value = ''
}
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div
        class="d-flex flex-column flex-md-row align-items-md-end justify-content-between gap-3 mb-4 mb-md-5"
      >
        <div>
          <p class="eyebrow">Your student kitchen</p>
          <h1 class="page-title">
            Good evening<span v-if="currentUser">, {{ currentUser.displayName }}</span
            >.
          </h1>
          <p class="page-subtitle">A calm plan for delicious meals and a happier wallet.</p>
        </div>
        <RouterLink class="btn btn-primary rounded-pill px-4 py-2" to="/calendar"
          >Plan my week</RouterLink
        >
      </div>

      <div v-if="loading" class="py-5 text-center text-secondary">Loading your meal plan…</div>
      <div v-else-if="error" class="empty-state p-5">
        We could not load your dashboard. Please try again.
      </div>
      <template v-else>
        <div class="row g-4 align-items-stretch">
          <div class="col-lg-8">
            <article class="surface-card dinner-card h-100">
              <div class="row g-0 h-100">
                <div class="col-md-6 dinner-image-wrap">
                  <img
                    class="recipe-image"
                    :src="data.tonight.imageUrl"
                    :alt="data.tonight.title"
                  />
                </div>
                <div class="col-md-6 p-4 p-xl-5 d-flex flex-column justify-content-center">
                  <p class="eyebrow">Tonight's dinner</p>
                  <h2>{{ data.tonight.title }}</h2>
                  <p class="text-muted mb-4">A tasty, low-stress dinner that fits your plan.</p>
                  <div class="d-flex flex-wrap gap-2 mb-4">
                    <span class="soft-badge">{{ data.tonight.cookTime }} min</span
                    ><span class="soft-badge">${{ data.tonight.estimatedCost.toFixed(2) }}</span
                    ><span class="soft-badge">{{ data.tonight.difficulty }}</span>
                  </div>
                  <div class="d-flex flex-wrap gap-2">
                    <RouterLink
                      class="btn btn-primary rounded-pill px-4"
                      :to="`/recipes/${data.tonight.id}`"
                      >View recipe</RouterLink
                    ><button
                      class="btn btn-outline-primary rounded-pill px-4"
                      type="button"
                      @click="replaceOpen = true"
                    >
                      Replace
                    </button>
                  </div>
                </div>
              </div>
            </article>
          </div>
          <div class="col-lg-4">
            <article class="surface-card budget-card h-100 p-4 p-xl-5">
              <div class="d-flex justify-content-between align-items-start mb-4">
                <div>
                  <p class="eyebrow">Weekly budget</p>
                  <h2 class="mb-0">${{ remaining.toFixed(2) }} <span>left</span></h2>
                </div>
                <span class="budget-icon" aria-hidden="true">$</span>
              </div>
              <div class="d-flex justify-content-between small fw-semibold mb-2">
                <span>${{ data.spent.toFixed(2) }} spent</span
                ><span>${{ data.weeklyBudget.toFixed(2) }} budget</span>
              </div>
              <div
                class="progress mb-4"
                role="progressbar"
                aria-label="Weekly budget used"
                :aria-valuenow="budgetPercent"
                aria-valuemin="0"
                aria-valuemax="100"
              >
                <div class="progress-bar" :style="{ width: `${budgetPercent}%` }"></div>
              </div>
              <p class="budget-note mb-0">
                You have {{ Math.round(100 - budgetPercent) }}% of your weekly food budget
                remaining.
              </p>
            </article>
          </div>
        </div>

        <section class="mt-5 pt-2">
          <div class="d-flex align-items-end justify-content-between mb-4">
            <div>
              <p class="eyebrow">Keep cooking</p>
              <h2 class="section-title">Recent favourites</h2>
            </div>
            <RouterLink class="text-link" to="/recipes">Explore recipes →</RouterLink>
          </div>
          <div v-if="data.favourites.length" class="row g-4">
            <div v-for="recipe in data.favourites" :key="recipe.id" class="col-sm-6 col-lg-4">
              <RecipeCard :recipe="recipe" />
            </div>
          </div>
          <div v-else class="empty-state p-5">Save a recipe and it will appear here.</div>
        </section>

        <section class="mt-5 pt-2">
          <div class="mb-3">
            <h2 class="section-title">Plan and manage</h2>
            <p class="text-secondary mb-0">
              Use these pages to complete your weekly meal-planning tasks.
            </p>
          </div>
          <div class="row g-3">
            <div v-for="link in quickLinks" :key="link.to" class="col-md-6 col-lg-4">
              <article class="card h-100">
                <div class="card-body">
                  <h3 class="h5">{{ link.title }}</h3>
                  <p class="card-text text-secondary">{{ link.description }}</p>
                  <RouterLink class="btn btn-outline-primary btn-sm" :to="link.to">{{
                    link.action
                  }}</RouterLink>
                </div>
              </article>
            </div>
          </div>
        </section>
      </template>
      <div v-if="replaceOpen" class="modal-backdrop-custom" @click.self="replaceOpen = false">
        <section
          class="replace-modal surface-card"
          role="dialog"
          aria-modal="true"
          aria-labelledby="replace-title"
        >
          <button class="close-modal" type="button" aria-label="Close" @click="replaceOpen = false">
            ×
          </button>
          <p class="eyebrow">Tonight's dinner</p>
          <h2 id="replace-title" class="section-title">Choose a replacement</h2>
          <p class="text-secondary mt-2">
            This updates today's Dinner entry in your current meal plan.
          </p>
          <select v-model="selectedRecipeId" class="form-select mt-3">
            <option value="">Select a recipe</option>
            <option v-for="recipe in recipes" :key="recipe.id" :value="recipe.id">
              {{ recipe.title }} - ${{ recipe.estimatedCost.toFixed(2) }}
            </option>
          </select>
          <div class="d-flex justify-content-end gap-2 mt-4">
            <button
              class="btn btn-outline-primary rounded-pill px-4"
              type="button"
              @click="replaceOpen = false"
            >
              Cancel</button
            ><button
              class="btn btn-primary rounded-pill px-4"
              type="button"
              :disabled="!selectedRecipeId"
              @click="replaceDinner"
            >
              Save dinner
            </button>
          </div>
        </section>
      </div>
    </div>
  </section>
</template>

<style scoped>
/* ===== 卡片容器基础高度 ===== */
.dinner-card {
  min-height: 22rem;
  border-top: 3px solid var(--um-green);
}

.dinner-image-wrap {
  min-height: 14rem;
}

/* ===== 标题通用样式（共用选择器，分行写更清晰） ===== */
.dinner-card h2,
.budget-card h2,
.section-title {
  color: var(--um-ink);
  font-weight: 700;
}

/* ===== 晚餐卡片标题（响应式字体） ===== */
.dinner-card h2 {
  font-size: 2rem;
}

/* ===== 预算卡片标题 ===== */
.budget-card h2 {
  font-size: 2.25rem;
}

.budget-card h2 span {
  color: var(--um-muted);
  font-size: 1rem;
  font-weight: 650;
  letter-spacing: 0;
}

.budget-card {
  border-top: 3px solid var(--um-coral);
}

/* ===== 预算图标（圆形美元符号） ===== */
.budget-icon {
  display: flex;
  width: 2.5rem;
  height: 2.5rem;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  color: var(--um-green);
  background: var(--um-green-light);
  font-size: 1.2rem;
  font-weight: 800;
}

/* ===== 进度条背景轨道 ===== */
.progress {
  height: 0.6rem;
  border-radius: 0.375rem;
  background: #e9ece5;
}

/* ===== 进度条填充条 ===== */
.progress-bar {
  border-radius: 0.375rem;
  background: var(--um-green);
}

/* ===== 预算备注文字 ===== */
.budget-note {
  color: var(--um-muted);
  font-size: 0.9rem;
  line-height: 1.55;
}

/* ===== 区块标题 ===== */
.section-title {
  margin: 0;
  font-size: 1.5rem;
}

/* ===== 文字链接（“探索食谱”那种） ===== */
.text-link {
  color: var(--um-green);
  font-size: 0.9rem;
  font-weight: 800;
}

.text-link:hover {
  color: var(--um-coral);
}

.modal-backdrop-custom {
  position: fixed;
  z-index: 1050;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  background: rgba(30, 43, 28, 0.45);
}

.replace-modal {
  position: relative;
  width: min(100%, 32rem);
  padding: 2rem;
}

.card {
  border-color: var(--um-line);
  border-radius: 0.5rem;
  box-shadow: none;
}

.card h3 {
  color: var(--um-green);
}

.close-modal {
  position: absolute;
  top: 1rem;
  right: 1rem;
  border: 0;
  color: var(--um-muted);
  background: transparent;
  font-size: 1.4rem;
}

/* ===== 移动端适配（屏幕宽度小于 768px 时） ===== */
@media (max-width: 767.98px) {
  .dinner-image-wrap {
    height: 13rem;
  }
}
</style>
