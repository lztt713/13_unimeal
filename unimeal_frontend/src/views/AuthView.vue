<script setup>
// Reuse the same component to render login or register UI based on route mode
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../services/api'
// Receive route prop: mode ('login' or 'register')
const props = defineProps({ mode: { type: String, required: true } })
// Get router instance for programmatic navigation
const router = useRouter()
// Form data container: name, email, password, role
const form = ref({ name: '', email: '', password: '', role: 'student' })
// State management: error message, saving state
const error = ref('')
const saving = ref(false)
//Computed property: determine if current mode is 'register'
const isRegister = computed(() => props.mode === 'register')

// Submit logic: validate -> request -> redirect -> exception handling
async function submit() {
  error.value = ''
   // Frontend validation: check required fields
  if (!form.value.email || !form.value.password || (isRegister.value && !form.value.name)) {
    error.value = 'Please complete all required fields.'
    return
  }
  saving.value = true
  try {
  // Call register or login API based on the current mode
    const user = isRegister.value ? await api.register(form.value) : await api.signIn(form.value)
    // 根据角色决定跳转目标
    const defaultRoute =
      user.role === 'administrator'
        ? '/admin'
        : user.role === 'contributor'
          ? '/my-recipes'
          : '/dashboard'
// Redirect: prioritize query.redirect from route guard (e.g., originally wanted /calendar)
    router.push(
      typeof router.currentRoute.value.query.redirect === 'string'
        ? router.currentRoute.value.query.redirect
        : defaultRoute,
    )
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
      <!-- 响应式：中屏占 8/12，大屏占 5/12，保证表单不会太宽 -->
        <div class="col-md-8 col-lg-5">
          <article class="surface-card p-4 p-md-5">
            <p class="eyebrow">UniMeal account</p>
            <!-- Dynamic title: switch text based on isRegister -->
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
              <!-- Register-only fields (hidden in login mode) -->
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
              <!-- Common fields: email and password -->
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
             <!-- Bottom switch link: toggle between login and register -->
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
  /* background: linear-gradient(135deg, #f7f4ed, #edf4e9); */
}
/* Main title: dark ink color, bold, tight letter spacing */
.auth-title {
  color: var(--um-ink);
  font-size: 2.25rem;
  font-weight: 800;
  letter-spacing: -0.05em;
}
/* Input field: rounded corners, padding, focus turns brand green */
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
