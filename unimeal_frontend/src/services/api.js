import axios from 'axios'
import { dashboard, dashboardRecipes } from '../mock/dashboard'
import { recipes } from '../mock/recipes'

export const http = axios.create({ baseURL: import.meta.env.VITE_API_BASE_URL || '/api', timeout: 8000 })

const clone = (value) => JSON.parse(JSON.stringify(value))

// Replace these mock implementations with http.get(...) once FastAPI endpoints are available.
export const api = {
  async getDashboard() { return clone({ ...dashboard, ...dashboardRecipes }) },
  async getRecipes() { return clone(recipes) },
}
