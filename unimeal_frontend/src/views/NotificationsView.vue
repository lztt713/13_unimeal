<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '../services/api'
import { updateUnreadNotificationCount } from '../services/notificationState'

const notifications = ref([])
const loading = ref(true)
// The user can switch between the unread inbox and complete notification history.
const view = ref('unread')

// Keep the page tabs and navigation badge based on the same notification state.
const unreadCount = computed(
  () => notifications.value.filter((notification) => !notification.read).length,
)
const readCount = computed(
  () => notifications.value.filter((notification) => notification.read).length,
)
// The selected tab controls the rendered subset without changing saved notification data.
const visibleNotifications = computed(() =>
  view.value === 'unread'
    ? notifications.value.filter((notification) => !notification.read)
    : notifications.value,
)

onMounted(async () => {
  try {
    // Use the same fetched list to initialise the page and global navigation badge.
    notifications.value = await api.getNotifications()
    updateUnreadNotificationCount(notifications.value)
  } finally {
    loading.value = false
  }
})

// Mark one item read without reloading the entire notification list.
async function markAsRead(notification) {
  if (notification.read) return
  const updated = await api.markNotificationRead(notification.id)
  if (updated) {
    notification.read = updated.read
    updateUnreadNotificationCount(notifications.value)
  }
}

// Apply the same state transition to every unread notification.
async function markAllAsRead() {
  notifications.value = await api.markAllNotificationsRead()
  updateUnreadNotificationCount(notifications.value)
}

async function clearRead() {
  // Delete only read items; active reminders remain available to the student.
  await api.clearReadNotifications()
  notifications.value = notifications.value.filter((notification) => !notification.read)
  updateUnreadNotificationCount(notifications.value)
  view.value = 'unread'
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
        <div class="d-flex gap-2">
          <!-- Reading is disabled when there are no unread items; clearing only appears on All. -->
          <button
            class="btn btn-outline-primary"
            type="button"
            :disabled="!unreadCount"
            @click="markAllAsRead"
          >
            Mark all as read
          </button>
          <button
            v-if="view === 'all' && readCount"
            class="btn btn-outline-danger"
            type="button"
            @click="clearRead"
          >
            Clear read
          </button>
        </div>
      </div>

      <div v-if="loading" class="py-5 text-center text-secondary">Loading notifications...</div>
      <template v-else>
        <div class="d-flex gap-2 mb-3">
          <button class="btn btn-sm" :class="view === 'unread' ? 'btn-primary' : 'btn-outline-primary'" @click="view = 'unread'">
            Unread ({{ unreadCount }})
          </button>
          <button class="btn btn-sm" :class="view === 'all' ? 'btn-primary' : 'btn-outline-primary'" @click="view = 'all'">
            All
          </button>
        </div>
        <div v-if="!visibleNotifications.length" class="empty-state p-5">
          <h2 class="h5 fw-bold">You are all caught up.</h2>
          <p class="mb-0">{{ view === 'unread' ? 'New reminders will appear here.' : 'There are no notifications yet.' }}</p>
        </div>
        <!-- Each notification keeps its read state until the student clears it from All. -->
        <div v-else class="surface-card overflow-hidden">
          <article
            v-for="notification in visibleNotifications"
            :key="notification.id"
            class="notification-item"
            :class="{ unread: !notification.read }"
          >
            <!-- The unread class provides a green visual indicator. -->
            <div class="d-flex flex-wrap justify-content-between gap-2">
              <div>
                <div class="d-flex align-items-center gap-2 mb-1">
                  <span class="notification-type">{{ notification.type }}</span>
                  <!-- The New badge is intentionally shown only for unread items. -->
                  <span v-if="!notification.read" class="badge text-bg-primary">New</span>
                </div>
                <!-- Title and message come directly from the backend notification record. -->
                <h2 class="h5 mb-1">{{ notification.title }}</h2>
                <p class="mb-0 text-secondary">{{ notification.message }}</p>
              </div>
              <small class="text-secondary">{{ notification.createdAt }}</small>
            </div>
            <!-- A single-item action is available only until the notification is read. -->
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
      </template>
    </div>
  </section>
</template>

<style scoped>
.notification-page {
  max-width: 60rem;
}
.notification-item {
  /* Separate notification records without adding a heavy card around each one. */
  padding: 1.25rem;
  border-bottom: 1px solid var(--um-line);
}
.notification-item:last-child {
  /* The final item does not need a dividing line. */
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
