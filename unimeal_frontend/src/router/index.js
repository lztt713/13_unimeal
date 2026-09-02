import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'
import PlaceholderView from '../views/PlaceholderView.vue'
import RecipeListView from '../views/RecipeListView.vue'
import RecipeDetailView from '../views/RecipeDetailView.vue'
import RecipeSubmissionView from '../views/RecipeSubmissionView.vue'
import MealCalendarView from '../views/MealCalendarView.vue'
import ShoppingListView from '../views/ShoppingListView.vue'
import BudgetSummaryView from '../views/BudgetSummaryView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/dashboard' },
    { path: '/dashboard', name: 'dashboard', component: DashboardView },
    { path: '/recipes', name: 'recipes', component: RecipeListView },
    { path: '/recipes/:id', name: 'recipe-detail', component: RecipeDetailView, props: true },
    { path: '/submit-recipe', name: 'recipe-submission', component: RecipeSubmissionView },
    { path: '/calendar', name: 'calendar', component: MealCalendarView },
    { path: '/shopping-list', name: 'shopping-list', component: ShoppingListView },
    { path: '/budget', name: 'budget', component: BudgetSummaryView },
    { path: '/admin', name: 'admin', component: PlaceholderView, props: { title: 'Admin Dashboard', description: 'User, recipe and report management will appear here.' } },
    { path: '/ai-helper', name: 'ai-helper', component: PlaceholderView, props: { title: 'AI Meal Helper', description: 'Ask for a meal idea in natural language. Doubao integration is coming soon.' } },
    { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
  ],
})

export default router
