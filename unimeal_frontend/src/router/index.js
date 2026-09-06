import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'
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
import MyRecipesView from '../views/MyRecipesView.vue'
import AdminManagementView from '../views/AdminManagementView.vue'
import { api } from '../services/api'

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
    { path: '/submit-recipe', name: 'recipe-submission', component: RecipeSubmissionView, meta: { roles: ['contributor', 'administrator'] } },
    { path: '/my-recipes', name: 'my-recipes', component: MyRecipesView, meta: { roles: ['contributor', 'administrator'] } },
    { path: '/calendar', name: 'calendar', component: MealCalendarView },
    { path: '/shopping-list', name: 'shopping-list', component: ShoppingListView },
    { path: '/budget', name: 'budget', component: BudgetSummaryView },
    { path: '/admin', name: 'admin', component: AdminDashboardView, meta: { roles: ['administrator'] } },
    { path: '/admin/manage', name: 'admin-management', component: AdminManagementView, meta: { roles: ['administrator'] } },
    { path: '/ai-helper', name: 'ai-helper', component: AiHelperView },
    { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
  ],
})

router.beforeEach(async (to) => {
  if (!to.meta.roles) return true
  const user = await api.getCurrentUser()
  return to.meta.roles.includes(user.role) ? true : { name: 'dashboard' }
})

export default router
