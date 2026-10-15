import axios from 'axios'
import { ref } from 'vue'

// Shared request error state displayed by the application shell.
export const apiError = ref('')

// One Axios client is shared by every API call. In development, Vite proxies
// the default /api base path to the local FastAPI server.
export const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 15000,
  withCredentials: true,
})

// Normalize failed API responses into a message that views can display.
http.interceptors.response.use(
  (response) => response,
  (error) => {
    const detail = error.response?.data?.detail
    error.message = Array.isArray(detail)
      ? detail.map((item) => item.msg).join('; ')
      : typeof detail === 'string'
        ? detail
        : 'Could not reach UniMeal. Check that the local server is running.'
    if (!error.config?.suppressGlobalError && !(error.config?.url === '/auth/me' && error.response?.status === 401)) {
      apiError.value = error.message
    }
    return Promise.reject(error)
  },
)

// Return only the response payload so views do not unwrap Axios data.
const data = (request) => request.then((response) => response.data)

// Central API contract: views call these methods instead of constructing URLs themselves.
export const api = {
  getDashboard: () => data(http.get('/dashboard')),
  // Recipe catalogue, details, ingredients, uploads and contributor publishing.
  getRecipes: () => data(http.get('/recipes')),
  getRecipe: (id) => data(http.get(`/recipes/${id}`)),
  getIngredients: () => data(http.get('/ingredients')),
  // These two lists are optional until the database endpoints are deployed.
  getEquipment: () => data(http.get('/equipment', { suppressGlobalError: true })),
  getAllergies: () => data(http.get('/allergies', { suppressGlobalError: true })),
  uploadRecipeImage: (file) => {
    const formData = new FormData()
    formData.append('file', file)
    return data(http.post('/uploads/recipe-image', formData))
  },
  createRecipe: (recipe) => data(http.post('/recipes', recipe)),
  updateRecipe: (id, recipe) => data(http.put(`/recipes/${id}`, recipe)),
  getMyRecipes: () => data(http.get('/my-recipes')),
  async toggleRecipePublication(id) {
    const recipe = await this.getRecipe(id)
    return this.updateRecipe(id, { status: recipe.status === 'Published' ? 'Draft' : 'Published' })
  },
  deleteMyRecipe: (id) => data(http.delete(`/recipes/${id}`)),
  // Recipe feedback is stored independently from the contributor's recipe data.
  addRecipeRating: (id, rating) => data(http.post(`/recipes/${id}/ratings`, { rating })),
  addRecipeComment: (id, text) => data(http.post(`/recipes/${id}/comments`, { text })),
  // Weekly meal-plan entries are the source for calendar and shopping-list data.
  getMealPlan: (weekStart) =>
    data(http.get('/meal-plan', { params: weekStart ? { week_start: weekStart } : {} })),
  saveMealPlanEntry: (entry) => data(http.post('/meal-plan/entries', entry)),
  removeMealPlanEntry: (id) => data(http.delete(`/meal-plan/entries/${id}`)),
  // Shopping list generation combines ingredients across the active meal plan.
  getShoppingList: () => data(http.post('/shopping-list/generate')),
  toggleShoppingItem: (id) => data(http.patch(`/shopping-list/items/${id}/purchased`)),
  // Budget summary is calculated by the backend for the current weekly period.
  getBudgetSummary: () => data(http.get('/budget-summary')),
  // Authentication and profile methods maintain the browser's session cookie.
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
  // Notifications provide both list content and read-state management.
  getNotifications: () => data(http.get('/notifications')),
  markNotificationRead: (id) => data(http.patch(`/notifications/${id}/read`)),
  markAllNotificationsRead: () => data(http.patch('/notifications/read-all')),
  clearReadNotifications: () => data(http.delete('/notifications/read')),
  // Administrator-only moderation and reference-data management.
  getAdminOverview: () => data(http.get('/admin/overview')),
  updateReportStatus: (id, status) => data(http.patch(`/admin/reports/${id}`, { status })),
  createContentReport: (report) => data(http.post('/reports', report)),
  getAdminManagement: () => data(http.get('/admin/management')),
  updateUser: (id, update) => data(http.patch(`/admin/users/${id}`, update)),
  updateAdminRecipeStatus: (id, status) => data(http.patch(`/admin/recipes/${id}`, { status })),
  getIngredientCategories: () => data(http.get('/admin/ingredient-categories')),
  addIngredientCategory: (name) => data(http.post('/admin/ingredient-categories', { name })),
  deleteIngredientCategory: (id) => data(http.delete(`/admin/ingredient-categories/${id}`)),
  // Students use saved recipes for their personal favourites collection.
  toggleSavedRecipe: (id) => data(http.post(`/recipes/${id}/saved`)),
  getSavedRecipeIds: () => data(http.get('/saved-recipes')),
  // AI-assisted natural-language recommendation and smart-search endpoints.
  getAiRecommendation: (query) =>
    data(http.post('/ai/recommendations', { query }, { timeout: 30000 })),
  smartSearch: (query) => data(http.post('/ai/smart-search', { query })),
}
