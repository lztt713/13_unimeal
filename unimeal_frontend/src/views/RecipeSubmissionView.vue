<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../services/api'

const router = useRouter()
const route = useRoute()
const ingredients = ref([])
const submitted = ref(false)
const errors = ref([])
const form = ref({ title: '', imageUrl: '', cuisine: '', difficulty: 'Easy', prepTime: 10, cookTime: 20, servings: 2, dietaryTags: [], ingredients: [{ ingredientId: '', quantity: '', unit: 'g' }], steps: [''] })
const tagOptions = ['Vegetarian', 'Vegan', 'Gluten Free', 'High Protein', 'Budget']
const previewUrl = computed(() => form.value.imageUrl || 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=900&q=80')

onMounted(async () => {
  ingredients.value = await api.getIngredients()
  if (!route.query.edit) return
  const recipe = await api.getRecipe(route.query.edit)
  if (!recipe) return
  form.value = {
    title: recipe.title,
    imageUrl: recipe.imageUrl,
    cuisine: recipe.cuisine,
    difficulty: recipe.difficulty,
    prepTime: recipe.prepTime,
    cookTime: recipe.cookTime,
    servings: recipe.servings,
    dietaryTags: recipe.dietaryTags,
    ingredients: recipe.ingredientDetails.map((item) => ({ ingredientId: item.ingredientId, quantity: item.quantity, unit: item.unit })),
    steps: recipe.steps,
  }
})
function addIngredient() { form.value.ingredients.push({ ingredientId: '', quantity: '', unit: 'g' }) }
function removeIngredient(index) { if (form.value.ingredients.length > 1) form.value.ingredients.splice(index, 1) }
function setIngredientUnit(row) { const item = ingredients.value.find((ingredient) => ingredient.id === Number(row.ingredientId)); if (item) row.unit = item.defaultUnit }
function addStep() { form.value.steps.push('') }
function removeStep(index) { if (form.value.steps.length > 1) form.value.steps.splice(index, 1) }
async function submitRecipe() {
  errors.value = []
  if (!form.value.title.trim()) errors.value.push('Recipe title is required.')
  if (!form.value.cuisine.trim()) errors.value.push('Cuisine is required.')
  if (Number(form.value.servings) < 1) errors.value.push('Servings must be at least 1.')
  if (form.value.ingredients.some((row) => !row.ingredientId || Number(row.quantity) <= 0)) errors.value.push('Each ingredient needs a selection and positive quantity.')
  if (form.value.steps.some((step) => !step.trim())) errors.value.push('Each method step needs text.')
  if (errors.value.length) return
  const details = form.value.ingredients.map((row) => ({ ingredientId: Number(row.ingredientId), name: ingredients.value.find((item) => item.id === Number(row.ingredientId)).name, quantity: Number(row.quantity), unit: row.unit }))
  const payload = { ...form.value, prepTime: Number(form.value.prepTime), cookTime: Number(form.value.cookTime), servings: Number(form.value.servings), estimatedCost: 0, ingredients: details.map((item) => item.name.toLowerCase()), ingredientDetails: details, steps: form.value.steps.map((step) => step.trim()) }
  const recipe = route.query.edit ? await api.updateRecipe(route.query.edit, payload) : await api.createRecipe(payload)
  submitted.value = true
  setTimeout(() => router.push(`/recipes/${recipe.id}`), 700)
}
</script>

<template>
  <section class="page-shell"><div class="container"><div class="submission-intro"><p class="eyebrow">Recipe contributor</p><h1 class="page-title">Share a student-friendly recipe.</h1><p class="page-subtitle">This form saves recipes, ingredients and method steps to the shared database.</p></div><form class="row g-4 mt-1" @submit.prevent="submitRecipe"><div class="col-lg-8"><section class="surface-card p-4 p-md-5"><h2 class="form-heading">Recipe details</h2><div v-if="errors.length" class="alert alert-danger"><ul class="mb-0"><li v-for="error in errors" :key="error">{{ error }}</li></ul></div><div class="row g-3"><div class="col-md-8"><label class="form-label" for="title">Title</label><input id="title" v-model="form.title" class="form-control" maxlength="200" /></div><div class="col-md-4"><label class="form-label" for="cuisine">Cuisine</label><input id="cuisine" v-model="form.cuisine" class="form-control" /></div><div class="col-md-4"><label class="form-label" for="difficulty">Difficulty</label><select id="difficulty" v-model="form.difficulty" class="form-select"><option>Easy</option><option>Medium</option><option>Hard</option></select></div><div class="col-md-4"><label class="form-label" for="prep">Prep minutes</label><input id="prep" v-model="form.prepTime" class="form-control" type="number" min="0" /></div><div class="col-md-4"><label class="form-label" for="cook">Cook minutes</label><input id="cook" v-model="form.cookTime" class="form-control" type="number" min="0" /></div><div class="col-md-4"><label class="form-label" for="servings">Servings</label><input id="servings" v-model="form.servings" class="form-control" type="number" min="1" /></div></div><fieldset class="mt-4"><legend class="form-label mb-2">Dietary tags</legend><div class="d-flex flex-wrap gap-2"><label v-for="tag in tagOptions" :key="tag" class="tag-choice"><input v-model="form.dietaryTags" type="checkbox" :value="tag" /> {{ tag }}</label></div></fieldset></section><section class="surface-card p-4 p-md-5 mt-4"><div class="d-flex justify-content-between align-items-center mb-3"><h2 class="form-heading mb-0">Ingredients</h2><button class="btn btn-outline-primary btn-sm rounded-pill" type="button" @click="addIngredient">Add ingredient</button></div><div v-for="(row, index) in form.ingredients" :key="index" class="ingredient-row row g-2 align-items-end"><div class="col-md-6"><label class="form-label">Ingredient</label><select v-model="row.ingredientId" class="form-select" @change="setIngredientUnit(row)"><option value="">Select ingredient</option><option v-for="ingredient in ingredients" :key="ingredient.id" :value="ingredient.id">{{ ingredient.name }}</option></select></div><div class="col-5 col-md-3"><label class="form-label">Quantity</label><input v-model="row.quantity" class="form-control" type="number" min="0.01" step="0.01" /></div><div class="col-4 col-md-2"><label class="form-label">Unit</label><input v-model="row.unit" class="form-control" /></div><div class="col-3 col-md-1"><button class="btn btn-link text-danger p-1" type="button" :disabled="form.ingredients.length === 1" @click="removeIngredient(index)">Remove</button></div></div></section><section class="surface-card p-4 p-md-5 mt-4"><div class="d-flex justify-content-between align-items-center mb-3"><h2 class="form-heading mb-0">Method</h2><button class="btn btn-outline-primary btn-sm rounded-pill" type="button" @click="addStep">Add step</button></div><div v-for="(step, index) in form.steps" :key="index" class="step-row d-flex gap-2"><span>{{ index + 1 }}</span><textarea v-model="form.steps[index]" class="form-control" rows="2" :aria-label="`Step ${index + 1}`"></textarea><button class="btn btn-link text-danger p-1 align-self-center" type="button" :disabled="form.steps.length === 1" @click="removeStep(index)">Remove</button></div></section></div><aside class="col-lg-4"><section class="surface-card p-4 sticky-lg-top preview-card"><h2 class="form-heading">Image preview</h2><img class="preview-image" :src="previewUrl" alt="Recipe preview" /><label class="form-label mt-3" for="image">Image URL</label><input id="image" v-model="form.imageUrl" class="form-control" type="url" placeholder="https://..." /><p class="small text-secondary mt-3">Image file upload will be connected after the backend storage endpoint is agreed. A URL keeps the current database field consistent.</p><button class="btn btn-primary rounded-pill w-100 mt-2" type="submit" :disabled="submitted">{{ submitted ? 'Saved - opening recipe...' : 'Submit recipe' }}</button></section></aside></form></div></section>
</template>

<style scoped>
/* ===== 提交页面标题区 ===== */
.submission-intro {
  max-width: 46rem;
}

/* ===== 表单标题 ===== */
.form-heading {
  color: var(--um-ink);
  font-size: 1.35rem;
  font-weight: 800;
  letter-spacing: -.03em;
}

/* ===== 表单标签 ===== */
.form-label {
  color: var(--um-ink);
  font-size: .82rem;
  font-weight: 750;
}

/* ===== 表单输入框 + 下拉框（通用样式） ===== */
.form-control,
.form-select {
  border-color: var(--um-line);
  border-radius: .7rem;
  padding: .65rem .8rem;
}

/* ===== 表单控件聚焦状态 ===== */
.form-control:focus,
.form-select:focus {
  border-color: var(--um-green);
  box-shadow: 0 0 0 .2rem rgba(49, 87, 44, .12);
}

/* ===== 饮食标签选择（"药丸"样式） ===== */
.tag-choice {
  border: 1px solid var(--um-line);
  border-radius: 99px;
  padding: .38rem .65rem;
  font-size: .82rem;
  cursor: pointer;
}

/* ===== 标签被选中时的状态 ===== */
.tag-choice:has(input:checked) {
  border-color: var(--um-green);
  color: var(--um-green);
  background: var(--um-green-light);
}

/* ===== 食材行（除第一个外，上面加分割线） ===== */
.ingredient-row + .ingredient-row {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid var(--um-line);
}

/* ===== 步骤行（上下间距） ===== */
.step-row + .step-row {
  margin-top: 1rem;
}

/* ===== 步骤序号圆圈 ===== */
.step-row > span {
  display: grid;
  width: 2rem;
  height: 2rem;
  flex: 0 0 2rem;
  place-items: center;
  border-radius: 50%;
  color: var(--um-green);
  background: var(--um-green-light);
  font-weight: 800;
}

/* ===== 预览卡片（粘性定位） ===== */
.preview-card {
  top: 6rem;
}

/* ===== 预览图片（固定比例 + 圆角） ===== */
.preview-image {
  width: 100%;
  aspect-ratio: 4 / 3;
  border-radius: .8rem;
  object-fit: cover;
}

/* ===== 移动端适配（超小屏） ===== */
@media (max-width: 575.98px) {
  .ingredient-row .btn-link {
    font-size: .7rem;
  }
}
</style>
