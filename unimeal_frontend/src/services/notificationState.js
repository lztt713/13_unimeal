import { ref } from 'vue'

// This shared value drives the notification badge in the application header.
export const unreadNotificationCount = ref(0)

// Recalculate the badge after a page loads or a notification is marked as read.
export function updateUnreadNotificationCount(notifications) {
  unreadNotificationCount.value = notifications.filter((notification) => !notification.read).length
}
