import { ref } from 'vue'

export const unreadNotificationCount = ref(0)

export function updateUnreadNotificationCount(notifications) {
  unreadNotificationCount.value = notifications.filter((notification) => !notification.read).length
}
