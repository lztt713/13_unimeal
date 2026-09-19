<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '../services/api'

const list = ref(null)
const loading = ref(true)
const loadError = ref(false)
// ----------  group by category -
const groupedItems = computed(
  () =>
    list.value?.items.reduce((groups, item) => {
      const category = item.category || 'Other'  // 没有 category 就归为 'Other'
      ;(groups[category] ||= []).push(item)
      return groups
    }, {}) || {},
)
// -------- purchased count
const purchasedCount = computed(
  () => list.value?.items.filter((item) => item.purchased).length || 0,
)

onMounted(async () => {
  try {
    list.value = await api.getShoppingList()
  } catch {
    loadError.value = true
  } finally {
    loading.value = false
  }
})
// -------- Method: toggle purchased ---
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
      <template v-else-if="list && list.items.length"
        ><div class="row g-4">
           <!-- 左侧：按类别分组的食材 -->
          <div class="col-lg-8">
            <!-- Outer loop: iterate over categories -->
            <section
              v-for="(items, category) in groupedItems"
              :key="category"
              class="surface-card p-4 p-md-5 mb-4"
            >
              <h2 class="list-heading">{{ category }}</h2>
              <!-- Inner loop: all items in this category -->
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
          </div>
          <!-- 右侧：Plan summary -->
          <aside class="col-lg-4">
            <section class="surface-card p-4 sticky-lg-top summary-card">
              <p class="eyebrow">This trip</p>
              <h2 class="list-heading">Plan summary</h2>
              <!-- Recipes planned count -->
              <div class="summary-row">
                <span>Recipes planned</span><strong>{{ list.recipeIds.length }}</strong>
              </div>
              <!-- Items checked -->
              <div class="summary-row">
                <span>Items checked</span
                ><strong>{{ purchasedCount }} / {{ list.items.length }}</strong>
              </div>
              <div class="summary-total">
                <span>Estimated total</span
                ><strong>${{ list.totalEstimatedCost.toFixed(2) }}</strong>
              </div>
            </section>
          </aside>
        </div></template>
         <!--Empty: no meal plan -->
      <div v-else class="empty-state p-5">Plan some meals to generate a shopping list.</div>
    </div>
  </section>
</template>

<style scoped>
/* 每个分类卡片的标题，以及右侧 "Plan summary" */
.list-heading {
  color: var(--um-ink);
  font-size: 1.35rem;
  font-weight: 800;
  letter-spacing: -0.03em;
}
/* ===== Each item row: 3-column grid ===== */
/* Col 1: circle */
/*  Col 2: name, auto-fill */
/* Col 3: quantity, auto */
.shopping-item {
  display: grid;
  grid-template-columns: 1.2rem minmax(0, 1fr) auto;
  gap: 0.75rem;
  align-items: center;
  padding: 1rem 0;
  border-bottom: 1px solid var(--um-line);
  cursor: pointer; /*鼠标移上去变手型，提示可点击*/
}
/* ===== Remove border from last item ===== */
.shopping-item:last-child {
  border: 0;
}
/* =====  Hide native checkbox ===== */
.shopping-item input {
  position: absolute;
  opacity: 0;
}
/* 每行最左侧的空心小圆圈 */
.check-circle {
  width: 1.1rem;
  height: 1.1rem;
  border: 1.5px solid #bdc7b9;
  border-radius: 50%;
}
/* 用户勾选后，圆圈变成"绿色实心圆 + 中间白点 */
.shopping-item input:checked + .check-circle {
  border-color: var(--um-green);
  background: var(--um-green);
  box-shadow: inset 0 0 0 3px #fff;
}
/* 已购买项的删除线 */
.shopping-item.purchased .item-name,
.shopping-item.purchased strong {
  color: #9ca59a;
  text-decoration: line-through;
}

.item-name {
  min-width: 0;
  font-weight: 650;
}
/* 每行右侧的 "500 g"、"6 pc" */
.shopping-item strong {
  color: var(--um-green);
  text-align: right;
  white-space: nowrap;  /*禁止换行（"500 g" 不断成两行）*/
}

.summary-card {
  top: 6rem;
}
/* 右侧那 3 行"标签 + 数字" */
.summary-row,
.summary-total {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.9rem 0;
  color: var(--um-muted);
}

.summary-row {
  border-bottom: 1px solid var(--um-line);   /* 中间两条有分割线 */
}
.summary-row strong {
  color: var(--um-ink);
}

.summary-total {
  margin-top: 0.7rem;
  color: var(--um-ink);   /* 最后一行颜色更深 */
  font-weight: 750;
}

.summary-total strong {
  color: var(--um-green);
  font-size: 1.4rem;
}

@media (max-width: 575.98px) {
  .shopping-item {
    gap: 0.55rem;
  }
}
</style>
