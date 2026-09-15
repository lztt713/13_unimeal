import 'bootstrap/dist/css/bootstrap.min.css'
import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { apiError } from './services/api'

const app = createApp(App)
app.config.errorHandler = (error) => {
  apiError.value = error.message || 'Something went wrong. Please try again.'
}
router.onError((error) => { apiError.value = error.message })
app.use(router)
app.mount('#app')
