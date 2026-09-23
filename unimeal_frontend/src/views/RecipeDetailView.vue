<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { api } from '../services/api'

const props = defineProps({ id: { type: String, required: true } })
const recipe = ref(null)
const loading = ref(true)
const selectedRating = ref(0)  // 用户当前选的分数
const ratingSaved = ref(false) // 是否刚评分成功
const saved = ref(false)  // 是否已收藏
const user = ref(null)

const reportOpen = ref(false) // 举报弹窗是否打开
const reportReason = ref('')
const reportMessage = ref('')
const commentText = ref('')  // 评论输入框内容
const commentMessage = ref('')  // 评论反馈消息
const commentError = ref(false)

const reportTarget = ref(null)        // null=举报食谱，有值=举报该评论
const reportCustomText = ref('')      // "Other concern" 时的补充文字


// 评论举报的选项列表
const commentReasons = [
  'Spam or advertising',
  'Offensive or inappropriate language',
  'Misleading information',
  'Off-topic or irrelevant',
  'Other concern',
]

// 食谱举报的选项列表
const recipeReasons = [
  'Incorrect recipe information',
  'Missing allergy warning',
  'Inappropriate image or content',
  'Other concern',
]

// 总时间 = 准备 + 烹饪
const totalTime = computed(() => (recipe.value ? recipe.value.prepTime + recipe.value.cookTime : 0))
// 过敏警告：用户过敏原 ∩ 食谱过敏原
const allergyWarnings = computed(() => {
  const allergies = user.value?.allergies || []
  return (recipe.value?.allergenTags || []).filter((tag) =>
    allergies.some((allergy) => allergy.toLowerCase() === tag.toLowerCase()),
  )
})

onMounted(async () => {
  const [recipeData, currentUser] = await Promise.all([
    api.getRecipe(props.id),
    api.getCurrentUser(),
  ])
  recipe.value = recipeData
  user.value = currentUser
  // 学生才拉收藏状态
  if (currentUser?.role === 'student') {
    const savedIds = await api.getSavedRecipeIds()
    saved.value = savedIds.includes(Number(props.id))
  }
  loading.value = false
})

async function rateRecipe(rating) {
  selectedRating.value = rating  // 点亮星星
  recipe.value = await api.addRecipeRating(props.id, rating)
  ratingSaved.value = true  // 显示"已保存"
}
// 收藏切换
async function toggleSaved() {
  saved.value = (await api.toggleSavedRecipe(props.id)).saved
}

// 打开"举报食谱"弹窗（清空之前的输入）
function openReportRecipe() {
  reportTarget.value = null
  reportReason.value = ''
  reportCustomText.value = ''
  reportOpen.value = true
}

// 打开"举报评论"弹窗
function openReportComment(comment) {
  reportTarget.value = comment  // 记录要举报的评论
  reportReason.value = ''
  reportCustomText.value = ''
  reportOpen.value = true
}
async function submitReport() {
  try {
    // 如果选了 "Other concern" 且有补充文字，拼接到 reason 里
    const finalReason =
      reportReason.value === 'Other concern' && reportCustomText.value.trim()
        ? `Other concern: ${reportCustomText.value.trim()}`
        : reportReason.value

    // 根据 reportTarget 决定举报食谱还是评论
    const payload = reportTarget.value
      ? {
          targetType: 'Comment',
          targetId: reportTarget.value.id,
          reason: finalReason,
        }
      : {
          targetType: 'Recipe',
          targetId: recipe.value.id,
          reason: finalReason,
        }

    await api.createContentReport(payload)
    reportMessage.value = 'Thank you. Your report has been sent to the administrator.'
    reportOpen.value = false

    // 清空所有状态
    reportReason.value = ''
    reportCustomText.value = ''
    reportTarget.value = null
  } catch (error) {
    reportMessage.value = error.message
  }
}

async function submitComment() {
  // 空校验
  if (!commentText.value.trim()) {
    commentError.value = true
    commentMessage.value = 'Please write a comment before submitting.'
    return
  }
  try {
    recipe.value = await api.addRecipeComment(props.id, commentText.value.trim())
    commentText.value = ''
    commentError.value = false
    commentMessage.value = 'Thank you for your comment.'
  } catch (error) {
    commentError.value = true
    commentMessage.value = error.message
  }
}
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div v-if="loading" class="py-5 text-center text-secondary">Loading recipe...</div>
      <div v-else-if="!recipe" class="empty-state p-5 mx-auto detail-empty">
        <h1 class="h4 fw-bold">Recipe not found</h1>
        <RouterLink class="btn btn-primary rounded-pill px-4 mt-3" to="/recipes"
          >Back to recipes</RouterLink
        >
      </div>
      <template v-else>
        <RouterLink class="back-link" to="/recipes">Back to recipe library</RouterLink>
        <article class="surface-card overflow-hidden mt-3">
          <div class="row g-0">
             <!-- Left: image -->
            <div class="col-lg-6 detail-image-wrap">
              <img class="recipe-image" :src="recipe.imageUrl" :alt="recipe.title" />
            </div>
             <!-- Right: info + buttons -->
            <div class="col-lg-6 p-4 p-md-5 d-flex flex-column justify-content-center">
               <!-- Cuisine + dietary tags -->
              <div class="d-flex flex-wrap gap-2 mb-3">
                <span class="soft-badge">{{ recipe.cuisine }}</span
                ><span v-for="tag in recipe.dietaryTags" :key="tag" class="detail-tag">{{
                  tag
                }}</span>
              </div>
              <!-- Title + description -->
              <h1 class="detail-title">{{ recipe.title }}</h1>
              <p class="detail-copy">
                A practical student recipe with clear portions, simple ingredients and estimated
                cost per serving.
              </p>
              <!-- Three meta: time / cost / servings -->
              <div class="row text-center g-2 my-3">
                <div class="col-4">
                  <strong>{{ totalTime }} min</strong><span>Total time</span>
                </div>
                <div class="col-4">
                  <strong>${{ recipe.estimatedCost.toFixed(2) }}</strong
                  ><span>Per serving</span>
                </div>
                <div class="col-4">
                  <strong>{{ recipe.servings }}</strong
                  ><span>Servings</span>
                </div>
              </div>
              <!-- Rating + action buttons -->
              <div class="d-flex align-items-center justify-content-between flex-wrap gap-3">
                <div class="d-flex align-items-center gap-2">
                  <span class="recipe-rating">{{ recipe.rating }} / 5</span
                  ><span class="text-secondary small">from {{ recipe.reviewCount }} ratings</span>
                </div>
                <!--  Report recipe / Save -->
                <div class="d-flex gap-2">
                  <button class="btn btn-outline-secondary btn-sm" @click="openReportRecipe">
                    Report recipe
                  </button>
                  <button v-if="user?.role === 'student'" class="btn btn-outline-primary rounded-pill btn-sm" @click="toggleSaved">
                    {{ saved ? 'Saved to favourites' : 'Save recipe' }}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </article>

        <!-- Allergy warning: only shows if user's and recipe's allergens intersect -->
        <div v-if="allergyWarnings.length" class="alert alert-warning mt-4 mb-0">
          <strong>Allergy warning:</strong> this recipe contains {{ allergyWarnings.join(', ') }}.
        </div>
        <div v-if="recipe.requiredEquipment?.length" class="surface-card p-3 mt-4">
          <strong class="me-2">Required equipment:</strong>
          <span v-for="equipment in recipe.requiredEquipment" :key="equipment.id" class="detail-tag me-2">
            {{ equipment.name }}
          </span>
        </div>

        <div class="row g-4 mt-1">
            <!-- Left: ingredients -->
          <div class="col-lg-4">
            <section class="surface-card p-4 h-100">
              <h2 class="section-heading">Ingredients</h2>
              <p class="text-secondary small">For {{ recipe.servings }} servings</p>
              <ul class="ingredient-list list-unstyled mb-0">
                <li v-for="ingredient in recipe.ingredientDetails" :key="ingredient.ingredientId">
                  <span>{{ ingredient.name }}</span
                  ><strong>{{ ingredient.quantity }} {{ ingredient.unit }}</strong>
                </li>
              </ul>
            </section>
          </div>
          <!-- Right: method -->
          <div class="col-lg-8">
            <section class="surface-card p-4 p-md-5">
              <h2 class="section-heading">Method</h2>
              <ol class="method-list mb-0">
                <li v-for="(step, index) in recipe.steps" :key="step">
                  <span class="step-number">{{ index + 1 }}</span>
                  <p>{{ step }}</p>
                </li>
              </ol>
            </section>
          </div>
        </div>
            <!-- Rating section: 5 circular buttons-->

        <section class="surface-card p-4 p-md-5 mt-4">
          <div class="row g-4 align-items-center">
            <div class="col-md-5">
              <h2 class="section-heading mb-1">Rate this recipe</h2>
              <p class="text-secondary mb-0">Your rating helps other students decide.</p>
            </div>
            <div class="col-md-7">
              <div
                class="rating-actions"
                role="group"
                aria-label="Rate this recipe from one to five"
              >
               <!-- 5 个评分按钮：selected 类控制选中态  -->
                <button
                  v-for="rating in 5"
                  :key="rating"
                  type="button"
                  :class="{ selected: selectedRating >= rating }"
                  :aria-label="`Rate ${rating} out of 5`"
                  @click="rateRecipe(rating)"
                >
                  {{ rating }}
                </button>
              </div>
              <p v-if="ratingSaved" class="saved-note mb-0 mt-2">
                Thanks - your rating has been saved.
              </p>
            </div>
          </div>
        </section>

         <!-- Comments section-->
        <section class="mt-5">
          <div class="d-flex align-items-end justify-content-between mb-3">
            <div>
              <p class="eyebrow">Student feedback</p>
              <h2 class="section-heading mb-0">Comments</h2>
            </div>
            <span class="text-secondary small">{{ recipe.comments.length }} shown</span>
          </div>
          <!-- Comment list -->
          <div v-if="recipe.comments.length" class="row g-3">
            <div v-for="comment in recipe.comments" :key="comment.id" class="col-md-6">
              <article class="surface-card p-4 h-100">
                <div class="d-flex justify-content-between gap-2">
                  <strong>{{ comment.author }}</strong
                  ><span v-if="comment.rating" class="recipe-rating">{{ comment.rating }} / 5</span>
                   <!-- Each comment can be reported -->
                  <button
                    v-if="user"
                    class="btn btn-link btn-sm text-secondary p-0 report-comment-btn"
                    @click="openReportComment(comment)"
                  >
                    Report
                  </button>
                </div>
                <p class="mb-2 mt-3">{{ comment.text }}</p>
                <small class="text-secondary">{{ comment.createdAt }}</small>
              </article>
            </div>
          </div>
           <!-- Empty state -->
          <div v-else class="empty-state p-4">
            No comments yet. Be the first student to share a helpful tip.
          </div>
          <!-- Comment form: students only -->
          <form
            v-if="user?.role === 'student'"
            class="surface-card p-4 mt-4"
            @submit.prevent="submitComment"
          >
            <h3 class="h5 fw-bold">Leave a comment</h3>
            <p class="text-secondary small">
              Share a helpful cooking tip or your experience with this recipe.
            </p>
            <label class="form-label" for="recipe-comment">Your comment</label>
            <textarea
              id="recipe-comment"
              v-model="commentText"
              class="form-control"
              rows="3"
              maxlength="500"
              placeholder="Write your comment here..."
            ></textarea>
            <div class="d-flex justify-content-between align-items-center gap-3 mt-3">
              <small class="text-secondary">{{ commentText.length }} / 500 characters</small
              ><button class="btn btn-primary" type="submit">Submit comment</button>
            </div>
            <p
              v-if="commentMessage"
              class="small mt-3 mb-0"
              :class="commentError ? 'text-danger' : 'text-secondary'"
            >
              {{ commentMessage }}
            </p>
          </form>
          <p v-else-if="!user" class="text-secondary small mt-4 mb-0">
            <RouterLink to="/login">Log in</RouterLink> to leave a comment.
          </p>
        </section>
        <!-- Report success message -->
        <p v-if="reportMessage" class="alert alert-success mt-4 mb-0">{{ reportMessage }}</p>
      </template>

      <!-- 举报弹窗：一个弹窗处理食谱/评论两种举报 -->
      <div v-if="reportOpen" class="modal-backdrop-custom" @click.self="reportOpen = false">
        <section
          class="report-modal surface-card">
           <!-- 根据 reportTarget 切换  -->
          <h2 id="report-title" class="section-heading">
            {{ reportTarget ? 'Report comment' : 'Report recipe' }}</h2>
          <p class="text-secondary">
            {{ reportTarget
              ? 'Tell the administrator why this comment needs review.'
              : 'Tell the administrator why this recipe needs review.' }}
          </p>

          <!--  Dynamic option list -->
          <label class="form-label" for="report-reason">Reason</label
          ><select id="report-reason" v-model="reportReason" class="form-select">
            <option value="">Choose a reason</option>
            <option
              v-for="reason in (reportTarget ? commentReasons : recipeReasons)"
              :key="reason"
              :value="reason"
            >
              {{ reason }}
            </option>
          </select>
          <!-- "Other concern" 时显示的补充输入框 -->
          <div v-if="reportReason === 'Other concern'" class="mt-3">
            <label class="form-label" for="report-custom">Please describe the issue</label>
            <textarea
              id="report-custom"
              v-model="reportCustomText"
              class="form-control"
              rows="3"
              maxlength="200"
              placeholder="Tell us what's wrong..."
            ></textarea>
            <small class="text-secondary">{{ reportCustomText.length }} / 200 characters</small>
          </div>
           <!-- Bottom buttons -->
          <div class="d-flex justify-content-end gap-2 mt-4">
            <button class="btn btn-outline-secondary" type="button" @click="reportOpen = false">
              Cancel</button
            ><button class="btn btn-primary" type="button" @click="submitReport">
              Send report
            </button>
          </div>
        </section>
      </div>
    </div>
  </section>
</template>

<style scoped>
/* ===== 空状态提示区（当食谱不存在时） ===== */
.detail-empty {
  max-width: 35rem;
}

/* ===== 返回链接（"← Back to recipes"） ===== */
.back-link {
  color: var(--um-green);
  font-size: 0.9rem;
  font-weight: 750;
}

/* ===== 图片容器（最小高度，防止加载时塌陷） ===== */
.detail-image-wrap {
  min-height: 22rem;
}

/* ===== 标题通用样式（详情标题 + 区块标题共用） ===== */
.detail-title,
.section-heading {
  color: var(--um-ink);
  font-weight: 800;
  letter-spacing: -0.045em;
}

/* ===== 详情页主标题 ===== */
.detail-title {
  font-size: 2.5rem;
}

/* ===== 详情描述文字 ===== */
.detail-copy {
  color: var(--um-muted);
  margin: 1rem 0;
}

/* ===== 标签小药丸（如 Vegetarian / Gluten Free） ===== */
.detail-tag {
  border-radius: 99px;
  padding: 0.38rem 0.65rem;
  background: #f4efe6;
  color: #676454;
  font-size: 0.76rem;
  font-weight: 750;
}

/* ===== 元信息卡片数字 ===== */
.col-4 strong {
  display: block;
  color: var(--um-green);
  font-size: 1.1rem;
}

/* ===== 元信息卡片文字 ===== */
.col-4 span {
  display: block;
  color: var(--um-muted);
  font-size: 0.72rem;
}

/* ===== 评分数字 ===== */
.recipe-rating {
  color: #9c5a0c;
  font-weight: 800;
}

/* ===== 区块标题（Ingredients / Method 等） ===== */
.section-heading {
  font-size: 1.45rem;
}

/* ===== 食材列表项 ===== */
.ingredient-list li {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.85rem 0;
  border-bottom: 1px solid var(--um-line);
  font-size: 0.94rem;
}

/* ===== 最后一个食材项不要边框 ===== */
.ingredient-list li:last-child {
  border: 0;
}

/* ===== 食材用量（右侧绿色数字） ===== */
.ingredient-list strong {
  color: var(--um-green);
  white-space: nowrap;
}

/* ===== 做法步骤列表（去除默认样式） ===== */
.method-list {
  list-style: none;
  padding: 0;
}

/* ===== 每个步骤项 ===== */
.method-list li {
  display: flex;
  gap: 1rem;
  padding: 0.85rem 0;
}

/* ===== 步骤描述文字 ===== */
.method-list p {
  margin: 0.25rem 0 0;
  line-height: 1.6;
}

/* ===== 步骤序号圆圈（1, 2, 3...） ===== */
.step-number {
  display: flex;
  flex: 0 0 2rem;
  height: 2rem;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  color: var(--um-green);
  background: var(--um-green-light);
  font-weight: 800;
}

/* ===== 评分按钮组容器 ===== */
.rating-actions {
  display: flex;
  gap: 0.45rem;
}

/* ===== 评分按钮 ===== */
.rating-actions button {
  width: 2.25rem;
  height: 2.25rem;
  border: 1px solid #d7d1c4;
  border-radius: 50%;
  color: var(--um-muted);
  background: #fff;
  font-weight: 800;
}

/* ===== 评分按钮被选中或悬停 ===== */
.rating-actions button.selected,
.rating-actions button:hover {
  border-color: var(--um-coral);
  color: #fff;
  background: var(--um-coral);
}

/* ===== “已保存”提示文字 ===== */
.saved-note {
  color: var(--um-green);
  font-size: 0.86rem;
  font-weight: 700;
}
/* ===== 弹窗遮罩 / Modal backdrop ===== */
.modal-backdrop-custom {
  position: fixed;
  z-index: 1050;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  background: rgba(0, 0, 0, 0.45);
}
/* ===== 弹窗本体 / Modal body ===== */
.report-modal {
  width: min(100%, 30rem);
  padding: 1.5rem;
}
.form-label {
  color: var(--um-ink);
  font-size: 0.85rem;
  font-weight: 700;
}
.form-control {
  border-color: #cfd9d3;
}

/* ===== 评论举报按钮 / Comment report button ===== */
.report-comment-btn {
  font-size: 0.76rem;
  font-weight: 700;
  text-decoration: none;
}
.report-comment-btn:hover {
  color: var(--um-coral) !important;
}
/* ===== 平板/手机适配（屏幕宽度小于 992px） ===== */
@media (max-width: 991.98px) {
  .detail-image-wrap {
    height: 18rem;
  }
}
</style>
