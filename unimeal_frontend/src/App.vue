<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute } from 'vue-router'
import { api } from './services/api'

const navOpen = ref(false)
const route = useRoute()
const user = ref(null)
const navItems = computed(() => {
  if (!user.value) return [{ label: 'Home', to: '/' }]
  if (user.value.role === 'student') return [{ label: 'Dashboard', to: '/dashboard' }, { label: 'Recipes', to: '/recipes' }, { label: 'Calendar', to: '/calendar' }, { label: 'Shopping List', to: '/shopping-list' }, { label: 'Budget', to: '/budget' }, { label: 'Notifications', to: '/notifications' }, { label: 'AI Helper', to: '/ai-helper' }]
  if (user.value.role === 'contributor') return [{ label: 'Recipes', to: '/recipes' }, { label: 'My Recipes', to: '/my-recipes' }, { label: 'Submit recipe', to: '/submit-recipe' }]
  return [{ label: 'Admin dashboard', to: '/admin' }, { label: 'Manage data', to: '/admin/manage' }]
})
async function refreshUser() { user.value = await api.getCurrentUser() }
onMounted(refreshUser)
watch(() => route.fullPath, refreshUser)
const closeNav = () => {
  navOpen.value = false
}
async function signOut() {
  await api.signOut()
  await refreshUser()
  closeNav()
}
</script>

<template>
  <header class="app-header sticky-top">
    <nav class="navbar navbar-expand-lg container py-3" aria-label="Main navigation">
      <RouterLink class="navbar-brand d-flex align-items-center gap-2" to="/" @click="closeNav">
        <span class="brand-mark" aria-hidden="true">U</span>
        <span>UniMeal</span>
      </RouterLink>
      <button
        class="navbar-toggler border-0 shadow-none"
        type="button"
        aria-controls="main-nav"
        :aria-expanded="navOpen"
        aria-label="Toggle navigation"
        @click="navOpen = !navOpen"
      >
        <span class="navbar-toggler-icon"></span>
      </button>
      <div id="main-nav" class="collapse navbar-collapse" :class="{ show: navOpen }">
        <ul class="navbar-nav ms-auto align-items-lg-center gap-lg-1">
          <li v-for="item in navItems" :key="item.to" class="nav-item">
            <RouterLink class="nav-link px-3" :to="item.to" @click="closeNav">{{ item.label }}</RouterLink>
          </li>
        </ul>
        <template v-if="user"><RouterLink class="student-avatar ms-lg-3" to="/profile" title="Profile">{{ user.displayName.charAt(0) }}</RouterLink><button class="btn btn-link nav-link ms-lg-2" type="button" @click="signOut">Sign out</button></template>
        <div v-else class="d-flex gap-2 ms-lg-3 mt-3 mt-lg-0"><RouterLink class="btn btn-outline-primary btn-sm" to="/login" @click="closeNav">Log in</RouterLink><RouterLink class="btn btn-primary btn-sm" to="/register" @click="closeNav">Register</RouterLink></div>
      </div>
    </nav>
  </header>

  <main class="app-main">
    <RouterView />
  </main>
</template>
