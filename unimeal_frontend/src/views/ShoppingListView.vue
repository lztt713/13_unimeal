<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '../services/api'

const list = ref(null)
const loading = ref(true)
const loadError = ref(false)
const activeTab = ref('to-buy')
// The To buy tab is the default task-focused view for a shopping trip.
const isToBuyTab = computed(() => activeTab.value === 'to-buy')
const purchasedItems = computed(() => list.value?.items.filter((item) => item.purchased) || [])
const toBuyItems = computed(() => list.value?.items.filter((item) => !item.purchased) || [])
const visibleItems = computed(() => (isToBuyTab.value ? toBuyItems.value : purchasedItems.value))

// Group the active tab's items so the list remains easy to scan while shopping.
const groupedItems = computed(
  () =>
    visibleItems.value.reduce((groups, item) => {
      const category = item.category || 'Other'
      ;(groups[category] ||= []).push(item)
      return groups
    }, {}) || {},
)
// These derived values drive the summary card without changing the server response.
const purchasedCount = computed(
  () => list.value?.items.filter((item) => item.purchased).length || 0,
)
const remainingItemCount = computed(
  () => list.value?.items.filter((item) => !item.purchased).length || 0,
)
const remainingEstimatedCost = computed(() =>
  (list.value?.items || [])
    .filter((item) => !item.purchased)
    .reduce((total, item) => total + item.estimatedCost, 0),
)
const boughtCost = computed(() =>
  (list.value?.items || [])
    .filter((item) => item.purchased)
    .reduce((total, item) => total + (item.actualCost ?? item.estimatedCost), 0),
)

onMounted(async () => {
  // Generate the latest list from the student's current meal plan.
  try {
    list.value = await api.getShoppingList()
  } catch {
    loadError.value = true
  } finally {
    loading.value = false
  }
})
// Refresh the list with the server's updated purchased state.
async function toggle(item) {
  list.value = await api.toggleShoppingItem(item.id)
}
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div
        class="d-flex flex-column flex-md-row align-items-md-end justify-content-between gap-3 mb-4"
      >
        <div>
          <p class="eyebrow">Generated from your meal plan</p>
          <h1 class="page-title">Shopping list.</h1>
          <p class="page-subtitle">
            Repeated ingredients are combined by ingredient and measurement unit.
          </p>
          <p class="list-update-note mb-0">Your list updates when you change this week's meal plan.</p>
        </div>
        <RouterLink class="btn btn-outline-primary rounded-pill px-4" to="/calendar"
          >Edit meal plan</RouterLink
        >
      </div>
      <div v-if="loading" class="py-5 text-center text-secondary">
        Building your shopping list...
      </div>
      <div v-else-if="loadError" class="empty-state p-5">
        We could not build your shopping list. Check your meal plan and try again.
      </div>
      <template v-else-if="list && list.items.length">
        <!-- Separate active shopping tasks from items already bought. -->
        <div class="shopping-tabs" role="tablist" aria-label="Shopping list status">
          <button
            class="shopping-tab"
            :class="{ active: isToBuyTab }"
            type="button"
            role="tab"
            :aria-selected="isToBuyTab"
            @click="activeTab = 'to-buy'"
          >
            To buy ({{ toBuyItems.length }})
          </button>
          <button
            class="shopping-tab"
            :class="{ active: !isToBuyTab }"
            type="button"
            role="tab"
            :aria-selected="!isToBuyTab"
            @click="activeTab = 'purchased'"
          >
            Purchased ({{ purchasedItems.length }})
          </button>
        </div>
        <div class="row g-4">
          <div class="col-lg-8">
            <section v-if="!visibleItems.length" class="shopping-empty surface-card p-4 p-md-5">
              <template v-if="isToBuyTab">
                <p class="eyebrow">Shopping complete</p>
                <h2 class="list-heading">You're all set for this trip.</h2>
                <p class="text-secondary mb-4">Everything on your current meal plan has been marked as purchased.</p>
                <RouterLink class="btn btn-primary rounded-pill px-4" to="/budget">View budget</RouterLink>
              </template>
              <template v-else>
                <h2 class="list-heading">No purchased items yet.</h2>
                <p class="text-secondary mb-0">Items move here after you tick them off in your shopping list.</p>
              </template>
            </section>
            <template v-else>
              <!-- Group ingredients by category so the list is easy to scan in a shop. -->
              <section
                v-for="(items, category) in groupedItems"
                :key="category"
                class="surface-card p-4 p-md-5 mb-4"
              >
                <h2 class="list-heading">{{ category }}</h2>
                <!-- Each row toggles its purchased state through the backend. -->
                <label
                  v-for="item in items"
                  :key="`${item.ingredientId}-${item.unit}`"
                  class="shopping-item"
                  :class="{ purchased: item.purchased }"
                  ><input type="checkbox" :checked="item.purchased" @change="toggle(item)" /><span
                    class="check-circle"
                    aria-hidden="true"
                  ></span
                  ><span class="item-name">{{ item.name }}</span
                  ><strong>{{ item.totalQuantity }} {{ item.unit }}</strong></label
                >
              </section>
            </template>
          </div>
          <aside class="col-lg-4">
            <section class="surface-card p-4 sticky-lg-top summary-card">
              <p class="eyebrow">This trip</p>
              <h2 class="list-heading">Plan summary</h2>
              <!-- These totals explain how the current shopping state affects the trip. -->
              <div class="summary-row">
                <span>Recipes planned</span><strong>{{ list.recipeIds.length }}</strong>
              </div>
              <div class="summary-row">
                <span>Items bought</span
                ><strong>{{ purchasedCount }} / {{ list.items.length }}</strong>
              </div>
              <div class="summary-total">
                <span>Estimated cost remaining</span
                ><strong>${{ remainingEstimatedCost.toFixed(2) }}</strong>
              </div>
              <div class="summary-row">
                <span>Remaining to buy</span><strong>{{ remainingItemCount }} items</strong>
              </div>
              <div class="summary-row">
                <span>Bought so far</span><strong>${{ boughtCost.toFixed(2) }}</strong>
              </div>
              <div class="summary-full-total">
                <span>Full plan estimate</span><strong>${{ list.totalEstimatedCost.toFixed(2) }}</strong>
              </div>
              <p class="summary-help mb-0">The remaining amount updates as you tick off items.</p>
            </section>
            <section v-if="list.savingsTips?.length" class="surface-card p-4 mt-4 savings-card">
              <p class="eyebrow">Smart optimisation</p>
              <h2 class="list-heading">Cost-saving ideas</h2>
              <ul class="savings-list mb-0">
                <li v-for="tip in list.savingsTips" :key="tip">{{ tip }}</li>
              </ul>
            </section>
          </aside>
        </div></template>
      <!-- A shopping list cannot exist until the student has planned at least one recipe. -->
      <div v-else class="empty-state p-5">
        <h2 class="h4 fw-bold">Your shopping list starts with your meal plan.</h2>
        <p class="text-secondary mb-4">Add recipes to your calendar and UniMeal will combine the ingredients for you.</p>
        <div class="d-flex flex-wrap justify-content-center gap-2">
          <RouterLink class="btn btn-primary rounded-pill px-4" to="/calendar">Plan my week</RouterLink>
          <RouterLink class="btn btn-outline-primary rounded-pill px-4" to="/recipes">Browse recipes</RouterLink>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.list-heading {
  color: var(--um-ink);
  font-size: 1.35rem;
  font-weight: 800;
  letter-spacing: -0.03em;
}
.list-update-note {
  margin-top: 0.45rem;
  color: var(--um-muted);
  font-size: 0.85rem;
}
.shopping-tabs {
  /* Compact tabs make it easy to switch without mixing bought and unbought items. */
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}
.shopping-tab {
  border: 1px solid var(--um-line);
  border-radius: 0.5rem;
  padding: 0.55rem 0.85rem;
  color: var(--um-green);
  background: #fff;
  font-weight: 750;
}
.shopping-tab.active {
  border-color: var(--um-green);
  color: #fff;
  background: var(--um-green);
}
.shopping-empty {
  border-left: 4px solid var(--um-green);
}
/* Each shopping row uses a check control, flexible item name and fixed quantity column. */
.shopping-item {
  display: grid;
  grid-template-columns: 1.2rem minmax(0, 1fr) auto;
  gap: 0.75rem;
  align-items: center;
  padding: 1rem 0;
  border-bottom: 1px solid var(--um-line);
  cursor: pointer;
}
/* The last row has no divider because the card already provides a boundary. */
.shopping-item:last-child {
  border: 0;
}
/* The native checkbox remains accessible but is visually replaced with a custom circle. */
.shopping-item input {
  position: absolute;
  opacity: 0;
}
.check-circle {
  /* An empty circle represents an item still to buy. */
  width: 1.1rem;
  height: 1.1rem;
  border: 1.5px solid #bdc7b9;
  border-radius: 50%;
}
.shopping-item input:checked + .check-circle {
  /* A green filled circle with an inset white dot represents a purchased item. */
  border-color: var(--um-green);
  background: var(--um-green);
  box-shadow: inset 0 0 0 3px #fff;
}
.shopping-item.purchased .item-name,
.shopping-item.purchased strong {
  /* Purchased items remain visible in their history tab but are clearly de-emphasised. */
  color: #9ca59a;
  text-decoration: line-through;
}

.item-name {
  min-width: 0;
  font-weight: 650;
}
.shopping-item strong {
  /* Prevent quantities such as "500 g" from wrapping onto two lines. */
  color: var(--um-green);
  text-align: right;
  white-space: nowrap;
}

.summary-card {
  top: 6rem;
}
.summary-row,
.summary-total {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.9rem 0;
  color: var(--um-muted);
}

.summary-row {
  /* Dividers separate the intermediate counts in the trip summary. */
  border-bottom: 1px solid var(--um-line);
}
.summary-row strong {
  color: var(--um-ink);
}

.summary-total {
  margin-top: 0.7rem;
  color: var(--um-ink);
  font-weight: 750;
}

.summary-total strong {
  color: var(--um-green);
  font-size: 1.4rem;
}
.summary-full-total {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding-top: 1rem;
  color: var(--um-ink);
  font-weight: 750;
}
.summary-help {
  margin-top: 0.85rem;
  color: var(--um-muted);
  font-size: 0.82rem;
  line-height: 1.45;
}

.savings-card {
  border-left: 4px solid var(--um-green);
}

.savings-list {
  padding-left: 1.2rem;
  color: var(--um-muted);
}

.savings-list li + li {
  margin-top: 0.75rem;
}

@media (max-width: 575.98px) {
  .shopping-item {
    gap: 0.55rem;
  }
}
</style>
