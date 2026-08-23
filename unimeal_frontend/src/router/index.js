import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'
import PlaceholderView from '../views/PlaceholderView.vue'
import RecipeListView from '../views/RecipeListView.vue'
import RecipeDetailView from '../views/RecipeDetailView.vue'
import RecipeSubmissionView from '../views/RecipeSubmissionView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/dashboard' },
    { path: '/dashboard', name: 'dashboard', component: DashboardView },
    { path: '/recipes', name: 'recipes', component: RecipeListView },
    { path: '/recipes/:id', name: 'recipe-detail', component: RecipeDetailView, props: true },
    { path: '/submit-recipe', name: 'recipe-submission', component: RecipeSubmissionView },
    { path: '/calendar', name: 'calendar', component: PlaceholderView, props: { title: 'Meal Calendar', description: 'Plan a delicious, affordable week one meal at a time.' } },
    { path: '/shopping-list', name: 'shopping-list', component: PlaceholderView, props: { title: 'Shopping List', description: 'Your grouped grocery list will appear here.' } },
    { path: '/budget', name: 'budget', component: PlaceholderView, props: { title: 'Budget Summary', description: 'Your weekly spending insights will appear here.' } },
    { path: '/admin', name: 'admin', component: PlaceholderView, props: { title: 'Admin Dashboard', description: 'User, recipe and report management will appear here.' } },
    { path: '/ai-helper', name: 'ai-helper', component: PlaceholderView, props: { title: 'AI Meal Helper', description: 'Ask for a meal idea in natural language. Doubao integration is coming soon.' } },
    { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
  ],
})

export default router
