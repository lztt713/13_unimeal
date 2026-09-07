<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../services/api'

const activeTab = ref('users')
const management = ref(null)
const categories = ref([])
const newCategory = ref('')
const error = ref('')

async function load() {
  management.value = await api.getAdminManagement()
  categories.value = await api.getIngredientCategories()
}
async function updateUser(user, update) {
  management.value = await api.updateUser(user.id, update)
}
async function updateRecipe(recipe, status) {
  management.value = await api.updateAdminRecipeStatus(recipe.id, status)
}
async function addCategory() {
  try {
    error.value = ''
    categories.value = await api.addIngredientCategory(newCategory.value)
    newCategory.value = ''
  } catch (err) {
    error.value = err.message
  }
}
async function removeCategory(category) {
  categories.value = await api.deleteIngredientCategory(category.id)
}
onMounted(load)
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div class="mb-4">
        <p class="eyebrow">Administrator workspace</p>
        <h1 class="page-title">Manage platform data.</h1>
        <p class="page-subtitle">
          Mock controls mirror the user, recipe and ingredient-category tables in the current
          schema.
        </p>
      </div>
      <div v-if="!management" class="py-5 text-center text-secondary">Loading platform data...</div>
      <section v-else class="surface-card p-3 p-md-5">
        <ul class="nav nav-pills gap-2 mb-4">
          <li
            class="nav-item"
            v-for="tab in [
              { id: 'users', label: 'Users' },
              { id: 'recipes', label: 'Recipes' },
              { id: 'categories', label: 'Ingredient categories' },
            ]"
            :key="tab.id"
          >
            <button
              class="nav-link"
              :class="{ active: activeTab === tab.id }"
              @click="activeTab = tab.id"
            >
              {{ tab.label }}
            </button>
          </li>
        </ul>
        <div v-if="activeTab === 'users'" class="table-responsive">
          <table class="table align-middle">
            <thead>
              <tr>
                <th>User</th>
                <th>Role</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="user in management.users" :key="user.id">
                <td>
                  <strong>{{ user.displayName }}</strong
                  ><small>{{ user.email }}</small>
                </td>
                <td>
                  <select
                    class="form-select form-select-sm"
                    :value="user.role"
                    @change="updateUser(user, { role: $event.target.value })"
                  >
                    <option value="student">Student</option>
                    <option value="contributor">Contributor</option>
                    <option value="administrator">Administrator</option>
                  </select>
                </td>
                <td>
                  <button
                    class="btn btn-sm rounded-pill"
                    :class="user.status === 'Active' ? 'btn-outline-danger' : 'btn-outline-primary'"
                    @click="
                      updateUser(user, {
                        status: user.status === 'Active' ? 'Suspended' : 'Active',
                      })
                    "
                  >
                    {{ user.status === 'Active' ? 'Suspend' : 'Activate' }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else-if="activeTab === 'recipes'" class="table-responsive">
          <table class="table align-middle">
            <thead>
              <tr>
                <th>Recipe</th>
                <th>Cost</th>
                <th>Visibility</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="recipe in management.recipes" :key="recipe.id">
                <td>
                  <strong>{{ recipe.title }}</strong
                  ><small>{{ recipe.cuisine }} · {{ recipe.difficulty }}</small>
                </td>
                <td>${{ recipe.estimatedCost.toFixed(2) }}</td>
                <td>
                  <select
                    class="form-select form-select-sm"
                    :value="recipe.status || 'Published'"
                    @change="updateRecipe(recipe, $event.target.value)"
                  >
                    <option>Published</option>
                    <option>Draft</option>
                    <option>Hidden</option>
                  </select>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else>
          <form class="row g-2 align-items-end mb-4" @submit.prevent="addCategory">
            <div class="col-sm-7 col-md-5">
              <label class="form-label">New category</label
              ><input v-model="newCategory" class="form-control" placeholder="e.g. Dairy" />
            </div>
            <div class="col-sm-auto">
              <button class="btn btn-primary rounded-pill" type="submit">Add category</button>
            </div>
          </form>
          <p v-if="error" class="text-danger small">{{ error }}</p>
          <div class="row g-3">
            <article v-for="category in categories" :key="category.id" class="col-md-6">
              <div class="category-card">
                <div>
                  <strong>{{ category.name }}</strong>
                  <p class="mb-0 text-secondary small">{{ category.description }}</p>
                </div>
                <button class="btn btn-link text-danger btn-sm" @click="removeCategory(category)">
                  Delete
                </button>
              </div>
            </article>
          </div>
        </div>
      </section>
    </div>
  </section>
</template>

<style scoped>
.nav-pills .nav-link {
  color: var(--um-green);
  font-weight: 750;
}
.nav-pills .nav-link.active,
.nav-pills .show > .nav-link {
  color: #fff;
  background: var(--um-green);
}
.nav-pills .nav-link.active:hover,
.nav-pills .nav-link.active:focus {
  color: #fff;
  background: #274a23;
}
.table small {
  display: block;
  color: var(--um-muted);
}
.form-label {
  color: var(--um-ink);
  font-size: 0.82rem;
  font-weight: 750;
}
.category-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem;
  border: 1px solid var(--um-line);
  border-radius: 0.8rem;
}
</style>
