<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute } from 'vue-router'
import { api } from './services/api'

const navOpen = ref(false)
const route = useRoute()
const user = ref(null)
const baseItems = [
  { label: 'Home', to: '/' }, { label: 'Dashboard', to: '/dashboard' }, { label: 'Recipes', to: '/recipes' },
  { label: 'Calendar', to: '/calendar' }, { label: 'Shopping List', to: '/shopping-list' }, { label: 'Budget', to: '/budget' }, { label: 'AI Helper', to: '/ai-helper' },
]
const navItems = computed(() => {
  const role = user.value?.role
  const items = [...baseItems]
  if (role === 'contributor' || role === 'administrator') items.splice(3, 0, { label: 'My Recipes', to: '/my-recipes' }, { label: 'Submit', to: '/submit-recipe' })
  if (role === 'administrator') items.push({ label: 'Admin', to: '/admin' })
  return items
})
async function refreshUser() { user.value = await api.getCurrentUser() }
onMounted(refreshUser)
watch(() => route.fullPath, refreshUser)
const closeNav = () => {
  navOpen.value = false
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
        <RouterLink class="student-avatar ms-lg-3" to="/profile" title="Profile">{{ user?.displayName?.charAt(0) || 'U' }}</RouterLink>
      </div>
    </nav>
  </header>

  <main class="app-main">
    <RouterView />
  </main>
</template>
