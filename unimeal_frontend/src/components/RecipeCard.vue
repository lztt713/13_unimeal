<script setup>
defineProps({
  recipe: { type: Object, required: true },
  allergyWarnings: { type: Array, default: () => [] },
})
</script>

<template>
  <article class="surface-card recipe-card h-100">
    <div class="recipe-card-image position-relative">
      <img class="recipe-image" :src="recipe.imageUrl" :alt="recipe.title" />
      <span class="price-pill">${{ recipe.estimatedCost.toFixed(2) }}</span>
    </div>
    <div class="p-3 p-md-4">
      <div class="d-flex align-items-center justify-content-between gap-2 mb-2">
        <span class="soft-badge">{{ recipe.cuisine }}</span>
        <span class="rating"
          >★ {{ recipe.rating }} <small>({{ recipe.reviewCount }})</small></span
        >
      </div>
      <h2 class="recipe-card-title">{{ recipe.title }}</h2>
      <div class="d-flex gap-3 mt-3 recipe-meta">
        <span>{{ recipe.cookTime }} min</span><span>{{ recipe.difficulty }}</span>
      </div>
      <div class="mt-3 d-flex flex-wrap gap-1">
        <span v-for="tag in recipe.dietaryTags" :key="tag" class="diet-tag">{{ tag }}</span>
      </div>
      <p v-if="allergyWarnings.length" class="allergy-warning mb-0 mt-3">
        Allergy warning: contains {{ allergyWarnings.join(', ') }}
      </p>
      <RouterLink class="stretched-link" :to="`/recipes/${recipe.id}`"
        ><span class="visually-hidden">View {{ recipe.title }}</span></RouterLink
      >
    </div>
  </article>
</template>

<style scoped>
/* ===== 卡片容器：相对定位 + 平滑动画 ===== */
.recipe-card {
  position: relative;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
}

/* ===== 卡片悬停效果（微微上浮 + 阴影） ===== */
.recipe-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 15px 35px rgba(50, 68, 47, 0.12);
}

/* ===== 卡片图片区域 ===== */
.recipe-card-image {
  height: 11.5rem;
  overflow: hidden;
}

/* ===== 价格标签（右上角的“小药丸”） ===== */
.price-pill {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  border-radius: 99px;
  padding: 0.32rem 0.6rem;
  color: #fff;
  background: rgba(36, 48, 36, 0.88);
  font-size: 0.78rem;
  font-weight: 800;
}

/* ===== 卡片标题 ===== */
.recipe-card-title {
  margin: 0;
  color: var(--um-ink);
  font-size: 1.08rem;
  font-weight: 800;
  letter-spacing: -0.025em;
}

/* ===== 评星等级 ===== */
.rating {
  color: #a65f10;
  font-size: 0.82rem;
  font-weight: 750;
}

.rating small {
  color: var(--um-muted);
  font-weight: 600;
}

/* ===== 烹饪元信息（时间、难度等） ===== */
.recipe-meta {
  color: var(--um-muted);
  font-size: 0.83rem;
  font-weight: 650;
}

/* ===== 饮食标签（素食、无麸质等） ===== */
.diet-tag {
  border-radius: 99px;
  padding: 0.2rem 0.48rem;
  color: #6b7167;
  background: #f2f0ea;
  font-size: 0.7rem;
  font-weight: 700;
}

.allergy-warning {
  color: #8a4b08;
  font-size: 0.78rem;
  font-weight: 700;
}
</style>
