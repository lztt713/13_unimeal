<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '../services/api'

const plan = ref({ entries: [] })
const recipes = ref([])
const loading = ref(true)
const loadError = ref(false)
const selectedWeekStart = ref('')
const activeSlot = ref(null)   // 当前打开的格子（day + mealType + entry）
const selectedRecipeId = ref('')
const plannedServings = ref(1)  // 这一餐做几人份，默认 1
const mealTypes = ['Breakfast', 'Lunch', 'Dinner']
// Generate 7 consecutive days starting from plan.weekStartDate
const weekDays = computed(() => {
  // 把 "2026-09-18" 拆成 [2026, 9, 18] / Split date string into numbers
  const [year, month, day] = plan.value.weekStartDate.split('-').map(Number)
   // Array.from 生成 7 个元素，offset 从 0 到 6
  return Array.from({ length: 7 }, (_, offset) => {
    // 注意 month - 1：JavaScript Date 的月份是 0-11
    const date = new Date(year, month - 1, day + offset)
    const dateKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
    return {
      date: dateKey,  // "2026-09-18"
      label: date.toLocaleDateString('en-NZ', { weekday: 'short' }), // "Mon"
      number: date.getDate(),  // 18
      isToday: date.toDateString() === new Date().toDateString(), // 是否今天
    }
  })
})
// selectedRecipeId 是"用户选了哪道菜的 ID"，selectedRecipe 是"把 ID 换成完整的数据对象"
const selectedRecipe = computed(() =>
  recipes.value.find((recipe) => recipe.id === Number(selectedRecipeId.value)),
)

async function loadMealPlan(weekStart) {
  plan.value = await api.getMealPlan(weekStart)// 传周起始日期
  selectedWeekStart.value = plan.value.weekStartDate
}

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
// ---------- 查某格有没有安排
function entryFor(day, mealType) {
  return plan.value.entries.find(
    (entry) => entry.plannedDate === day.date && entry.mealType === mealType,
  )
}
// ---------- 根据 entry 找食谱详情
function recipeFor(entry) {
  return recipes.value.find((recipe) => recipe.id === entry?.recipeId)
}
// ---------- 点击格子打开弹窗
function openSlot(day, mealType) {
  const entry = entryFor(day, mealType)  // 先查这个格子有没有安排
  activeSlot.value = { day, mealType, entry }  // 记录当前操作的格子
  selectedRecipeId.value = entry?.recipeId || '' // 已有安排则预选食谱
  plannedServings.value = entry?.plannedServings || 1   // 已有安排则读取份数，否则默认 1
}
// ---------- 保存安排
async function saveSlot() {
  if (!selectedRecipeId.value) return // 没选食谱直接返回
  plan.value = await api.saveMealPlanEntry({
    id: activeSlot.value.entry?.id, //  有 id 就是更新，没有就是新建
    plannedDate: activeSlot.value.day.date, //  日期
    mealType: activeSlot.value.mealType, //  餐次
    recipeId: Number(selectedRecipeId.value),//  转成数字
    plannedServings: plannedServings.value,  // 用户指定的份数
  })
  activeSlot.value = null
}
// ---------- 删除安排
async function removeSlot() {
  // Only call API if there's an existing entry
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
      <template v-else
        ><div class="surface-card calendar-wrap">
          <div class="calendar-grid">
            <!-- 左上角空白格 -->
            <div class="calendar-corner"></div>
             <!-- 7 个日期表头 -->
            <div
              v-for="day in weekDays"
              :key="day.date"
              class="day-heading"
              :class="{ today: day.isToday }"
            >
              <span>{{ day.label }}</span
              ><strong>{{ day.number }}</strong>
            </div>
            <!-- 3 行（每行一个餐次） -->
            <template v-for="mealType in mealTypes" :key="mealType">
              <!-- 左侧的餐次标签 -->
              <div class="meal-label">{{ mealType }}</div>
              <!-- 7 个格子 -->
              <div v-for="day in weekDays" :key="`${mealType}-${day.date}`" class="calendar-slot">
                <!-- 有安排：显示带图片的卡片 -->
                <template v-if="entryFor(day, mealType)"
                  ><button class="planned-recipe" type="button" @click="openSlot(day, mealType)">
                    <img
                      :src="recipeFor(entryFor(day, mealType)).imageUrl"
                      :alt="recipeFor(entryFor(day, mealType)).title"
                    /><span>{{ recipeFor(entryFor(day, mealType)).title }}</span>
                  </button>
                </template>
                 <!-- 没安排：显示 + 号 -->
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
         <!-- @click.self：只有点遮罩层才关闭  -->
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
            <!-- 下拉框 -->
            <select v-model="selectedRecipeId" class="form-select mt-3">
              <option value="">Select a recipe</option>
              <option v-for="recipe in recipes" :key="recipe.id" :value="recipe.id">
                {{ recipe.title }} - ${{ recipe.estimatedCost.toFixed(2) }}
              </option>
            </select>
            <!-- 选中食谱的预览 -->
            <div v-if="selectedRecipe" class="chosen-recipe mt-3">
              <img :src="selectedRecipe.imageUrl" :alt="selectedRecipe.title" />
              <div>
                <strong>{{ selectedRecipe.title }}</strong
                ><span>{{ selectedRecipe.cookTime }} min · {{ selectedRecipe.difficulty }}</span>
              </div>
            </div>
            <!-- 份数输入：选中食谱后才显示 -->
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
            <!-- 删除 / 保存 -->
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
/*  Calendar wrapper: horizontal scroll ===== */
.calendar-wrap {
  overflow-x: auto;
}
/*  Col 1: 6.5rem */
/*  Cols 2-8: 7 cols, min 8.5rem */
.calendar-grid {
  display: grid;
  grid-template-columns: 6.5rem repeat(7, minmax(8.5rem, 1fr));
  min-width: 66rem;
}
/* =====  Borders for grid children ===== */
.calendar-grid > * {
  border-bottom: 1px solid var(--um-line);
  border-right: 1px solid var(--um-line);
}
.calendar-corner {
  background: #fbfaf6;
}
/* =====  Day headings ===== */
.day-heading {
  display: flex;
  min-height: 5.25rem;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 0.15rem;
  background: #fbfaf6;
}
/* 今天的表头高亮 */
.day-heading.today {
  background: var(--um-green-light);
}
.day-heading.today strong {
  color: var(--um-coral);
}
/* "Mon" / "Tue" 这些星期的缩写 ,"Breakfast" / "Lunch" / "Dinner" */
.day-heading span,
.meal-label {
  color: var(--um-muted);
  font-size: 0.76rem;
  font-weight: 750;
  text-transform: uppercase;
}
/* "18" / "19" 这些日期数字 */
.day-heading strong {
  color: var(--um-green);
  font-size: 1.25rem;
}
/* =====  Meal labels ===== */
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
/* =====  "+" button: empty slot ===== */
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
/* =====  Planned recipe card ===== */
.planned-recipe {
  display: block;
  width: 100%;
  overflow: hidden;
  border: 0; /*button 默认有边框，去掉 */
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
/* 卡片底部那行菜名 */
.planned-recipe span {
  display: block;  /* 独占一行*/
  padding: 0.45rem;
}
/* ===== 弹窗遮罩层 / Modal backdrop ===== */
.modal-backdrop-custom {
  position: fixed;
  z-index: 1050;  /*盖在所有内容上面（Bootstrap 弹窗默认 1050）*/
  inset: 0;  /*上下左右都是 0，铺满整个屏幕*/
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
/* 弹窗里的 "Choose a recipe" */
.form-heading {
  color: var(--um-ink);
  font-weight: 800;
}
/* 弹窗里选完食谱后出现的小预览卡片（图片 + 标题 + 时间） */
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
/* 预览卡片里的标题和时间。
作用：让标题和时间各占一行 */
.chosen-recipe strong,
.chosen-recipe span {
  display: block;
}
/* 预览卡片里的 "35 min · Medium" */
.chosen-recipe span {
  color: var(--um-muted);
  font-size: 0.8rem;
}
</style>
