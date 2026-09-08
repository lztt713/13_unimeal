import axios from 'axios'
import { ref } from 'vue'

export const apiError = ref('')
export const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 15000,
  withCredentials: true,
})

http.interceptors.response.use(
  (response) => response,
  (error) => {
    const detail = error.response?.data?.detail
    error.message = Array.isArray(detail)
      ? detail.map((item) => item.msg).join('; ')
      : typeof detail === 'string'
        ? detail
        : 'Could not reach UniMeal. Check that the local server is running.'
    if (!(error.config?.url === '/auth/me' && error.response?.status === 401)) {
      apiError.value = error.message
    }
    return Promise.reject(error)
  },
)
const data = (request) => request.then((response) => response.data)

export const api = {
  getDashboard: () => data(http.get('/dashboard')),
  getRecipes: () => data(http.get('/recipes')),
  getRecipe: (id) => data(http.get(`/recipes/${id}`)),
  getIngredients: () => data(http.get('/ingredients')),
  createRecipe: (recipe) => data(http.post('/recipes', recipe)),
  updateRecipe: (id, recipe) => data(http.put(`/recipes/${id}`, recipe)),
  getMyRecipes: () => data(http.get('/my-recipes')),
  async toggleRecipePublication(id) {
    const recipe = await this.getRecipe(id)
    return this.updateRecipe(id, { status: recipe.status === 'Published' ? 'Draft' : 'Published' })
  },
  deleteMyRecipe: (id) => data(http.delete(`/recipes/${id}`)),
  addRecipeRating: (id, rating) => data(http.post(`/recipes/${id}/ratings`, { rating })),
  addRecipeComment: (id, text) => data(http.post(`/recipes/${id}/comments`, { text })),
  getMealPlan: () => data(http.get('/meal-plan')),
  saveMealPlanEntry: (entry) => data(http.post('/meal-plan/entries', entry)),
  removeMealPlanEntry: (id) => data(http.delete(`/meal-plan/entries/${id}`)),
  getShoppingList: () => data(http.post('/shopping-list/generate')),
  toggleShoppingItem: (id) => data(http.patch(`/shopping-list/items/${id}/purchased`)),
  getBudgetSummary: () => data(http.get('/budget-summary')),
  async getCurrentUser() {
    try {
      return await data(http.get('/auth/me'))
    } catch (error) {
      if (error.response?.status === 401) return null
      throw error
    }
  },
  signIn: (credentials) => data(http.post('/auth/login', credentials)),
  register: (profile) => data(http.post('/auth/register', profile)),
  signOut: () => data(http.post('/auth/logout')),
  updateProfile: (profile) => data(http.put('/profile', profile)),
  getNotifications: () => data(http.get('/notifications')),
  markNotificationRead: (id) => data(http.patch(`/notifications/${id}/read`)),
  markAllNotificationsRead: () => data(http.patch('/notifications/read-all')),
  getAdminOverview: () => data(http.get('/admin/overview')),
  updateReportStatus: (id, status) => data(http.patch(`/admin/reports/${id}`, { status })),
  createContentReport: (report) => data(http.post('/reports', report)),
  getAdminManagement: () => data(http.get('/admin/management')),
  updateUser: (id, update) => data(http.patch(`/admin/users/${id}`, update)),
  updateAdminRecipeStatus: (id, status) => data(http.patch(`/admin/recipes/${id}`, { status })),
  getIngredientCategories: () => data(http.get('/admin/ingredient-categories')),
  addIngredientCategory: (name) => data(http.post('/admin/ingredient-categories', { name })),
  deleteIngredientCategory: (id) => data(http.delete(`/admin/ingredient-categories/${id}`)),
  toggleSavedRecipe: (id) => data(http.post(`/recipes/${id}/saved`)),
  getSavedRecipeIds: () => data(http.get('/saved-recipes')),
  getAiRecommendation: (query) => data(http.post('/recommendations', { query })),
}
