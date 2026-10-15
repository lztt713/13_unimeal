<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../services/api'

const profile = ref(null)
const saved = ref(false)
// Allergen options are reference data maintained by the platform rather than free text.
const allergyOptions = ref([])
// Recipe data supplies the available cuisine choices so preferences stay consistent.
const allRecipes = ref([])
const tagOptions = ['Vegetarian', 'Vegan', 'Gluten Free', 'High Protein', 'Budget']
const route = useRoute()
const router = useRouter()
const isOnboarding = computed(() => route.query.onboarding === '1')

// Cuisine choices stay aligned with the recipe data returned by the API.
const cuisineOptions = computed(() =>
  [...new Set(allRecipes.value.map((recipe) => recipe.cuisine))].sort(),
)
onMounted(async () => {
  // Load profile data and reference options together to populate the form.
  const [userData, recipesData, availableAllergies] = await Promise.all([
    api.getCurrentUser(),
    api.getRecipes(),
    api.getAllergies().catch(() => []),
  ])
  profile.value = {
    ...userData,
    allergies: userData.allergies || [],
  }
  allRecipes.value = recipesData
  allergyOptions.value = availableAllergies
})

// Save profile changes and complete onboarding for newly registered students.
async function saveProfile() {
  const updatedProfile = await api.updateProfile(profile.value)
  profile.value = {
    ...updatedProfile,
    allergies: updatedProfile.allergies || [],
  }
  if (isOnboarding.value && updatedProfile.role === 'student') {
    await router.push('/dashboard')
    return
  }
  // Show a short success message for normal profile edits outside onboarding.
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
          <!-- The avatar is a lightweight visual identity generated from the display name. -->
          <div class="profile-avatar">{{ profile.displayName.charAt(0) }}</div>
          <div>
            <p class="eyebrow">{{ profile.role }} account</p>
            <h1 class="page-title">{{ profile.displayName }}</h1>
            <p class="page-subtitle mt-1">{{ profile.email }}</p>
          </div>
        </div>
        <section v-if="isOnboarding && profile.role === 'student'" class="onboarding-note mt-4">
          <p class="eyebrow mb-1">Step 1 of 2</p>
          <h2 class="profile-title mb-2">Set up your meal preferences</h2>
          <p class="mb-0">
            Your budget, dietary needs and kitchen access help UniMeal make safer, more useful suggestions.
            You can change these any time.
          </p>
        </section>
        <form class="row g-4 mt-1" @submit.prevent="saveProfile">
          <!-- Students need the preference form; other roles use the full-width account guidance. -->
          <div :class="profile.role === 'student' ? 'col-lg-8' : 'col-lg-12'">
            <!-- Only a student profile affects recommendations, planning and safety checks. -->
            <section v-if="profile.role === 'student'" class="surface-card p-4 p-md-5">
              <h2 class="profile-title">Preferences that shape your plan</h2>
              <div class="row g-3 mt-1">
                <!-- The budget is numeric and displayed with a dollar prefix for clarity. -->
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
                <!-- Cooking skill helps prioritise appropriate recipe difficulty. -->
                <div class="col-md-6">
                  <label class="form-label">Cooking skill</label
                  ><select v-model="profile.cookingSkill" class="form-select">
                    <option>Beginner</option>
                    <option>Comfortable</option>
                    <option>Confident</option>
                  </select>
                </div>
                <!-- Kitchen access is selected from the supported preparation environments. -->
                <div class="col-md-6">
                  <label class="form-label">Kitchen access</label
                  ><select v-model="profile.kitchenAccess" class="form-select">
                    <option>Shared kitchen</option>
                    <option>Private kitchen</option>
                    <option>Limited equipment</option>
                    <option>No kitchen</option>
                  </select>
                </div>
              </div>
              <fieldset class="mt-4">
                <!-- Allergen selections use controlled values so matching is reliable. -->
                <legend class="form-label mb-2">Allergies</legend>
                <div v-if="allergyOptions.length" class="d-flex flex-wrap gap-2">
                  <label v-for="allergy in allergyOptions" :key="allergy.id" class="choice-pill">
                    <input v-model="profile.allergies" type="checkbox" :value="allergy.name" />
                    {{ allergy.name }}
                  </label>
                </div>
                <p v-else class="text-secondary mb-0">No allergen options are configured.</p>
              </fieldset>
              <fieldset class="mt-4">
                <!-- Dietary tags can be combined to represent more than one preference. -->
                <legend class="form-label mb-2">Dietary preferences</legend>
                <div class="d-flex flex-wrap gap-2">
                  <label v-for="tag in tagOptions" :key="tag" class="choice-pill"
                    ><input v-model="profile.dietaryPreferences" type="checkbox" :value="tag" />
                    {{ tag }}</label
                  >
                </div>
              </fieldset>
              <fieldset class="mt-4">
                <!-- Cuisine preferences use values derived from the existing recipe catalogue. -->
                <legend class="form-label mb-2">Favourite cuisines</legend>
                <div class="d-flex flex-wrap gap-2">
                  <label v-for="cuisine in cuisineOptions" :key="cuisine" class="choice-pill"
                    ><input v-model="profile.favouriteCuisines" type="checkbox" :value="cuisine" />
                    {{ cuisine }}</label
                  >
                </div>
              </fieldset>
            </section>
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
          <!-- A sticky save panel remains visible while the student reviews profile preferences. -->
          <aside v-if="profile.role === 'student'" class="col-lg-4">
            <section class="surface-card p-4 sticky-lg-top profile-side">
              <h2 class="profile-title">Save changes</h2>
              <p class="text-secondary">
                Your preferences will be used for future meal recommendations and smart searches.
              </p>
              <button class="btn btn-primary rounded-pill w-100" type="submit">
                {{ isOnboarding ? 'Save and continue' : 'Save profile' }}
              </button>
              <p v-if="saved" class="saved-message mb-0 mt-3">Your profile was updated.</p>
            </section>
          </aside>
        </form></template
      >
    </div>
  </section>
</template>

<style scoped>
/* Header layout keeps the generated avatar and account identity visually connected. */
.profile-header {
  display: flex;
  gap: 1.25rem;
  align-items: center;
}
.profile-avatar {
  /* A circular coral avatar distinguishes account identity from recipe imagery. */
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
.form-control,
.form-select,
.input-group-text {
  /* All profile controls share the same border and rounded-corner treatment. */
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
.input-group .form-control {
  /* The budget input joins cleanly to its dollar-prefix addon. */
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}
.choice-pill {
  /* Checkbox options are displayed as compact, easily scannable pill controls. */
  border: 1px solid var(--um-line);
  border-radius: 99px;
  padding: 0.38rem 0.65rem;
  font-size: 0.82rem;
  cursor: pointer;
}
.profile-side {
  top: 6rem;
}
.onboarding-note {
  padding: 1.25rem 1.5rem;
  border-left: 4px solid var(--um-green);
  border-radius: 0.5rem;
  background: var(--um-green-light);
  color: var(--um-ink);
}
.saved-message {
  color: var(--um-green);
  font-size: 0.85rem;
  font-weight: 750;
}
</style>
