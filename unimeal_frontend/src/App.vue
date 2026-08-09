<script setup>
import { ref } from 'vue'
import { RouterLink, RouterView } from 'vue-router'

const navOpen = ref(false)
const closeNav = () => {
  navOpen.value = false
}
</script>

<template>
  <header class="app-header sticky-top">
    <nav class="navbar navbar-expand-lg container py-3" aria-label="Main navigation">
      <RouterLink class="navbar-brand d-flex align-items-center gap-2" to="/dashboard" @click="closeNav">
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
          <li v-for="item in [
            { label: 'Dashboard', to: '/dashboard' }, { label: 'Recipes', to: '/recipes' },
            { label: 'Calendar', to: '/calendar' }, { label: 'Shopping List', to: '/shopping-list' },
            { label: 'Budget', to: '/budget' }, { label: 'AI Helper', to: '/ai-helper' },
          ]" :key="item.to" class="nav-item">
            <RouterLink class="nav-link px-3" :to="item.to" @click="closeNav">{{ item.label }}</RouterLink>
          </li>
        </ul>
        <span class="student-avatar ms-lg-3" title="Student account">M</span>
      </div>
    </nav>
  </header>

  <main class="app-main">
    <RouterView />
  </main>
</template>
