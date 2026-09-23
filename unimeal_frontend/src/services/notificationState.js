import { ref } from 'vue'

export const unreadNotificationCount = ref(0)  //存未读通知数
//接收通知数组，数出未读的，写入全局变量
export function updateUnreadNotificationCount(notifications) {
  unreadNotificationCount.value = notifications.filter((notification) => !notification.read).length
}
