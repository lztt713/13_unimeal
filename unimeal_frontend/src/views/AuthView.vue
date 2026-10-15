<script setup>
// Reuse the same component to render login or registration UI based on the route mode.
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../services/api'
// The route provides either "login" or "register" as the mode prop.
const props = defineProps({ mode: { type: String, required: true } })
// Use the router after a successful request to enter the correct role workflow.
const router = useRouter()
// The form supports the complete registration payload and the smaller login payload.
const form = ref({ name: '', email: '', password: '', role: 'student' })
// These values provide inline validation feedback and prevent duplicate submission.
const error = ref('')
const saving = ref(false)
// Determine which fields and labels should be rendered for the current mode.
const isRegister = computed(() => props.mode === 'register')

// Validate locally, call the relevant authentication endpoint, then redirect by role.
async function submit() {
  error.value = ''
  // Perform simple required-field validation before making a network request.
  if (!form.value.email || !form.value.password || (isRegister.value && !form.value.name)) {
    error.value = 'Please complete all required fields.'
    return
  }
  saving.value = true
  try {
    // Registration creates an account; login reuses the existing account credentials.
    const user = isRegister.value ? await api.register(form.value) : await api.signIn(form.value)
    // Send each role to its own starting page after authentication.
    const defaultRoute =
      user.role === 'administrator'
        ? '/admin'
        : user.role === 'contributor'
          ? '/my-recipes'
          : '/dashboard'
    // A new student needs to set the preferences that drive recommendations before planning.
    // Existing users still return to their requested page or normal dashboard.
    if (isRegister.value && user.role === 'student') {
      router.push({ path: '/profile', query: { onboarding: '1' } })
    } else {
      router.push(
        typeof router.currentRoute.value.query.redirect === 'string'
          ? router.currentRoute.value.query.redirect
          : defaultRoute,
      )
    }
  } catch (err) {
    error.value = err.message
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <section class="auth-page">
    <div class="container">
      <div class="row justify-content-center">
        <div class="col-md-8 col-lg-5">
          <article class="surface-card p-4 p-md-5">
            <p class="eyebrow">UniMeal account</p>
            <!-- The shared screen changes its title and helper text for login or registration. -->
            <h1 class="auth-title">
              {{ isRegister ? 'Create your UniMeal account.' : 'Welcome back.' }}
            </h1>
            <p class="text-secondary mb-4">
              {{
                isRegister
                  ? 'Choose an account type and start using UniMeal.'
                  : 'Sign in to continue your meal plan.'
              }}
            </p>
            <form @submit.prevent="submit">
              <div v-if="error" class="alert alert-danger">{{ error }}</div>
              <!-- These fields are needed only while creating a new account. -->
              <div v-if="isRegister" class="mb-3">
                <label class="form-label" for="name">Display name</label
                ><input id="name" v-model="form.name" class="form-control" />
              </div>
              <div v-if="isRegister" class="mb-3">
                <label class="form-label" for="account-type">Account type</label
                ><select id="account-type" v-model="form.role" class="form-select">
                  <option value="student">Student</option>
                  <option value="contributor">Recipe contributor</option>
                </select>
              </div>
              <!-- Existing and new accounts both use email and password credentials. -->
              <div class="mb-3">
                <label class="form-label" for="email">Email</label
                ><input id="email" v-model="form.email" class="form-control" type="email" />
              </div>
              <div class="mb-4">
                <label class="form-label" for="password">Password</label
                ><input
                  id="password"
                  v-model="form.password"
                  class="form-control"
                  type="password"
                  :minlength="isRegister ? 8 : 1"
                  :autocomplete="isRegister ? 'new-password' : 'current-password'"
                />
              </div>
              <button class="btn btn-primary rounded-pill w-100 py-2" :disabled="saving">
                {{ saving ? 'Please wait...' : isRegister ? 'Create account' : 'Sign in' }}
              </button>
            </form>
            <!-- Let visitors switch between the two authentication paths without losing context. -->
            <p class="small text-secondary text-center mt-4 mb-0">
              {{ isRegister ? 'Already have an account?' : 'New to UniMeal?' }}
              <RouterLink :to="isRegister ? '/login' : '/register'">{{
                isRegister ? 'Sign in' : 'Create one'
              }}</RouterLink>
            </p>
          </article>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.auth-page {
  min-height: calc(100vh - 73px);
  padding: 5rem 0;
}
/* The authentication page keeps its form vertically centred with generous whitespace. */
.auth-title {
  color: var(--um-ink);
  font-size: 2.25rem;
  font-weight: 800;
  letter-spacing: -0.05em;
}
/* Form labels and controls share the product's rounded, high-contrast input style. */
.form-label {
  color: var(--um-ink);
  font-size: 0.85rem;
  font-weight: 750;
}
.form-control {
  border-color: var(--um-line);
  border-radius: 0.7rem;
  padding: 0.7rem 0.8rem;
}
.form-control:focus {
  border-color: var(--um-green);
  box-shadow: 0 0 0 0.2rem rgba(49, 87, 44, 0.12);
}
</style>
