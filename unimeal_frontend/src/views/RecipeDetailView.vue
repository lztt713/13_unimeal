<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { api } from '../services/api'

const props = defineProps({ id: { type: String, required: true } })
const recipe = ref(null)
const loading = ref(true)
const selectedRating = ref(0)
const ratingSaved = ref(false)

const totalTime = computed(() => recipe.value ? recipe.value.prepTime + recipe.value.cookTime : 0)

onMounted(async () => {
  recipe.value = await api.getRecipe(props.id)
  loading.value = false
})

async function rateRecipe(rating) {
  selectedRating.value = rating
  recipe.value = await api.addRecipeRating(props.id, rating)
  ratingSaved.value = true
}
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div v-if="loading" class="py-5 text-center text-secondary">Loading recipe...</div>
      <div v-else-if="!recipe" class="empty-state p-5 mx-auto detail-empty">
        <h1 class="h4 fw-bold">Recipe not found</h1>
        <RouterLink class="btn btn-primary rounded-pill px-4 mt-3" to="/recipes">Back to recipes</RouterLink>
      </div>
      <template v-else>
        <RouterLink class="back-link" to="/recipes">Back to recipe library</RouterLink>
        <article class="surface-card overflow-hidden mt-3">
          <div class="row g-0">
            <div class="col-lg-6 detail-image-wrap"><img class="recipe-image" :src="recipe.imageUrl" :alt="recipe.title" /></div>
            <div class="col-lg-6 p-4 p-md-5 d-flex flex-column justify-content-center">
              <div class="d-flex flex-wrap gap-2 mb-3"><span class="soft-badge">{{ recipe.cuisine }}</span><span v-for="tag in recipe.dietaryTags" :key="tag" class="detail-tag">{{ tag }}</span></div>
              <h1 class="detail-title">{{ recipe.title }}</h1>
              <p class="detail-copy">A practical student recipe with clear portions, simple ingredients and estimated cost per serving.</p>
              <div class="row text-center g-2 my-3">
                <div class="col-4"><strong>{{ totalTime }} min</strong><span>Total time</span></div>
                <div class="col-4"><strong>${{ recipe.estimatedCost.toFixed(2) }}</strong><span>Per serving</span></div>
                <div class="col-4"><strong>{{ recipe.servings }}</strong><span>Servings</span></div>
              </div>
              <div class="d-flex align-items-center gap-2"><span class="recipe-rating">{{ recipe.rating }} / 5</span><span class="text-secondary small">from {{ recipe.reviewCount }} ratings</span></div>
            </div>
          </div>
        </article>

        <div class="row g-4 mt-1">
          <div class="col-lg-4">
            <section class="surface-card p-4 h-100"><h2 class="section-heading">Ingredients</h2><p class="text-secondary small">For {{ recipe.servings }} servings</p><ul class="ingredient-list list-unstyled mb-0"><li v-for="ingredient in recipe.ingredientDetails" :key="ingredient.ingredientId"><span>{{ ingredient.name }}</span><strong>{{ ingredient.quantity }} {{ ingredient.unit }}</strong></li></ul></section>
          </div>
          <div class="col-lg-8">
            <section class="surface-card p-4 p-md-5"><h2 class="section-heading">Method</h2><ol class="method-list mb-0"><li v-for="(step, index) in recipe.steps" :key="step"><span class="step-number">{{ index + 1 }}</span><p>{{ step }}</p></li></ol></section>
          </div>
        </div>

        <section class="surface-card p-4 p-md-5 mt-4">
          <div class="row g-4 align-items-center"><div class="col-md-5"><h2 class="section-heading mb-1">Rate this recipe</h2><p class="text-secondary mb-0">Your rating helps other students decide.</p></div><div class="col-md-7"><div class="rating-actions" role="group" aria-label="Rate this recipe from one to five"><button v-for="rating in 5" :key="rating" type="button" :class="{ selected: selectedRating >= rating }" :aria-label="`Rate ${rating} out of 5`" @click="rateRecipe(rating)">{{ rating }}</button></div><p v-if="ratingSaved" class="saved-note mb-0 mt-2">Thanks - your mock rating has been saved.</p></div></div>
        </section>

        <section class="mt-5"><div class="d-flex align-items-end justify-content-between mb-3"><div><p class="eyebrow">Student feedback</p><h2 class="section-heading mb-0">Comments</h2></div><span class="text-secondary small">{{ recipe.comments.length }} shown</span></div><div v-if="recipe.comments.length" class="row g-3"><div v-for="comment in recipe.comments" :key="comment.id" class="col-md-6"><article class="surface-card p-4 h-100"><div class="d-flex justify-content-between gap-2"><strong>{{ comment.author }}</strong><span class="recipe-rating">{{ comment.rating }} / 5</span></div><p class="mb-2 mt-3">{{ comment.text }}</p><small class="text-secondary">{{ comment.createdAt }}</small></article></div></div><div v-else class="empty-state p-4">No comments yet. Be the first student to share a helpful tip.</div></section>
      </template>
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
  font-size: .9rem;
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
  letter-spacing: -.045em;
}

/* ===== 详情页主标题（响应式字体） ===== */
.detail-title {
  font-size: clamp(2rem, 4vw, 3.2rem);
}

/* ===== 详情描述文字（作者、简介等） ===== */
.detail-copy {
  color: var(--um-muted);
  margin: 1rem 0;
}

/* ===== 标签小药丸（如 Vegetarian / Gluten Free） ===== */
.detail-tag {
  border-radius: 99px;
  padding: .38rem .65rem;
  background: #f4efe6;
  color: #676454;
  font-size: .76rem;
  font-weight: 750;
}

/* ===== 元信息卡片（时间 / 价格 / 难度中的数字） ===== */
.col-4 strong {
  display: block;
  color: var(--um-green);
  font-size: 1.1rem;
}

/* ===== 元信息卡片（时间 / 价格 / 难度中的标签文字） ===== */
.col-4 span {
  display: block;
  color: var(--um-muted);
  font-size: .72rem;
}

/* ===== 评分星星/数字 ===== */
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
  padding: .85rem 0;
  border-bottom: 1px solid var(--um-line);
  font-size: .94rem;
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
  padding: .85rem 0;
}

/* ===== 步骤描述文字 ===== */
.method-list p {
  margin: .25rem 0 0;
  line-height: 1.6;
}

/* ===== 步骤序号圆圈（1, 2, 3...） ===== */
.step-number {
  display: grid;
  flex: 0 0 2rem;
  height: 2rem;
  place-items: center;
  border-radius: 50%;
  color: var(--um-green);
  background: var(--um-green-light);
  font-weight: 800;
}

/* ===== 评分按钮组容器 ===== */
.rating-actions {
  display: flex;
  gap: .45rem;
}

/* ===== 评分按钮（点赞/踩） ===== */
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
  font-size: .86rem;
  font-weight: 700;
}

/* ===== 平板/手机适配（屏幕宽度小于 992px） ===== */
@media (max-width: 991.98px) {
  .detail-image-wrap {
    height: 18rem;
  }
}
</style>
