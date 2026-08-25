import axios from 'axios'
import { dashboard, dashboardRecipes } from '../mock/dashboard'
import { recipes } from '../mock/recipes'
import { ingredients } from '../mock/ingredients'

export const http = axios.create({ baseURL: import.meta.env.VITE_API_BASE_URL || '/api', timeout: 8000 })

const clone = (value) => JSON.parse(JSON.stringify(value))

// Replace these mock implementations with http.get(...) once FastAPI endpoints are available.
export const api = {
  async getDashboard() { return clone({ ...dashboard, ...dashboardRecipes }) },
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
}
