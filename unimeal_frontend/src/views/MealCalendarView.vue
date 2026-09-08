<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '../services/api'

const plan = ref({ entries: [] })
const recipes = ref([])
const loading = ref(true)
const loadError = ref(false)
const activeSlot = ref(null)
const selectedRecipeId = ref('')
const mealTypes = ['Breakfast', 'Lunch', 'Dinner']
const weekDays = computed(() => {
  const [year, month, day] = plan.value.weekStartDate.split('-').map(Number)
  return Array.from({ length: 7 }, (_, offset) => {
    const date = new Date(year, month - 1, day + offset)
    const dateKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
    return {
      date: dateKey,
      label: date.toLocaleDateString('en-NZ', { weekday: 'short' }),
      number: date.getDate(),
      isToday: date.toDateString() === new Date().toDateString(),
    }
  })
})
const selectedRecipe = computed(() =>
  recipes.value.find((recipe) => recipe.id === Number(selectedRecipeId.value)),
)

onMounted(async () => {
  try {
    ;[plan.value, recipes.value] = await Promise.all([api.getMealPlan(), api.getRecipes()])
  } catch {
    loadError.value = true
  } finally {
    loading.value = false
  }
})
function entryFor(day, mealType) {
  return plan.value.entries.find(
    (entry) => entry.plannedDate === day.date && entry.mealType === mealType,
  )
}
function recipeFor(entry) {
  return recipes.value.find((recipe) => recipe.id === entry?.recipeId)
}
function openSlot(day, mealType) {
  const entry = entryFor(day, mealType)
  activeSlot.value = { day, mealType, entry }
  selectedRecipeId.value = entry?.recipeId || ''
}
async function saveSlot() {
  if (!selectedRecipeId.value) return
  plan.value = await api.saveMealPlanEntry({
    id: activeSlot.value.entry?.id,
    plannedDate: activeSlot.value.day.date,
    mealType: activeSlot.value.mealType,
    recipeId: Number(selectedRecipeId.value),
    plannedServings: 2,
  })
  activeSlot.value = null
}
async function removeSlot() {
  if (activeSlot.value.entry) plan.value = await api.removeMealPlanEntry(activeSlot.value.entry.id)
  activeSlot.value = null
}
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div
        class="d-flex flex-column flex-md-row justify-content-between align-items-md-end gap-3 mb-4"
      >
        <div>
          <p class="eyebrow">Student meal plan</p>
          <h1 class="page-title">Your week, at a glance.</h1>
          <p class="page-subtitle">Schedule a recipe for each meal slot and update it anytime.</p>
        </div>
        <RouterLink class="btn btn-outline-primary rounded-pill px-4" to="/recipes"
          >Browse recipes</RouterLink
        >
      </div>
      <div v-if="loading" class="py-5 text-center text-secondary">Loading your meal plan...</div>
      <div v-else-if="loadError" class="empty-state p-5">
        We could not load your meal plan. Please try again.
      </div>
      <template v-else
        ><div class="surface-card calendar-wrap">
          <div class="calendar-grid">
            <div class="calendar-corner"></div>
            <div
              v-for="day in weekDays"
              :key="day.date"
              class="day-heading"
              :class="{ today: day.isToday }"
            >
              <span>{{ day.label }}</span
              ><strong>{{ day.number }}</strong>
            </div>
            <template v-for="mealType in mealTypes" :key="mealType"
              ><div class="meal-label">{{ mealType }}</div>
              <div v-for="day in weekDays" :key="`${mealType}-${day.date}`" class="calendar-slot">
                <template v-if="entryFor(day, mealType)"
                  ><button class="planned-recipe" type="button" @click="openSlot(day, mealType)">
                    <img
                      :src="recipeFor(entryFor(day, mealType)).imageUrl"
                      :alt="recipeFor(entryFor(day, mealType)).title"
                    /><span>{{ recipeFor(entryFor(day, mealType)).title }}</span>
                  </button></template
                ><button
                  v-else
                  class="add-slot"
                  type="button"
                  :aria-label="`Add ${mealType} for ${day.label}`"
                  @click="openSlot(day, mealType)"
                >
                  +
                </button>
              </div></template
            >
          </div>
        </div>
        <div v-if="activeSlot" class="modal-backdrop-custom" @click.self="activeSlot = null">
          <section
            class="slot-modal surface-card"
            role="dialog"
            aria-modal="true"
            aria-labelledby="slot-title"
          >
            <button class="close-modal" type="button" aria-label="Close" @click="activeSlot = null">
              x
            </button>
            <p class="eyebrow">
              {{ activeSlot.day.label }} {{ activeSlot.day.number }} - {{ activeSlot.mealType }}
            </p>
            <h2 id="slot-title" class="form-heading">Choose a recipe</h2>
            <select v-model="selectedRecipeId" class="form-select mt-3">
              <option value="">Select a recipe</option>
              <option v-for="recipe in recipes" :key="recipe.id" :value="recipe.id">
                {{ recipe.title }} - ${{ recipe.estimatedCost.toFixed(2) }}
              </option>
            </select>
            <div v-if="selectedRecipe" class="chosen-recipe mt-3">
              <img :src="selectedRecipe.imageUrl" :alt="selectedRecipe.title" />
              <div>
                <strong>{{ selectedRecipe.title }}</strong
                ><span>{{ selectedRecipe.cookTime }} min · {{ selectedRecipe.difficulty }}</span>
              </div>
            </div>
            <div class="d-flex justify-content-between gap-2 mt-4">
              <button
                class="btn btn-link text-danger p-0"
                type="button"
                :disabled="!activeSlot.entry"
                @click="removeSlot"
              >
                Remove meal</button
              ><button
                class="btn btn-primary rounded-pill px-4"
                type="button"
                :disabled="!selectedRecipeId"
                @click="saveSlot"
              >
                Save meal
              </button>
            </div>
          </section>
        </div></template
      >
    </div>
  </section>
</template>

<style scoped>
.calendar-wrap {
  overflow-x: auto;
}
.calendar-grid {
  display: grid;
  grid-template-columns: 6.5rem repeat(7, minmax(8.5rem, 1fr));
  min-width: 66rem;
}
.calendar-grid > * {
  border-bottom: 1px solid var(--um-line);
  border-right: 1px solid var(--um-line);
}
.calendar-corner {
  background: #fbfaf6;
}
.day-heading {
  display: flex;
  min-height: 5.25rem;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 0.15rem;
  background: #fbfaf6;
}
.day-heading span,
.meal-label {
  color: var(--um-muted);
  font-size: 0.76rem;
  font-weight: 750;
  text-transform: uppercase;
}
.day-heading strong {
  color: var(--um-green);
  font-size: 1.25rem;
}
.meal-label {
  display: flex;
  align-items: center;
  justify-content: center;
  background: #fbfaf6;
}
.calendar-slot {
  min-height: 7rem;
  padding: 0.5rem;
  background: #fff;
}
.add-slot {
  display: flex;
  width: 100%;
  height: 100%;
  min-height: 5.8rem;
  align-items: center;
  justify-content: center;
  border: 1px dashed #d8ddd3;
  border-radius: 0.75rem;
  color: #94a18f;
  background: transparent;
  font-size: 1.4rem;
}
.add-slot:hover {
  border-color: var(--um-green);
  color: var(--um-green);
  background: #f5f8f2;
}
.planned-recipe {
  display: block;
  width: 100%;
  overflow: hidden;
  border: 0;
  border-radius: 0.75rem;
  color: var(--um-ink);
  background: #f3f6f0;
  text-align: left;
  font-size: 0.76rem;
  font-weight: 750;
}
.planned-recipe img {
  width: 100%;
  height: 3.9rem;
  object-fit: cover;
}
.planned-recipe span {
  display: block;
  padding: 0.45rem;
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
.slot-modal {
  position: relative;
  width: min(100%, 32rem);
  padding: 2rem;
}
.close-modal {
  position: absolute;
  top: 1rem;
  right: 1rem;
  border: 0;
  color: var(--um-muted);
  background: transparent;
  font-size: 1.25rem;
}
.form-heading {
  color: var(--um-ink);
  font-weight: 800;
}
.chosen-recipe {
  display: flex;
  gap: 0.75rem;
  align-items: center;
  padding: 0.75rem;
  border-radius: 0.75rem;
  background: #f5f7f2;
}
.chosen-recipe img {
  width: 4rem;
  height: 3rem;
  border-radius: 0.5rem;
  object-fit: cover;
}
.chosen-recipe strong,
.chosen-recipe span {
  display: block;
}
.chosen-recipe span {
  color: var(--um-muted);
  font-size: 0.8rem;
}
</style>
