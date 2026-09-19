<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import { api, apiError } from './services/api'

const navOpen = ref(false)
const route = useRoute()
const router = useRouter()
const user = ref(null)
const navItems = computed(() => {
  if (!user.value) return [{ label: 'Home', to: '/' }]
  if (user.value.role === 'student') return [{ label: 'Dashboard', to: '/dashboard' }, { label: 'Recipes', to: '/recipes' }, { label: 'Calendar', to: '/calendar' }, { label: 'Shopping List', to: '/shopping-list' }, { label: 'Budget', to: '/budget' }, { label: 'Notifications', to: '/notifications' }, { label: 'AI Helper', to: '/ai-helper' }]
  if (user.value.role === 'contributor') return [{ label: 'Recipes', to: '/recipes' }, { label: 'My Recipes', to: '/my-recipes' }, { label: 'Submit recipe', to: '/submit-recipe' }]
  return [{ label: 'Admin dashboard', to: '/admin' }, { label: 'Manage data', to: '/admin/manage' }]
})

// Logo 点击后应该去哪里（按角色分流）
const logoRoute = computed(() => {
  if (!user.value) return '/'                    // 未登录 → home
  if (user.value.role === 'student') return '/dashboard'
  if (user.value.role === 'contributor') return '/my-recipes'
  return '/admin'                                // 管理员
})
async function refreshUser() {
  try { user.value = await api.getCurrentUser() } catch { user.value = null }
}
onMounted(refreshUser)
watch(() => route.fullPath, () => { apiError.value = ''; refreshUser() })
const closeNav = () => {
  navOpen.value = false
}
async function signOut() {
  await api.signOut()
  await refreshUser()
  closeNav()
  await router.push('/login')
}
</script>

<template>
  <header class="app-header sticky-top">
    <nav class="navbar navbar-expand-lg container py-3" aria-label="Main navigation">
       <!-- Logo -->
      <RouterLink class="navbar-brand d-flex align-items-center gap-2" :to="logoRoute" @click="closeNav">
        <span class="brand-mark" aria-hidden="true">U</span>
        <span>UniMeal</span>
      </RouterLink>
      <!-- 汉堡菜单按钮（移动端） -->
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
      <!-- 折叠区域 -->
      <div id="main-nav" class="collapse navbar-collapse" :class="{ show: navOpen }">
         <!-- 主导航链接 -->
        <ul class="navbar-nav ms-auto align-items-lg-center gap-lg-1">
          <li v-for="item in navItems" :key="item.to" class="nav-item">
            <RouterLink class="nav-link px-3" :to="item.to" @click="closeNav">{{ item.label }}</RouterLink>
          </li>
        </ul>
          <!-- 已登录：头像 + Sign out -->
        <template v-if="user"><RouterLink class="student-avatar ms-lg-3" to="/profile" title="Profile">{{ user.displayName.charAt(0) }}</RouterLink><button class="btn btn-link nav-link ms-lg-2" type="button" @click="signOut">Sign out</button></template>
        <!-- 未登录：Login + Register 按钮 -->
        <div v-else class="d-flex gap-2 ms-lg-3 mt-3 mt-lg-0"><RouterLink class="btn btn-outline-primary btn-sm" to="/login" @click="closeNav">Log in</RouterLink><RouterLink class="btn btn-primary btn-sm" to="/register" @click="closeNav">Register</RouterLink></div>
      </div>
    </nav>
  </header>

  <main class="app-main">
    <div v-if="apiError" class="container mt-3" role="alert">
      <div class="alert alert-danger d-flex justify-content-between align-items-center gap-3">
        <span>{{ apiError }}</span>
        <button class="btn-close" aria-label="Dismiss error" @click="apiError = ''"></button>
      </div>
    </div>
    <RouterView />
  </main>
</template>
