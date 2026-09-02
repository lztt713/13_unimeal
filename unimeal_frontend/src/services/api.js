import axios from 'axios'
import { dashboard, dashboardRecipes } from '../mock/dashboard'
import { recipes } from '../mock/recipes'
import { ingredients } from '../mock/ingredients'
import { budgetSummary, weeklyPlan } from '../mock/planning'

export const http = axios.create({ baseURL: import.meta.env.VITE_API_BASE_URL || '/api', timeout: 8000 })

const clone = (value) => JSON.parse(JSON.stringify(value))
const purchasedShoppingItemKeys = new Set()

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
    return clone({ ...dashboard, ...dashboardRecipes, tonight })
  },
  async getRecipes() { return clone(recipes) },
  async getRecipe(recipeId) {
    return clone(recipes.find((recipe) => recipe.id === Number(recipeId)) || null)
  },
  async getIngredients() { return clone(ingredients) },
  async createRecipe(recipe) {
    const savedRecipe = { ...clone(recipe), id: Date.now(), rating: 0, reviewCount: 0, comments: [] }
    recipes.unshift(savedRecipe)
    return clone(savedRecipe)
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
}
