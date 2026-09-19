import axios from 'axios'
import { ref } from 'vue'

// 全局错误信息：任何请求失败，都会写进这个变量
// 页面可以在顶部监听它，统一弹一个错误提示
export const apiError = ref('')
// 创建 axios 实例（整个项目共用这一个实例）
export const http = axios.create({
  // 后端地址：优先读环境变量，没有就用 /api（开发时代理到后端）
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
// 辅助函数：把 axios 的 { data, status, headers } 外壳剥掉
// 只返回真正的业务数据，让页面代码更干净
const data = (request) => request.then((response) => response.data)
// ---------- 所有后端接口的清单 ----------
export const api = {
  getDashboard: () => data(http.get('/dashboard')),
  // ===== 食谱相关 =====
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
 // ===== 评分 & 评论 =====
  addRecipeRating: (id, rating) => data(http.post(`/recipes/${id}/ratings`, { rating })),
  addRecipeComment: (id, text) => data(http.post(`/recipes/${id}/comments`, { text })),
  // ===== 饮食计划 =====
  getMealPlan: () => data(http.get('/meal-plan')),
  saveMealPlanEntry: (entry) => data(http.post('/meal-plan/entries', entry)),
  removeMealPlanEntry: (id) => data(http.delete(`/meal-plan/entries/${id}`)),
  // ===== 购物清单 =====
  getShoppingList: () => data(http.post('/shopping-list/generate')),
  toggleShoppingItem: (id) => data(http.patch(`/shopping-list/items/${id}/purchased`)),
   // ===== 预算 =====
  getBudgetSummary: () => data(http.get('/budget-summary')),
   // ===== 认证相关 =====
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
 // ===== 通知 =====
  getNotifications: () => data(http.get('/notifications')),
  markNotificationRead: (id) => data(http.patch(`/notifications/${id}/read`)),
  markAllNotificationsRead: () => data(http.patch('/notifications/read-all')),
  // ===== 管理员 =====
  getAdminOverview: () => data(http.get('/admin/overview')),
  updateReportStatus: (id, status) => data(http.patch(`/admin/reports/${id}`, { status })),
  createContentReport: (report) => data(http.post('/reports', report)),
  getAdminManagement: () => data(http.get('/admin/management')),
  updateUser: (id, update) => data(http.patch(`/admin/users/${id}`, update)),
  updateAdminRecipeStatus: (id, status) => data(http.patch(`/admin/recipes/${id}`, { status })),
  getIngredientCategories: () => data(http.get('/admin/ingredient-categories')),
  addIngredientCategory: (name) => data(http.post('/admin/ingredient-categories', { name })),
  deleteIngredientCategory: (id) => data(http.delete(`/admin/ingredient-categories/${id}`)),
  // ===== 收藏 =====
  toggleSavedRecipe: (id) => data(http.post(`/recipes/${id}/saved`)),
  getSavedRecipeIds: () => data(http.get('/saved-recipes')),
  // ===== AI =====
  getAiRecommendation: (query) => data(http.post('/ai/recommendations',{ query },{ timeout: 30000 },),),
}
