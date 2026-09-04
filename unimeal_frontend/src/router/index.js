import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'
import PlaceholderView from '../views/PlaceholderView.vue'
import RecipeListView from '../views/RecipeListView.vue'
import RecipeDetailView from '../views/RecipeDetailView.vue'
import RecipeSubmissionView from '../views/RecipeSubmissionView.vue'
import MealCalendarView from '../views/MealCalendarView.vue'
import ShoppingListView from '../views/ShoppingListView.vue'
import BudgetSummaryView from '../views/BudgetSummaryView.vue'
import HomeView from '../views/HomeView.vue'
import AuthView from '../views/AuthView.vue'
import ProfileView from '../views/ProfileView.vue'
import AdminDashboardView from '../views/AdminDashboardView.vue'
import AiHelperView from '../views/AiHelperView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', name: 'home', component: HomeView },
    { path: '/login', name: 'login', component: AuthView, props: { mode: 'login' } },
    { path: '/register', name: 'register', component: AuthView, props: { mode: 'register' } },
    { path: '/profile', name: 'profile', component: ProfileView },
    { path: '/dashboard', name: 'dashboard', component: DashboardView },
    { path: '/recipes', name: 'recipes', component: RecipeListView },
    { path: '/recipes/:id', name: 'recipe-detail', component: RecipeDetailView, props: true },
    { path: '/submit-recipe', name: 'recipe-submission', component: RecipeSubmissionView },
    { path: '/calendar', name: 'calendar', component: MealCalendarView },
    { path: '/shopping-list', name: 'shopping-list', component: ShoppingListView },
    { path: '/budget', name: 'budget', component: BudgetSummaryView },
    { path: '/admin', name: 'admin', component: AdminDashboardView },
    { path: '/ai-helper', name: 'ai-helper', component: AiHelperView },
    { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
  ],
})

export default router
