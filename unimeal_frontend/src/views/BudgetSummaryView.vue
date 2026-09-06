<script setup>
import { Chart, BarElement, BarController, CategoryScale, LinearScale, Tooltip } from 'chart.js'
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import { api } from '../services/api'

Chart.register(BarElement, BarController, CategoryScale, LinearScale, Tooltip)
const summary = ref(null)
const chartCanvas = ref(null)
let chart
const remaining = computed(() => summary.value ? summary.value.period.budgetAmount - summary.value.actualSpent : 0)
const usedPercent = computed(() => summary.value ? Math.min(100, summary.value.actualSpent / summary.value.period.budgetAmount * 100) : 0)

onMounted(async () => {
  summary.value = await api.getBudgetSummary()
  await nextTick()
  chart = new Chart(chartCanvas.value, { type: 'bar', data: { labels: ['This week'], datasets: [{ label: 'Spent', data: [summary.value.actualSpent], backgroundColor: '#31572c', borderRadius: 8, barThickness: 48 }, { label: 'Budget', data: [summary.value.period.budgetAmount], backgroundColor: '#e8e4d9', borderRadius: 8, barThickness: 48 }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { tooltip: { displayColors: false } }, scales: { x: { grid: { display: false }, border: { display: false } }, y: { beginAtZero: true, grid: { color: '#efede6' }, border: { display: false }, ticks: { callback: (value) => `$${value}` } } } } })
})
onBeforeUnmount(() => chart?.destroy())
</script>

<template>
  <section class="page-shell"><div class="container"><div class="d-flex flex-column flex-md-row align-items-md-end justify-content-between gap-3 mb-4"><div><p class="eyebrow">Weekly spending</p><h1 class="page-title">Budget summary.</h1><p class="page-subtitle">A clear view of your planned food costs and weekly budget.</p></div><RouterLink class="btn btn-outline-primary rounded-pill px-4" to="/shopping-list">View shopping list</RouterLink></div><div v-if="!summary" class="py-5 text-center text-secondary">Loading budget summary...</div><template v-else><div class="row g-4"><div class="col-lg-7"><section class="surface-card p-4 p-md-5 chart-card h-100"><div class="d-flex justify-content-between align-items-start"><div><h2 class="budget-heading">Spent vs budget</h2><p class="text-secondary mb-0">{{ summary.period.startDate }} to {{ summary.period.endDate }}</p></div><span class="soft-badge">Current week</span></div><div class="chart-wrap mt-4"><canvas ref="chartCanvas" aria-label="Bar chart comparing weekly spending and budget" role="img"></canvas></div><p class="small text-secondary mb-0">Chart values use purchased shopping-list items within the selected budget period.</p></section></div><div class="col-lg-5"><section class="surface-card p-4 p-md-5 h-100"><p class="eyebrow">Available to spend</p><h2 class="remaining-amount">${{ remaining.toFixed(2) }}</h2><p class="text-secondary">of ${{ summary.period.budgetAmount.toFixed(2) }} remains this week.</p><div class="progress mt-4" role="progressbar" aria-label="Budget used" :aria-valuenow="usedPercent" aria-valuemin="0" aria-valuemax="100"><div class="progress-bar" :style="{ width: `${usedPercent}%` }"></div></div><div class="d-flex justify-content-between mt-2 small fw-semibold"><span>{{ usedPercent.toFixed(0) }}% used</span><span>${{ summary.actualSpent.toFixed(2) }} spent</span></div><div class="budget-tip mt-4"><strong>Small win</strong><p class="mb-0">Your planned meals keep you below this week's limit. Check the list before buying extras.</p></div></section></div></div><section class="surface-card p-4 p-md-5 mt-4"><h2 class="budget-heading">Spending breakdown</h2><div v-for="category in summary.categories" :key="category.label" class="breakdown-row"><span>{{ category.label }}</span><div><span class="breakdown-track"><i :style="{ width: `${summary.actualSpent ? category.amount / summary.actualSpent * 100 : 0}%` }"></i></span><strong>${{ category.amount.toFixed(2) }}</strong></div></div></section></template></div></section>
</template>

<style scoped>
.budget-heading { color: var(--um-ink); font-size: 1.4rem; font-weight: 800; letter-spacing: -.03em; }.chart-wrap { position: relative; height: 19rem; }.remaining-amount { color: var(--um-green); font-size: 3rem; font-weight: 800; letter-spacing: -.06em; }.progress { height: .65rem; border-radius: 99px; background: #e9ece5; }.progress-bar { border-radius: 99px; background: var(--um-coral); }.budget-tip { padding: 1rem; border-radius: .8rem; color: #51634e; background: #f1f6ef; font-size: .9rem; }.budget-tip strong { color: var(--um-green); }.budget-tip p { margin-top: .35rem; }.breakdown-row { display: flex; justify-content: space-between; align-items: center; gap: 1rem; padding: 1rem 0; border-bottom: 1px solid var(--um-line); color: var(--um-muted); font-weight: 650; }.breakdown-row > div { display: flex; gap: .75rem; align-items: center; }.breakdown-row strong { min-width: 3.8rem; color: var(--um-green); text-align: right; }.breakdown-track { width: min(20vw, 10rem); height: .45rem; overflow: hidden; border-radius: 99px; background: #ecefe9; }.breakdown-track i { display: block; height: 100%; border-radius: inherit; background: var(--um-green); }@media (max-width: 575.98px) { .breakdown-track { width: 5rem; } }
</style>
