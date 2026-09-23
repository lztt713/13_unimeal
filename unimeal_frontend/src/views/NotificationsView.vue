<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '../services/api'
import { updateUnreadNotificationCount } from '../services/notificationState'

const notifications = ref([])
const loading = ref(true)
const view = ref('unread')  // 当前视图：'unread' 或 'all'
// ---------- Computed: unread count ----------
// 未读数
const unreadCount = computed(
  () => notifications.value.filter((notification) => !notification.read).length,
)
// 已读数
const readCount = computed(
  () => notifications.value.filter((notification) => notification.read).length,
)
// 当前显示的通知列表（根据 view 切换）
const visibleNotifications = computed(() =>
  view.value === 'unread'
    ? notifications.value.filter((notification) => !notification.read) // 只看未读
    : notifications.value,   // 全部
)

onMounted(async () => {
  try {
    notifications.value = await api.getNotifications()
    updateUnreadNotificationCount(notifications.value) // 同步全局未读数
  } finally {
    loading.value = false
  }
})

// ----------  mark one as read ----------
async function markAsRead(notification) {
  if (notification.read) return  // 已经读过了，不做任何事
  const updated = await api.markNotificationRead(notification.id)
  if (updated) {
    notification.read = updated.read
    updateUnreadNotificationCount(notifications.value)  //  同步全局未读数
  }
}

// --------- mark all as read -----
async function markAllAsRead() {
  notifications.value = await api.markAllNotificationsRead()
  updateUnreadNotificationCount(notifications.value)
}

async function clearRead() {
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
          <!-- Button disabled when no unread notifications -->
          <button
            class="btn btn-outline-primary"
            type="button"
            :disabled="!unreadCount"
            @click="markAllAsRead"
          >
            Mark all as read
          </button>
          <button
            class="btn btn-outline-danger"
            type="button"
            :disabled="!readCount"
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
        <!-- Notification list -->
        <div v-else class="surface-card overflow-hidden">
          <article
            v-for="notification in visibleNotifications"
            :key="notification.id"
            class="notification-item"
            :class="{ unread: !notification.read }"
          >
           <!-- "unread" class adds green left border + light green background -->
            <div class="d-flex flex-wrap justify-content-between gap-2">
              <div>
                <div class="d-flex align-items-center gap-2 mb-1">
                  <span class="notification-type">{{ notification.type }}</span>
                  <!--  "New" badge (only if unread) -->
                  <span v-if="!notification.read" class="badge text-bg-primary">New</span>
                </div>
                <!-- Title -->
                <h2 class="h5 mb-1">{{ notification.title }}</h2>
                <p class="mb-0 text-secondary">{{ notification.message }}</p>
              </div>
              <small class="text-secondary">{{ notification.createdAt }}</small>
            </div>
            <!-- "Mark as read" only shows when unread -->
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
/* 每一条通知 */
.notification-item {
  padding: 1.25rem;
  border-bottom: 1px solid var(--um-line);
}
/* 最后一条去掉下边框 */
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
