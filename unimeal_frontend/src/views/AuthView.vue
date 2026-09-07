<script setup>
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../services/api'

const props = defineProps({ mode: { type: String, required: true } })
const router = useRouter()
const form = ref({ name: '', email: '', password: '', role: 'student' })
const error = ref('')
const saving = ref(false)
const isRegister = computed(() => props.mode === 'register')

async function submit() {
  error.value = ''
  if (!form.value.email || !form.value.password || (isRegister.value && !form.value.name)) {
    error.value = 'Please complete all required fields.'
    return
  }
  saving.value = true
  try {
    const user = isRegister.value ? await api.register(form.value) : await api.signIn(form.value)
    const defaultRoute =
      user.role === 'administrator'
        ? '/admin'
        : user.role === 'contributor'
          ? '/my-recipes'
          : '/dashboard'
    router.push(
      typeof router.currentRoute.value.query.redirect === 'string'
        ? router.currentRoute.value.query.redirect
        : defaultRoute,
    )
  } catch {
    error.value = 'We could not complete that request. Please try again.'
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
                <p class="info-note text-start mt-2">
                  Administrator accounts are created and managed by the system administrator.
                </p>
              </div>
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
                />
              </div>
              <button class="btn btn-primary rounded-pill w-100 py-2" :disabled="saving">
                {{ saving ? 'Please wait...' : isRegister ? 'Create account' : 'Sign in' }}
              </button>
            </form>
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
  background: linear-gradient(135deg, #f7f4ed, #edf4e9);
}
.auth-title {
  color: var(--um-ink);
  font-size: 2.25rem;
  font-weight: 800;
  letter-spacing: -0.05em;
}
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
.info-note {
  color: var(--um-muted);
  font-size: 0.72rem;
  text-align: center;
}
</style>
