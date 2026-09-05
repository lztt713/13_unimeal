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
  if (!form.value.email || !form.value.password || (isRegister.value && !form.value.name)) { error.value = 'Please complete all required fields.'; return }
  saving.value = true
  try { isRegister.value ? await api.register(form.value) : await api.signIn(form.value); router.push('/dashboard') }
  catch { error.value = 'We could not complete that request. Please try again.' }
  finally { saving.value = false }
}
</script>

<template>
  <section class="auth-page"><div class="container"><div class="row justify-content-center"><div class="col-md-8 col-lg-5"><article class="surface-card p-4 p-md-5"><p class="eyebrow">UniMeal account</p><h1 class="auth-title">{{ isRegister ? 'Create your UniMeal account.' : 'Welcome back.' }}</h1><p class="text-secondary mb-4">{{ isRegister ? 'Start planning student-friendly meals in a few steps.' : 'Sign in to continue your meal plan.' }}</p><form @submit.prevent="submit"><div v-if="error" class="alert alert-danger">{{ error }}</div><div v-if="isRegister" class="mb-3"><label class="form-label" for="name">Display name</label><input id="name" v-model="form.name" class="form-control" /></div><div class="mb-3"><label class="form-label" for="email">Email</label><input id="email" v-model="form.email" class="form-control" type="email" /></div><div v-if="!isRegister" class="mb-3"><label class="form-label" for="demo-role">Demo role</label><select id="demo-role" v-model="form.role" class="form-select"><option value="student">Student</option><option value="contributor">Recipe contributor</option><option value="administrator">Administrator</option></select><p class="mock-note text-start mt-2">For frontend demonstration only; the backend will derive this from the authenticated account.</p></div><div class="mb-4"><label class="form-label" for="password">Password</label><input id="password" v-model="form.password" class="form-control" type="password" /></div><button class="btn btn-primary rounded-pill w-100 py-2" :disabled="saving">{{ saving ? 'Please wait...' : isRegister ? 'Create account' : 'Sign in' }}</button></form><p class="small text-secondary text-center mt-4 mb-0">{{ isRegister ? 'Already have an account?' : 'New to UniMeal?' }} <RouterLink :to="isRegister ? '/login' : '/register'">{{ isRegister ? 'Sign in' : 'Create one' }}</RouterLink></p><p class="mock-note mb-0 mt-3">Mock authentication only. Password handling will be provided by the backend.</p></article></div></div></div></section>
</template>

<style scoped>
.auth-page { min-height: calc(100vh - 73px); padding: 5rem 0; background: linear-gradient(135deg, #f7f4ed, #edf4e9); }.auth-title { color: var(--um-ink); font-size: 2.25rem; font-weight: 800; letter-spacing: -.05em; }.form-label { color: var(--um-ink); font-size: .85rem; font-weight: 750; }.form-control { border-color: var(--um-line); border-radius: .7rem; padding: .7rem .8rem; }.form-control:focus { border-color: var(--um-green); box-shadow: 0 0 0 .2rem rgba(49,87,44,.12); }.mock-note { color: var(--um-muted); font-size: .72rem; text-align: center; }
</style>
