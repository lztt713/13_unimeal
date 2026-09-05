import axios from 'axios'
import { dashboard, dashboardRecipes } from '../mock/dashboard'
import { recipes } from '../mock/recipes'
import { ingredients } from '../mock/ingredients'
import { budgetSummary, weeklyPlan } from '../mock/planning'
import { adminOverview, currentUser } from '../mock/users'

export const http = axios.create({ baseURL: import.meta.env.VITE_API_BASE_URL || '/api', timeout: 8000 })

const clone = (value) => JSON.parse(JSON.stringify(value))
const purchasedShoppingItemKeys = new Set()
const contributorRecipeIds = new Set([1, 2, 3])

function mergedShoppingItems(recipeIds) {
  const items = new Map()
  recipes.filter((recipe) => recipeIds.includes(recipe.id)).forEach((recipe) => {
    recipe.ingredientDetails.forEach((ingredient) => {
      const key = `${ingredient.ingredientId}-${ingredient.unit}`
      const current = items.get(key) || { ...ingredient, totalQuantity: 0, estimatedCost: 0, purchased: purchasedShoppingItemKeys.has(key) }
      current.totalQuantity += ingredient.quantity
      current.estimatedCost += 1.2
      items.set(key, current)
    })
  })
  return [...items.values()]
}

// Replace these mock implementations with http.get(...) once FastAPI endpoints are available.
export const api = {
  async getDashboard() {
    const now = new Date()
    const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
    const tonightEntry = weeklyPlan.entries.find((entry) => entry.plannedDate === today && entry.mealType === 'Dinner')
    const tonight = recipes.find((recipe) => recipe.id === tonightEntry?.recipeId) || dashboardRecipes.tonight
    return clone({ ...dashboard, ...dashboardRecipes, favourites: recipes.filter((recipe) => dashboard.favouriteRecipeIds.includes(recipe.id)), tonight })
  },
  async getRecipes() { return clone(recipes) },
  async getRecipe(recipeId) {
    return clone(recipes.find((recipe) => recipe.id === Number(recipeId)) || null)
  },
  async getIngredients() { return clone(ingredients) },
  async createRecipe(recipe) {
    const savedRecipe = { ...clone(recipe), id: Date.now(), authorId: currentUser.id, status: 'Draft', rating: 0, reviewCount: 0, comments: [] }
    recipes.unshift(savedRecipe)
    contributorRecipeIds.add(savedRecipe.id)
    return clone(savedRecipe)
  },
  async updateRecipe(recipeId, recipe) {
    const index = recipes.findIndex((item) => item.id === Number(recipeId))
    if (index < 0) throw new Error('Recipe not found')
    recipes[index] = { ...recipes[index], ...clone(recipe), id: recipes[index].id }
    return clone(recipes[index])
  },
  async getMyRecipes() { return clone(recipes.filter((recipe) => contributorRecipeIds.has(recipe.id))) },
  async toggleRecipePublication(recipeId) {
    const recipe = recipes.find((item) => item.id === Number(recipeId))
    if (!recipe) throw new Error('Recipe not found')
    recipe.status = recipe.status === 'Published' ? 'Draft' : 'Published'
    return clone(recipe)
  },
  async deleteMyRecipe(recipeId) {
    const index = recipes.findIndex((item) => item.id === Number(recipeId))
    if (index >= 0) recipes.splice(index, 1)
    contributorRecipeIds.delete(Number(recipeId))
    return clone({ id: Number(recipeId) })
  },
  async addRecipeRating(recipeId, rating) {
    const recipe = recipes.find((item) => item.id === Number(recipeId))
    if (!recipe) throw new Error('Recipe not found')
    recipe.rating = Number(((recipe.rating * recipe.reviewCount + rating) / (recipe.reviewCount + 1)).toFixed(1))
    recipe.reviewCount += 1
    return clone(recipe)
  },
  async getMealPlan() { return clone(weeklyPlan) },
  async saveMealPlanEntry(entry) {
    const existing = weeklyPlan.entries.find((item) => item.plannedDate === entry.plannedDate && item.mealType === entry.mealType)
    if (existing) Object.assign(existing, { ...entry, id: existing.id })
    else weeklyPlan.entries.push({ ...entry, id: Date.now() })
    return clone(weeklyPlan)
  },
  async removeMealPlanEntry(entryId) {
    const index = weeklyPlan.entries.findIndex((item) => item.id === entryId)
    if (index >= 0) weeklyPlan.entries.splice(index, 1)
    return clone(weeklyPlan)
  },
  async getShoppingList() {
    const recipeIds = [...new Set(weeklyPlan.entries.map((entry) => entry.recipeId))]
    const items = mergedShoppingItems(recipeIds)
    return clone({ id: 1, recipeIds, status: 'active', items, totalEstimatedCost: items.reduce((sum, item) => sum + item.estimatedCost, 0) })
  },
  async toggleShoppingItem(ingredientId, unit) {
    const key = `${ingredientId}-${unit}`
    if (purchasedShoppingItemKeys.has(key)) purchasedShoppingItemKeys.delete(key)
    else purchasedShoppingItemKeys.add(key)
    return this.getShoppingList()
  },
  async getBudgetSummary() { return clone(budgetSummary) },
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
  async getAdminManagement() { return clone({ users: adminOverview.users, recipes }) },
  async updateUser(userId, update) {
    const user = adminOverview.users.find((item) => item.id === Number(userId))
    if (user) Object.assign(user, update)
    return this.getAdminManagement()
  },
  async updateAdminRecipeStatus(recipeId, status) {
    const recipe = recipes.find((item) => item.id === Number(recipeId))
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
    const id = Number(recipeId)
    const index = dashboard.favouriteRecipeIds.indexOf(id)
    if (index >= 0) dashboard.favouriteRecipeIds.splice(index, 1)
    else dashboard.favouriteRecipeIds.push(id)
    return clone({ saved: index < 0 })
  },
  async getSavedRecipeIds() { return clone(dashboard.favouriteRecipeIds) },
  async getAiRecommendation(query) {
    const normalized = query.trim().toLowerCase()
    const matches = recipes.filter((recipe) => [recipe.title, recipe.cuisine, ...recipe.ingredients, ...recipe.dietaryTags].join(' ').toLowerCase().includes(normalized) || recipe.dietaryTags.some((tag) => normalized.includes(tag.toLowerCase())))
    return clone({ query, mode: 'mock', summary: 'Based on your request, these recipes balance cost, time and dietary tags.', recipes: matches.length ? matches.slice(0, 3) : recipes.filter((recipe) => recipe.estimatedCost <= 5).slice(0, 3), cautions: ['Check ingredient labels against your allergies.', 'Estimated costs can vary by supermarket.'] })
  },
}
