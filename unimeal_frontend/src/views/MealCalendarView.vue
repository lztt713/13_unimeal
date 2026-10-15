<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../services/api'

const plan = ref({ entries: [] })
const recipes = ref([])
const loading = ref(true)
const loadError = ref(false)
const selectedWeekStart = ref('')
// The calendar slot currently open in the recipe selection dialog.
const activeSlot = ref(null)
// Store the selected ID separately so the full recipe can be resolved from the loaded list.
const selectedRecipeId = ref('')
// A new meal defaults to one serving; existing entries keep their saved amount.
const plannedServings = ref(1)
const mealTypes = ['Breakfast', 'Lunch', 'Dinner']
const isEmptyPlan = computed(() => !plan.value.entries.length)
const route = useRoute()
const router = useRouter()
const requestedRecipeId = computed(() => {
  const value = Number(route.query.recipe)
  return Number.isInteger(value) && value > 0 ? value : null
})
// A recipe can be passed from its detail page through the calendar query string.
const recipeToPlan = computed(() =>
  recipes.value.find((recipe) => recipe.id === requestedRecipeId.value) || null,
)

// Generate seven local calendar days without timezone-related date shifts.
const weekDays = computed(() => {
  // Parse the API's YYYY-MM-DD value as local components to avoid timezone shifts.
  const [year, month, day] = plan.value.weekStartDate.split('-').map(Number)
  return Array.from({ length: 7 }, (_, offset) => {
    // JavaScript month indexes start at zero, so subtract one from the API month.
    const date = new Date(year, month - 1, day + offset)
    const dateKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
    return {
      date: dateKey, // e.g. "2026-09-18"
      label: date.toLocaleDateString('en-NZ', { weekday: 'short' }), // e.g. "Mon"
      number: date.getDate(), // e.g. 18
      // Highlight the current local day rather than comparing UTC timestamps.
      isToday: date.toDateString() === new Date().toDateString(),
    }
  })
})
const selectedRecipe = computed(() =>
  recipes.value.find((recipe) => recipe.id === Number(selectedRecipeId.value)),
)

// Request the selected week from the backend, then use its returned week boundary.
async function loadMealPlan(weekStart) {
  plan.value = await api.getMealPlan(weekStart)
  selectedWeekStart.value = plan.value.weekStartDate
}

// Format calendar dates in the API's YYYY-MM-DD format.
function formatDateKey(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

async function showThisWeek() {
  await loadMealPlan()
}

async function showNextWeek() {
  const [year, month, day] = selectedWeekStart.value.split('-').map(Number)
  await loadMealPlan(formatDateKey(new Date(year, month - 1, day + 7)))
}

onMounted(async () => {
  try {
    const [mealPlan, recipeList] = await Promise.all([api.getMealPlan(), api.getRecipes()])
    plan.value = mealPlan
    selectedWeekStart.value = mealPlan.weekStartDate
    recipes.value = recipeList
  } catch {
    loadError.value = true
  } finally {
    loading.value = false
  }
})
function entryFor(day, mealType) {
  // Find the saved entry that belongs to this date and meal type.
  return plan.value.entries.find(
    (entry) => entry.plannedDate === day.date && entry.mealType === mealType,
  )
}
function recipeFor(entry) {
  // Entries only contain a recipe ID, so resolve the display information here.
  return recipes.value.find((recipe) => recipe.id === entry?.recipeId)
}
function openSlot(day, mealType) {
  // Load the existing entry when editing, otherwise prepare a new empty slot.
  const entry = entryFor(day, mealType)
  activeSlot.value = { day, mealType, entry }
  // Preselect a recipe passed from the recipe-detail page when the slot is empty.
  selectedRecipeId.value = entry?.recipeId || recipeToPlan.value?.id || ''
  plannedServings.value = entry?.plannedServings || 1
}
async function saveSlot() {
  // The save button is disabled without a recipe, but keep this guard for safety.
  if (!selectedRecipeId.value) return
  plan.value = await api.saveMealPlanEntry({
    id: activeSlot.value.entry?.id,
    plannedDate: activeSlot.value.day.date,
    mealType: activeSlot.value.mealType,
    recipeId: Number(selectedRecipeId.value),
    plannedServings: plannedServings.value,
  })
  activeSlot.value = null
  // Remove the query parameter once the recipe-detail shortcut has been saved.
  if (recipeToPlan.value) await router.replace('/calendar')
}
async function clearRecipeToPlan() {
  await router.replace('/calendar')
}
async function removeSlot() {
  // Avoid a delete request when the selected slot has no persisted entry.
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
        <div class="d-flex flex-wrap gap-2">
          <button class="btn btn-outline-primary rounded-pill px-3" type="button" @click="showThisWeek">
            This week
          </button>
          <button class="btn btn-outline-primary rounded-pill px-3" type="button" @click="showNextWeek">
            Next week
          </button>
          <RouterLink class="btn btn-primary rounded-pill px-4" to="/recipes">Browse recipes</RouterLink>
        </div>
      </div>
      <div v-if="loading" class="py-5 text-center text-secondary">Loading your meal plan...</div>
      <div v-else-if="loadError" class="empty-state p-5">
        We could not load your meal plan. Please try again.
      </div>
      <template v-else>
        <!-- A recipe selected on its detail page is preloaded for the next chosen slot. -->
        <section v-if="recipeToPlan" class="calendar-tip mb-4">
          <p class="eyebrow mb-1">Ready to plan</p>
          <strong>{{ recipeToPlan.title }} is selected.</strong>
          <span>Click any + to choose its date and meal type.</span>
          <button class="btn btn-outline-primary btn-sm rounded-pill" type="button" @click="clearRecipeToPlan">
            Choose a different recipe
          </button>
        </section>
        <section v-else-if="isEmptyPlan" class="calendar-tip mb-4">
          <p class="eyebrow mb-1">Your first meal plan</p>
          <strong>Click a +, choose a recipe and servings, then save.</strong>
          <span>Your shopping list updates automatically after you add meals.</span>
        </section>
        <!-- The calendar is a seven-column grid and scrolls horizontally on narrow screens. -->
        <div class="surface-card calendar-wrap">
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
            <template v-for="mealType in mealTypes" :key="mealType">
              <div class="meal-label">{{ mealType }}</div>
              <div v-for="day in weekDays" :key="`${mealType}-${day.date}`" class="calendar-slot">
                <template v-if="entryFor(day, mealType)"
                  ><button class="planned-recipe" type="button" @click="openSlot(day, mealType)">
                    <img
                      :src="recipeFor(entryFor(day, mealType)).imageUrl"
                      :alt="recipeFor(entryFor(day, mealType)).title"
                    /><span>{{ recipeFor(entryFor(day, mealType)).title }}</span>
                  </button>
                </template>
                <button
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
        <!-- This modal handles both creating a meal and editing an existing meal. -->
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
            <div v-if="selectedRecipe" class="mt-3">
              <label class="form-label" for="servings">Servings</label>
              <input
                id="servings"
                v-model.number="plannedServings"
                class="form-control"
                type="number"
                min="1"
                max="10"
              />
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
/* Keep the full seven-day grid usable on smaller screens. */
.calendar-wrap {
  overflow-x: auto;
}
.calendar-tip {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem 0.85rem;
  padding: 1rem 1.25rem;
  border-left: 4px solid var(--um-green);
  border-radius: 0.5rem;
  background: var(--um-green-light);
  color: var(--um-ink);
}
.calendar-tip .eyebrow {
  width: 100%;
}
.calendar-tip span {
  color: var(--um-muted);
}
/* The first column holds meal labels; the remaining seven columns are days. */
.calendar-grid {
  display: grid;
  grid-template-columns: 6.5rem repeat(7, minmax(8.5rem, 1fr));
  min-width: 66rem;
}
/* Draw a consistent table-like border around every grid cell. */
.calendar-grid > * {
  border-bottom: 1px solid var(--um-line);
  border-right: 1px solid var(--um-line);
}
.calendar-corner {
  background: #fbfaf6;
}
/* Day headings and the current-day highlight. */
.day-heading {
  display: flex;
  min-height: 5.25rem;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 0.15rem;
  background: #fbfaf6;
}
.day-heading.today {
  background: var(--um-green-light);
}
.day-heading.today strong {
  color: var(--um-coral);
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
/* Meal-type labels on the left edge of the grid. */
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
/* Empty slots use a dashed button to invite the user to add a meal. */
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
/* A planned recipe appears as a compact, clickable recipe card. */
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
