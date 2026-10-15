<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../services/api'

// The current administration workspace: users, recipes or ingredient categories.
const activeTab = ref('users')
const management = ref(null)
// Categories are loaded separately because they are reference data, not part of management.
const categories = ref([])
// Keep the draft category value separate from the persisted category list.
const newCategory = ref('')
const error = ref('')

// Load users, recipes and ingredient categories for the three admin tabs.
async function load() {
  management.value = await api.getAdminManagement()
  categories.value = await api.getIngredientCategories()
}
async function updateUser(user, update) {
  // Send only the field that changed, then replace local data with the backend response.
  management.value = await api.updateUser(user.id, update)
}
// Update recipe visibility or moderation status without reloading the page.
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
  // Prevent accidental deletion of a shared reference category.
  if (!window.confirm(`Delete "${category.name}"?`)) return
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
          Manage users, recipe visibility and ingredient categories.
        </p>
      </div>
      <div v-if="!management" class="py-5 text-center text-secondary">Loading platform data...</div>
      <section v-else class="surface-card p-3 p-md-5">
        <!-- Three tabs keep unrelated administrative tasks on one manageable page. -->
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
            <!-- The active class supplies the selected green-pill state. -->
            <button
              class="nav-link"
              :class="{ active: activeTab === tab.id }"
              @click="activeTab = tab.id"
            >
              {{ tab.label }}
            </button>
          </li>
        </ul>
        <!-- User accounts: role and active/suspended status can be updated here. -->
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
                  <!-- Bind the current role without a local copy; changes persist immediately. -->
                  <strong>{{ user.displayName }}</strong
                  ><small>{{ user.email }}</small>
                </td>
                <td>
                  <!-- The action label reflects the next state the administrator will apply. -->
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
        <!-- Recipe moderation controls publishing visibility without editing recipe content. -->
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
                    <option>Archived</option>
                  </select>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <!-- Ingredient categories are shared reference data used by recipe forms and lists. -->
        <div v-else>
          <!-- Submit through Vue to avoid a browser page refresh. -->
          <form class="row g-2 align-items-end mb-4" @submit.prevent="addCategory">
            <div class="col-sm-7 col-md-5">
              <label class="form-label">New category</label
              ><input v-model="newCategory" class="form-control" placeholder="e.g. Dairy" />
            </div>
            <div class="col-sm-auto">
              <button class="btn btn-primary rounded-pill" type="submit">Add category</button>
            </div>
          </form>
          <!-- Backend validation messages stay close to the category form. -->
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
/* Bootstrap's pill navigation is recoloured to match the UniMeal visual system. */
.nav-pills .nav-link {
  color: var(--um-green);
  font-weight: 750;
}
.nav-pills .nav-link.active,
.nav-pills .show > .nav-link {
  color: #fff;
  background: var(--um-green);
}

.table small {
  /* Secondary recipe/user detail appears beneath the main table value. */
  display: block;
  color: var(--um-muted);
}
.form-label {
  color: var(--um-ink);
  font-size: 0.82rem;
  font-weight: 750;
}
.category-card {
  /* Compact cards keep category name, description and delete action together. */
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem;
  border: 1px solid var(--um-line);
  border-radius: 0.8rem;
}
</style>
