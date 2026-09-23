<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '../services/api'

const profile = ref(null)
const saved = ref(false)
const allergyOptions = ref([])
const selectedAllergy = ref('No known allergies')
const allRecipes = ref([])   // 所有食谱（用于动态提取菜系）
const tagOptions = ['Vegetarian', 'Vegan', 'Gluten Free', 'High Protein', 'Budget']
// 菜系：从食谱数据动态提取
const cuisineOptions = computed(() =>
  [...new Set(allRecipes.value.map((recipe) => recipe.cuisine))].sort(),
)
onMounted(async () => {
  // 并行请求用户资料 + 所有食谱
  const [userData, recipesData, availableAllergies] = await Promise.all([
    api.getCurrentUser(),
    api.getRecipes(),
    api.getAllergies().catch(() => []),
  ])
  profile.value = {
    ...userData,
    allergies: userData.allergies || [],
  }
  selectedAllergy.value = userData.allergies?.[0] || 'No known allergies'
  allRecipes.value = recipesData
  allergyOptions.value = availableAllergies
})

// ----------save profile (students only)
async function saveProfile() {
  const allergies = selectedAllergy.value === 'No known allergies' ? [] : [selectedAllergy.value]
  const updatedProfile = await api.updateProfile({ ...profile.value, allergies })
  profile.value = {
    ...updatedProfile,
    allergies: updatedProfile.allergies || [],
  }
  selectedAllergy.value = updatedProfile.allergies?.[0] || 'No known allergies'
  // Show "saved" toast, auto-hide after 2.5s
  saved.value = true
  setTimeout(() => {
    saved.value = false
  }, 2500)
}
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div v-if="!profile" class="py-5 text-center text-secondary">Loading your profile...</div>
      <template v-else
        ><div class="profile-header surface-card p-4 p-md-5">
           <!-- Avatar: first letter of display name -->
          <div class="profile-avatar">{{ profile.displayName.charAt(0) }}</div>
          <div>
            <p class="eyebrow">{{ profile.role }} account</p>
            <h1 class="page-title">{{ profile.displayName }}</h1>
            <p class="page-subtitle mt-1">{{ profile.email }}</p>
          </div>
        </div>
        <form class="row g-4 mt-1" @submit.prevent="saveProfile">
          <!-- Left column width dynamic: 8 for students, 12 for others -->
          <div :class="profile.role === 'student' ? 'col-lg-8' : 'col-lg-12'">
             <!-- Student-only: full preference form -->
            <section v-if="profile.role === 'student'" class="surface-card p-4 p-md-5">
              <h2 class="profile-title">Preferences that shape your plan</h2>
              <div class="row g-3 mt-1">
                <!--  Budget input with $ prefix -->
                <div class="col-md-6">
                  <label class="form-label">Weekly food budget</label>
                  <div class="input-group">
                    <span class="input-group-text">$</span
                    ><input
                      v-model.number="profile.weeklyBudget"
                      class="form-control"
                      type="number"
                      min="0"
                      step="0.01"
                    />
                  </div>
                </div>
                 <!--  Cooking skill -->
                <div class="col-md-6">
                  <label class="form-label">Cooking skill</label
                  ><select v-model="profile.cookingSkill" class="form-select">
                    <option>Beginner</option>
                    <option>Comfortable</option>
                    <option>Confident</option>
                  </select>
                </div>
                <!--  Kitchen access -->
                <div class="col-md-6">
                  <label class="form-label">Kitchen access</label
                  ><select v-model="profile.kitchenAccess" class="form-select">
                    <option>Shared kitchen</option>
                    <option>Private kitchen</option>
                    <option>Limited equipment</option>
                    <option>No kitchen</option>
                  </select>
                </div>
                <div class="col-md-6">
                  <label class="form-label">Allergies</label>
                  <select v-model="selectedAllergy" class="form-select">
                    <option value="No known allergies">No known allergies</option>
                    <option
                      v-for="allergy in allergyOptions.filter((item) => item.name !== 'No known allergies')"
                      :key="allergy.id"
                      :value="allergy.name"
                    >
                      {{ allergy.name }}
                    </option>
                  </select>
                </div>
              </div>
              <fieldset class="mt-4">
                <legend class="form-label mb-2">Dietary preferences</legend>
                <div class="d-flex flex-wrap gap-2">
                  <label v-for="tag in tagOptions" :key="tag" class="choice-pill"
                    ><input v-model="profile.dietaryPreferences" type="checkbox" :value="tag" />
                    {{ tag }}</label
                  >
                </div>
              </fieldset>
              <fieldset class="mt-4">
                <legend class="form-label mb-2">Favourite cuisines</legend>
                <div class="d-flex flex-wrap gap-2">
                  <label v-for="cuisine in cuisineOptions" :key="cuisine" class="choice-pill"
                    ><input v-model="profile.favouriteCuisines" type="checkbox" :value="cuisine" />
                    {{ cuisine }}</label
                  >
                </div>
              </fieldset>
            </section>
            <!-- ========== 贡献者专属 ========== -->
            <section v-else-if="profile.role === 'contributor'" class="surface-card p-4 p-md-5">
              <h2 class="profile-title">Your contributor account</h2>
              <p class="text-secondary mb-3">
                As a recipe contributor, your focus is on creating and managing recipes.
              </p>
              <p class="text-secondary mb-0">
                Manage your recipes from the
                <RouterLink to="/my-recipes">My Recipes</RouterLink> page.
              </p>
            </section>
            <!-- （管理员） -->
            <section v-else class="surface-card p-4 p-md-5">
              <h2 class="profile-title">Your administrator account</h2>
               <p class="text-secondary mb-3">
                As an administrator, your focus is on managing users, recipes, ingredient categories,
                and reported content.
              </p>
              <p class="text-secondary mb-0">
                Go to the
                <RouterLink to="/admin">Admin dashboard</RouterLink>
                to manage platform data.
              </p>
            </section>

          </div>
          <!-- Right: Save changes card (students only) -->
          <aside v-if="profile.role === 'student'" class="col-lg-4">
            <section class="surface-card p-4 sticky-lg-top profile-side">
              <h2 class="profile-title">Save changes</h2>
              <p class="text-secondary">
                Your preferences will be used for future meal recommendations and smart searches.
              </p>
              <button class="btn btn-primary rounded-pill w-100" type="submit">Save profile</button>
              <p v-if="saved" class="saved-message mb-0 mt-3">Your profile was updated.</p>
            </section>
          </aside>
        </form></template
      >
    </div>
  </section>
</template>

<style scoped>

.profile-header {
  display: flex;
  gap: 1.25rem;
  align-items: center;
}
/* ===== 圆形头像  ===== */
.profile-avatar {
  display: flex;
  width: 4.5rem;
  height: 4.5rem;
  flex: 0 0 4.5rem;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  color: #fff;
  background: var(--um-coral);
  font-size: 1.7rem;
  font-weight: 800;
}
.profile-title {
  color: var(--um-ink);
  font-size: 1.35rem;
  font-weight: 800;
}
.form-label {
  color: var(--um-ink);
  font-size: 0.83rem;
  font-weight: 750;
}
/* ===== 表单控件边框和圆角 ===== */
.form-control,
.form-select,
.input-group-text {
  border-color: var(--um-line);
  border-radius: 0.7rem;
}
.form-control,
.form-select {
  padding: 0.65rem 0.8rem;
}
.input-group .input-group-text {
  border-top-right-radius: 0;
  border-bottom-right-radius: 0;
}
/* 输入框：只保留右侧圆角  */
.input-group .form-control {
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}
.choice-pill {
  border: 1px solid var(--um-line);
  border-radius: 99px;
  padding: 0.38rem 0.65rem;
  font-size: 0.82rem;
  cursor: pointer;
}
.profile-side {
  top: 6rem;
}
.saved-message {
  color: var(--um-green);
  font-size: 0.85rem;
  font-weight: 750;
}
</style>
