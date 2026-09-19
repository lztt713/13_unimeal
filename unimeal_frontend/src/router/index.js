import { createRouter, createWebHistory } from 'vue-router'
// Import all page components (views)
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
import NotificationsView from '../views/NotificationsView.vue'
import MyRecipesView from '../views/MyRecipesView.vue'
import AdminManagementView from '../views/AdminManagementView.vue'
import { api } from '../services/api'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', name: 'home', component: HomeView },
    // Login and register reuse AuthView, distinguished by props
    { path: '/login', name: 'login', component: AuthView, props: { mode: 'login' } },
    { path: '/register', name: 'register', component: AuthView, props: { mode: 'register' } },

    // ---------- Pages requiring authentication --------
    { path: '/profile', name: 'profile', component: ProfileView, meta: { requiresAuth: true } },

    // meta.roles is the core of access control, read by beforeEach guard below
    {
      path: '/dashboard',
      name: 'dashboard',
      component: DashboardView,
      meta: { roles: ['student'] },
    },
    { path: '/recipes', name: 'recipes', component: RecipeListView, meta: { requiresAuth: true } },
    {
      path: '/recipes/:id',
      name: 'recipe-detail',
      component: RecipeDetailView,
      props: true,
      meta: { requiresAuth: true },
    },
    // ---------Contributor-only pages ----------
    {
      path: '/submit-recipe',
      name: 'recipe-submission',
      component: RecipeSubmissionView,
      meta: { roles: ['contributor'] },
    },
    {
      path: '/my-recipes',
      name: 'my-recipes',
      component: MyRecipesView,
      meta: { roles: ['contributor'] },
    },
    {
      path: '/calendar',
      name: 'calendar',
      component: MealCalendarView,
      meta: { roles: ['student'] },
    },
    {
      path: '/shopping-list',
      name: 'shopping-list',
      component: ShoppingListView,
      meta: { roles: ['student'] },
    },
    { path: '/budget', name: 'budget', component: BudgetSummaryView, meta: { roles: ['student'] } },
    {
      path: '/admin',
      name: 'admin',
      component: AdminDashboardView,
      meta: { roles: ['administrator'] },
    },
    {
      path: '/admin/manage',
      name: 'admin-management',
      component: AdminManagementView,
      meta: { roles: ['administrator'] },
    },
    {
      path: '/ai-helper',
      name: 'ai-helper',
      component: AiHelperView,
      meta: { roles: ['student'] },
    },
    {
      path: '/notifications',
      name: 'notifications',
      component: NotificationsView,
      meta: { roles: ['student'] },
    },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
})

router.beforeEach(async (to) => {
   // Step 1: If the target page requires no login and has no role restriction, pass directly
  if (!to.meta.requiresAuth && !to.meta.roles) return true
   // Step 2: Need authentication, request backend to get current user info (with Cookie)
  const user = await api.getCurrentUser()
   // Step 3: If not logged in, redirect to login page and record original target path
  if (!user) return { name: 'login', query: { redirect: to.fullPath } }
  // Step 4: Logged in, but the page only requires login (no role restriction), pass
  if (!to.meta.roles) return true
   // Step 5: Check if user role matches page requirements
  if (to.meta.roles.includes(user.role)) return true
  if (user.role === 'administrator') return { name: 'admin' }
  if (user.role === 'contributor') return { name: 'my-recipes' }
  return { name: 'dashboard' }
})

export default router
