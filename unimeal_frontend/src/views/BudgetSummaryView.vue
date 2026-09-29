<script setup>
import { Chart, BarElement, BarController, CategoryScale, LinearScale, Tooltip } from 'chart.js'
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import { api } from '../services/api'

// Register Chart.js components
Chart.register(BarElement, BarController, CategoryScale, LinearScale, Tooltip)
const summary = ref(null)
const chartCanvas = ref(null)
let chart //Chart.js 实例（不需要响应式，所以用 let）

const hasBudget = computed(() => summary.value?.period.budgetAmount > 0)
// ---------- 剩余金额 remaining ----------
const remaining = computed(() =>
  hasBudget.value ? summary.value.period.budgetAmount - summary.value.actualSpent : 0,
)
const overBudget = computed(() => hasBudget.value && remaining.value < 0)
// ---------- 已用百分比  used percentage -----
const usedPercent = computed(() =>
  hasBudget.value
    ? Math.min(100, (summary.value.actualSpent / summary.value.period.budgetAmount) * 100)
    : 0,
)

// ---------- 动态提示：根据预算状态返回不同文案 ----------
const budgetMessage = computed(() => {
  if (!summary.value) return null

  if (!hasBudget.value) {
    return {
      title: 'No budget set',
      text: 'Your purchases are recorded, but there is no weekly budget to compare them with.',
      type: 'neutral',
    }
  }

  if (overBudget.value) {
    return {
      title: 'Budget exceeded',
      text: `You have spent $${Math.abs(remaining.value).toFixed(2)} over your weekly budget.`,
      type: 'warning',
    }
  }

  const percent = usedPercent.value

  if (percent >= 100) {
    return {
      title: 'Budget reached',
      text: 'You have used your full weekly budget.',
      type: 'warning',
    }
  }

  if (percent >= 80) {
    return {
      title: 'Getting close',
      text: 'You have used most of your weekly budget. Plan carefully for the remaining days.',
      type: 'warning',
    }
  }

  return {
    title: 'On track',
    text: `You still have $${remaining.value.toFixed(2)} left this week. Keep it up!`,
    type: 'success',
  }
})
// ---------- 生命周期：加载数据 + 初始化图表 /
onMounted(async () => {
  summary.value = await api.getBudgetSummary()
  // A $0 chart provides no useful comparison; the template shows a clearer empty state instead.
  if (!summary.value.actualSpent) return
  // Wait for Vue to finish DOM update, ensure <canvas> is rendered
  await nextTick()
   // Initialize Chart.js bar chart on canvas
  chart = new Chart(chartCanvas.value, {
    type: 'bar',
    data: {
      labels: ['This week'],
      datasets: [
        {
          label: 'Spent',
          data: [summary.value.actualSpent],
          backgroundColor: '#31572c',
          borderRadius: 8,
          barThickness: 48, // 柱子宽度 48px
        },
        {
          label: 'Budget',
          data: [summary.value.period.budgetAmount],
          backgroundColor: '#e8e4d9',
          borderRadius: 8,
          barThickness: 48,
        },
      ],
    },
    options: {
      responsive: true,  // 跟随容器大小自动调整
      maintainAspectRatio: false,  // 不保持固定比例，允许自由伸缩
      plugins: { tooltip: { displayColors: false } },  // 鼠标悬停提示不显示颜色小方块
      scales: {
        x: { grid: { display: false }, border: { display: false } },// X 轴不要网格线,轴线
        y: {
          beginAtZero: true,
          grid: { color: '#efede6' },
          border: { display: false },
          ticks: { callback: (value) => `$${value}` }, // 每个刻度加上美元符号
        },
      },
    },
  })
})
// - Cleanup before unmount --
//  Destroy chart to prevent memory leak
onBeforeUnmount(() => chart?.destroy())
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div
        class="d-flex flex-column flex-md-row align-items-md-end justify-content-between gap-3 mb-4"
      >
        <div>
          <p class="eyebrow">Weekly spending</p>
          <h1 class="page-title">Budget summary.</h1>
          <p class="page-subtitle">A clear view of your purchased food costs and weekly budget.</p>
        </div>
        <RouterLink class="btn btn-outline-primary rounded-pill px-4" to="/shopping-list"
          >View shopping list</RouterLink>
      </div>
      <!-- 加载中 / Loading -->
      <div v-if="!summary" class="py-5 text-center text-secondary">Loading budget summary...</div>
      <template v-else
        ><div class="row g-4">
           <!-- Left (7/12): Bar chart -->
          <div class="col-lg-7">
            <section class="surface-card p-4 p-md-5 chart-card h-100">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <h2 class="budget-heading">Actual spending vs budget</h2>
                  <!--  Show date range -->
                  <p class="text-secondary mb-0">
                    {{ summary.period.startDate }} to {{ summary.period.endDate }}
                  </p>
                </div>
                <span class="soft-badge">Current week</span>
              </div>
              <!-- Chart.js canvas -->
              <div v-if="summary.actualSpent > 0" class="chart-wrap mt-4">
                <canvas ref="chartCanvas"></canvas>
              </div>
              <div v-else class="budget-empty mt-4">
                <h3 class="h5 fw-bold">No purchases recorded this week yet.</h3>
                <p class="text-secondary mb-3">Your spending appears here after you tick off items in your shopping list.</p>
                <RouterLink class="btn btn-outline-primary rounded-pill px-4" to="/shopping-list">Open shopping list</RouterLink>
              </div>
            </section>
          </div>
          <!-- Right (5/12): Remaining budget + progress bar -->
          <div class="col-lg-5">
            <section class="surface-card p-4 p-md-5 h-100">
              <p class="eyebrow">
                {{ !hasBudget ? 'Weekly spending' : overBudget ? 'Over budget' : 'Available to spend' }}
              </p>
              <h2 v-if="hasBudget" class="remaining-amount" :class="{ 'text-danger': overBudget }">
                ${{ Math.abs(remaining).toFixed(2) }} {{ overBudget ? 'over' : 'left' }}
              </h2>
              <h2 v-else class="remaining-amount">No budget set</h2>
              <p v-if="hasBudget" class="text-secondary">
                Weekly budget: ${{ summary.period.budgetAmount.toFixed(2) }}.
              </p>
              <RouterLink v-else to="/profile">Set your weekly budget in your profile</RouterLink>
              <p class="budget-explanation">Only items marked as purchased in your shopping list count here.</p>
              <div v-if="hasBudget" class="progress mt-4">
                <div class="progress-bar" :style="{ width: `${usedPercent}%` }"></div>
              </div>
              <div class="d-flex justify-content-between mt-2 small fw-semibold">
                <span v-if="hasBudget">{{ usedPercent.toFixed(0) }}% used</span
                ><span>${{ summary.actualSpent.toFixed(2) }} actual spent</span>
              </div>
              <!--  Tip box -->
              <div v-if="budgetMessage" class="budget-tip mt-4" :class="budgetMessage.type">
                <strong>{{ budgetMessage.title }}</strong>
                <p class="mb-0">
                  {{ budgetMessage.text }}
                </p>
              </div>
            </section>
          </div>
        </div>
        <section v-if="summary.actualSpent > 0" class="surface-card p-4 p-md-5 mt-4">
          <h2 class="budget-heading">Weekly spending by category</h2>

          <div v-for="category in summary.categories" :key="category.label" class="breakdown-row">
            <span>{{ category.label }}</span>
            <div>
              <span class="breakdown-track"
                ><i
                  :style="{ width: `${(category.amount / summary.actualSpent) * 100}%` }"
                ></i></span
              ><strong>${{ category.amount.toFixed(2) }}</strong>
            </div>
          </div>
        </section></template
      >
    </div>
  </section>
</template>

<style scoped>
.budget-heading {
  color: var(--um-ink);
  font-size: 1.4rem;
  font-weight: 800;
  letter-spacing: -0.03em;
}
/* 给 canvas 一个固定高度的容器 */
.chart-wrap {
  position: relative;
  height: 19rem;
}
.budget-empty {
  display: flex;
  min-height: 19rem;
  flex-direction: column;
  align-items: flex-start;
  justify-content: center;
  padding: 1.5rem;
  border-radius: 0.6rem;
  background: var(--um-green-light);
}
.budget-explanation {
  margin-bottom: 0;
  color: var(--um-muted);
  font-size: 0.84rem;
  line-height: 1.45;
}
.remaining-amount {
  color: var(--um-green);
  font-size: 3rem;
  font-weight: 800;
  letter-spacing: -0.06em;  /* 字距收紧 */
}
.progress {
  height: 0.65rem;
  border-radius: 99px;
  background: #e9ece5;
}
.progress-bar {
  border-radius: 99px;
  background: var(--um-coral);
}

/*  Base tip box */
.budget-tip {
  padding: 1rem;
  border-radius: 0.8rem;
  font-size: 0.9rem;
}

/*  Green success (on track) */
.budget-tip.success {
  color: #51634e;
  background: #f1f6ef;
}

/*  Orange warning (close or exceeded) */
.budget-tip.warning {
  color: #8a4b08;
  background: #fdf1e6;
}
.budget-tip.neutral {
  color: #51634e;
  background: #f1f3ef;
}

.budget-tip strong {
  display: block;
  margin-bottom: 0.35rem;
}
/* 底部的 "Protein $15.00" 这种行 */
.breakdown-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  padding: 1rem 0;
  border-bottom: 1px solid var(--um-line);
  color: var(--um-muted);
  font-weight: 650;
}
.breakdown-row > div {
  display: flex;
  gap: 0.75rem;
  align-items: center;
}
.breakdown-row strong {
  min-width: 3.8rem;
  color: var(--um-green);
  text-align: right;
}
/* ===== Category progress track ===== */
.breakdown-track {
  width: min(20vw, 10rem);
  height: 0.45rem;
  overflow: hidden;
  border-radius: 99px;
  background: #ecefe9;
}
.breakdown-track i {
  display: block;
  height: 100%;
  border-radius: inherit; /* Inherit parent's radius */
  background: var(--um-green);
}
@media (max-width: 575.98px) {
  .breakdown-track {
    width: 5rem;
  }
}
</style>
