<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '../services/api'

const notifications = ref([])
const loading = ref(true)
const unreadCount = computed(
  () => notifications.value.filter((notification) => !notification.read).length,
)

onMounted(async () => {
  try {
    notifications.value = await api.getNotifications()
  } finally {
    loading.value = false
  }
})

async function markAsRead(notification) {
  if (notification.read) return
  const updated = await api.markNotificationRead(notification.id)
  if (updated) notification.read = updated.read
}

async function markAllAsRead() {
  notifications.value = await api.markAllNotificationsRead()
}
</script>

<template>
  <section class="page-shell">
    <div class="container notification-page">
      <div class="d-flex flex-wrap align-items-end justify-content-between gap-3 mb-4">
        <div>
          <p class="eyebrow">Student updates</p>
          <h1 class="page-title mb-1">Notifications</h1>
          <p class="page-subtitle mb-0">
            Keep track of planned meals, shopping reminders and saved recipe updates.
          </p>
        </div>
        <button
          class="btn btn-outline-primary"
          type="button"
          :disabled="!unreadCount"
          @click="markAllAsRead"
        >
          Mark all as read
        </button>
      </div>

      <div v-if="loading" class="py-5 text-center text-secondary">Loading notifications...</div>
      <div v-else-if="!notifications.length" class="empty-state p-5">
        <h2 class="h5 fw-bold">You are all caught up.</h2>
        <p class="mb-0">New meal-plan and shopping reminders will appear here.</p>
      </div>
      <div v-else class="surface-card overflow-hidden">
        <article
          v-for="notification in notifications"
          :key="notification.id"
          class="notification-item"
          :class="{ unread: !notification.read }"
        >
          <div class="d-flex flex-wrap justify-content-between gap-2">
            <div>
              <div class="d-flex align-items-center gap-2 mb-1">
                <span class="notification-type">{{ notification.type }}</span>
                <span v-if="!notification.read" class="badge text-bg-primary">New</span>
              </div>
              <h2 class="h5 mb-1">{{ notification.title }}</h2>
              <p class="mb-0 text-secondary">{{ notification.message }}</p>
            </div>
            <small class="text-secondary">{{ notification.createdAt }}</small>
          </div>
          <button
            v-if="!notification.read"
            class="btn btn-sm btn-outline-secondary mt-3"
            type="button"
            @click="markAsRead(notification)"
          >
            Mark as read
          </button>
        </article>
      </div>
    </div>
  </section>
</template>

<style scoped>
.notification-page {
  max-width: 60rem;
}

.notification-item {
  padding: 1.25rem;
  border-bottom: 1px solid var(--um-line);
}

.notification-item:last-child {
  border-bottom: 0;
}

.notification-item.unread {
  border-left: 4px solid var(--um-green);
  background: #f7fbf8;
}

.notification-type {
  color: var(--um-green);
  font-size: 0.78rem;
  font-weight: 700;
}
</style>
