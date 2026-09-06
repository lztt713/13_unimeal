import axios from 'axios'
import { recipes as mockRecipes } from '../mock/recipes'
import { adminOverview, currentUser } from '../mock/users'

export const http = axios.create({ baseURL: import.meta.env.VITE_API_BASE_URL || '/api', timeout: 8000 })

const clone = (value) => JSON.parse(JSON.stringify(value))
const responseData = async (request) => (await request).data

export const api = {
  async getDashboard() { return responseData(http.get('/dashboard')) },
  async getRecipes(params = {}) { return responseData(http.get('/recipes', { params })) },
  async getRecipe(recipeId) { return responseData(http.get(`/recipes/${Number(recipeId)}`)) },
  async getIngredients() { return responseData(http.get('/ingredients')) },
  async createRecipe(recipe) { return responseData(http.post('/recipes', recipe)) },
  async updateRecipe(recipeId, recipe) { return responseData(http.put(`/recipes/${Number(recipeId)}`, recipe)) },
  async getMyRecipes() { return responseData(http.get('/my-recipes')) },
  async toggleRecipePublication(recipeId) {
    const recipe = await this.getRecipe(recipeId)
    const status = recipe.status === 'Published' ? 'Draft' : 'Published'
    return this.updateRecipe(recipeId, { status })
  },
  async deleteMyRecipe(recipeId) { return responseData(http.delete(`/recipes/${Number(recipeId)}`)) },
  async addRecipeRating(recipeId, rating) { return responseData(http.post(`/recipes/${Number(recipeId)}/ratings`, { rating })) },
  async getMealPlan(weekStart) { return responseData(http.get('/meal-plan', { params: weekStart ? { week_start: weekStart } : {} })) },
  async saveMealPlanEntry(entry) {
    return entry.id
      ? responseData(http.put(`/meal-plan/entries/${Number(entry.id)}`, entry))
      : responseData(http.post('/meal-plan/entries', entry))
  },
  async removeMealPlanEntry(entryId) { return responseData(http.delete(`/meal-plan/entries/${Number(entryId)}`)) },
  async getShoppingList(weekStart) { return responseData(http.post('/shopping-list/generate', null, { params: weekStart ? { week_start: weekStart } : {} })) },
  async toggleShoppingItem(itemId) { return responseData(http.patch(`/shopping-list/items/${Number(itemId)}/purchased`)) },
  async getBudgetSummary() { return responseData(http.get('/budget-summary')) },
  async getCurrentUser() { return clone(currentUser) },
  async signIn({ email, role }) {
    Object.assign(currentUser, { email: email || currentUser.email, role: role || currentUser.role })
    return clone(currentUser)
  },
  async register({ name, email }) {
    Object.assign(currentUser, { displayName: name || currentUser.displayName, email: email || currentUser.email, role: 'student' })
    return clone(currentUser)
  },
  async updateProfile(profile) { Object.assign(currentUser, clone(profile)); return clone(currentUser) },
  async getAdminOverview() { return clone(adminOverview) },
  async updateReportStatus(reportId, status) {
    const report = adminOverview.reports.find((item) => item.id === reportId)
    if (report) report.status = status
    return clone(adminOverview)
  },
  async getAdminManagement() { return clone({ users: adminOverview.users, recipes: mockRecipes }) },
  async updateUser(userId, update) {
    const user = adminOverview.users.find((item) => item.id === Number(userId))
    if (user) Object.assign(user, update)
    return this.getAdminManagement()
  },
  async updateAdminRecipeStatus(recipeId, status) {
    const recipe = mockRecipes.find((item) => item.id === Number(recipeId))
    if (recipe) recipe.status = status
    return this.getAdminManagement()
  },
  async getIngredientCategories() { return clone(adminOverview.ingredientCategories) },
  async addIngredientCategory(name) {
    const trimmed = name.trim()
    if (!trimmed) throw new Error('Category name is required')
    if (adminOverview.ingredientCategories.some((category) => category.name.toLowerCase() === trimmed.toLowerCase())) throw new Error('This category already exists')
    adminOverview.ingredientCategories.push({ id: Date.now(), name: trimmed, description: 'Custom category' })
    return this.getIngredientCategories()
  },
  async deleteIngredientCategory(categoryId) {
    const index = adminOverview.ingredientCategories.findIndex((item) => item.id === Number(categoryId))
    if (index >= 0) adminOverview.ingredientCategories.splice(index, 1)
    return this.getIngredientCategories()
  },
  async toggleSavedRecipe(recipeId) {
    return responseData(http.post(`/recipes/${Number(recipeId)}/saved`))
  },
  async getSavedRecipeIds() { return responseData(http.get('/saved-recipes')) },
  async getAiRecommendation(query) {
    const normalized = query.trim().toLowerCase()
    const matches = mockRecipes.filter((recipe) => [recipe.title, recipe.cuisine, ...recipe.ingredients, ...recipe.dietaryTags].join(' ').toLowerCase().includes(normalized) || recipe.dietaryTags.some((tag) => normalized.includes(tag.toLowerCase())))
    return clone({ query, mode: 'mock', summary: 'Based on your request, these recipes balance cost, time and dietary tags.', recipes: matches.length ? matches.slice(0, 3) : mockRecipes.filter((recipe) => recipe.estimatedCost <= 5).slice(0, 3), cautions: ['Check ingredient labels against your allergies.', 'Estimated costs can vary by supermarket.'] })
  },
}
