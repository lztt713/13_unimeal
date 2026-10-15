<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../services/api'

const router = useRouter()
const route = useRoute()
const ingredients = ref([])
// Equipment comes from reference data so contributors cannot create inconsistent values.
const equipmentOptions = ref([])
const submitted = ref(false)
const submitting = ref(false)
const errors = ref([])

// Local image state supports preview and validation before uploading.
const imageInput = ref(null)
const selectedImage = ref(null)
const localPreviewUrl = ref('')
const imageError = ref('')
const maxImageSize = 5 * 1024 * 1024
const acceptedImageTypes = ['image/jpeg', 'image/png', 'image/webp']
const form = ref({
  title: '',
  imageUrl: '',
  cuisine: '',
  difficulty: 'Easy',
  prepTime: 10,
  cookTime: 20,
  servings: 1,
  estimatedCost: 0,
  dietaryTags: [],
  requiredEquipmentIds: [],
  ingredients: [{ ingredientId: '', quantity: '', unit: 'g' }],
  steps: [''],
})
const tagOptions = ['Vegetarian', 'Vegan', 'Gluten Free', 'High Protein', 'Budget']
// Preview priority is local file, then entered URL, then a neutral fallback image.
const previewUrl = computed(
  () =>
    localPreviewUrl.value ||
    form.value.imageUrl ||
    'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=900&q=80',
)

onMounted(async () => {
  // Equipment options appear automatically once the database endpoint is available.
  const [ingredientData, equipmentData] = await Promise.all([
    api.getIngredients(),
    api.getEquipment().catch(() => []),
  ])
  ingredients.value = ingredientData
  equipmentOptions.value = equipmentData
  // Reuse the same form for editing an existing contributor recipe.
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
    estimatedCost: recipe.estimatedCost,
    dietaryTags: recipe.dietaryTags,
    requiredEquipmentIds: (recipe.requiredEquipment || []).map((equipment) => equipment.id),
    ingredients: recipe.ingredientDetails.map((item) => ({
      ingredientId: item.ingredientId,
      quantity: item.quantity,
      unit: item.unit,
    })),
    steps: recipe.steps,
  }
})
function addIngredient() {
  // New rows start with the common gram unit until an ingredient supplies a default.
  form.value.ingredients.push({ ingredientId: '', quantity: '', unit: 'g' })
}
function removeIngredient(index) {
  // Keep at least one row so the recipe form always prompts for an ingredient.
  if (form.value.ingredients.length > 1) form.value.ingredients.splice(index, 1)
}
function setIngredientUnit(row) {
  // Selecting an ingredient copies its database default unit into the editable row.
  const item = ingredients.value.find((ingredient) => ingredient.id === Number(row.ingredientId))
  if (item) row.unit = item.defaultUnit
}
function addStep() {
  // Method steps are editable as a simple ordered text array.
  form.value.steps.push('')
}
function removeStep(index) {
  // Keep one step input available even after a contributor removes a row.
  if (form.value.steps.length > 1) form.value.steps.splice(index, 1)
}

function clearSelectedImage() {
  // Release temporary browser URLs to avoid retaining local image memory.
  if (localPreviewUrl.value) URL.revokeObjectURL(localPreviewUrl.value)
  localPreviewUrl.value = ''
  selectedImage.value = null
  imageError.value = ''
  if (imageInput.value) imageInput.value.value = ''
}

function removeCurrentImage() {
  clearSelectedImage()
  form.value.imageUrl = ''
}

function selectImage(event) {
  const file = event.target.files?.[0]
  if (!file) return
  imageError.value = ''
  // Validate type and size before creating a preview or uploading the file.
  if (!acceptedImageTypes.includes(file.type)) {
    imageError.value = 'Choose a JPG, PNG, or WEBP image.'
    event.target.value = ''
    return
  }
  if (file.size > maxImageSize) {
    imageError.value = 'Choose an image smaller than 5 MB.'
    event.target.value = ''
    return
  }
  if (localPreviewUrl.value) URL.revokeObjectURL(localPreviewUrl.value)
  selectedImage.value = file
  localPreviewUrl.value = URL.createObjectURL(file)
}
onBeforeUnmount(clearSelectedImage)

async function submitRecipe() {
  errors.value = []
  // Validate client-side fields for immediate contributor feedback.
  if (!form.value.title.trim()) errors.value.push('Recipe title is required.')
  if (!form.value.cuisine.trim()) errors.value.push('Cuisine is required.')
  if (Number(form.value.servings) < 1) errors.value.push('Servings must be at least 1.')
  if (form.value.ingredients.some((row) => !row.ingredientId || Number(row.quantity) <= 0))
    errors.value.push('Each ingredient needs a selection and positive quantity.')
  if (form.value.steps.some((step) => !step.trim()))
    errors.value.push('Each method step needs text.')
  if (errors.value.length) return
  // Build rich ingredient rows once, then derive the smaller search-index names from them.
  const details = form.value.ingredients.map((row) => ({
    ingredientId: Number(row.ingredientId),
    name: ingredients.value.find((item) => item.id === Number(row.ingredientId)).name,
    quantity: Number(row.quantity),
    unit: row.unit,
  }))
  const payload = {
    ...form.value,
    prepTime: Number(form.value.prepTime),
    cookTime: Number(form.value.cookTime),
    servings: Number(form.value.servings),
    estimatedCost: Number(form.value.estimatedCost),
    // Ingredient names support text search; detailed rows preserve quantities and units.
    ingredients: details.map((item) => item.name.toLowerCase()),
    ingredientDetails: details,
    steps: form.value.steps.map((step) => step.trim()),
  }
  submitting.value = true
  try {
    // A selected local file is uploaded first. The backend returns the URL saved with the recipe.
    if (selectedImage.value) {
      const upload = await api.uploadRecipeImage(selectedImage.value)
      payload.imageUrl = upload.imageUrl
    }
    const recipe = route.query.edit
      ? await api.updateRecipe(route.query.edit, payload)
      : await api.createRecipe(payload)
    submitted.value = true
    setTimeout(() => router.push(`/recipes/${recipe.id}`), 700)
  } catch (error) {
    errors.value = [error.message]
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <section class="page-shell">
    <div class="container">
      <div class="submission-intro">
        <p class="eyebrow">Recipe contributor</p>
        <h1 class="page-title">Share a student-friendly recipe.</h1>
        <p class="page-subtitle">
          Add the recipe details students need: ingredients, method, time, cost and dietary tags.
        </p>
      </div>
      <form class="row g-4 mt-1" @submit.prevent="submitRecipe">
        <div class="col-lg-8">
          <section class="surface-card p-4 p-md-5">
            <!-- Core fields are validated before the contributor's recipe is sent to the API. -->
            <h2 class="form-heading">Recipe details</h2>
            <div v-if="errors.length" class="alert alert-danger">
              <ul class="mb-0">
                <li v-for="error in errors" :key="error">{{ error }}</li>
              </ul>
            </div>
            <div class="row g-3">
              <div class="col-md-8">
                <label class="form-label" for="title">Title</label
                ><input id="title" v-model="form.title" class="form-control" maxlength="200" />
              </div>
              <div class="col-md-4">
                <label class="form-label" for="cuisine">Cuisine</label
                ><input id="cuisine" v-model="form.cuisine" class="form-control" />
              </div>
              <div class="col-md-4">
                <label class="form-label" for="difficulty">Difficulty</label
                ><select id="difficulty" v-model="form.difficulty" class="form-select">
                  <option>Easy</option>
                  <option>Medium</option>
                  <option>Hard</option>
                </select>
              </div>
              <div class="col-md-4">
                <label class="form-label" for="prep">Prep minutes</label
                ><input
                  id="prep"
                  v-model="form.prepTime"
                  class="form-control"
                  type="number"
                  min="0"
                />
              </div>
              <div class="col-md-4">
                <label class="form-label" for="cook">Cook minutes</label
                ><input
                  id="cook"
                  v-model="form.cookTime"
                  class="form-control"
                  type="number"
                  min="0"
                />
              </div>
              <div class="col-md-4">
                <label class="form-label" for="servings">Servings</label
                ><input
                  id="servings"
                  v-model="form.servings"
                  class="form-control"
                  type="number"
                  min="1"
                />
              </div>
              <div class="col-md-4">
                <label class="form-label" for="estimated-cost">Estimated cost per serving</label
                ><input
                  id="estimated-cost"
                  v-model="form.estimatedCost"
                  class="form-control"
                  type="number"
                  min="0"
                  step="0.01"
                />
              </div>
            </div>
            <fieldset class="mt-4">
              <!-- Multiple dietary tags can be selected for search and student filtering. -->
              <legend class="form-label mb-2">Dietary tags</legend>
              <div class="d-flex flex-wrap gap-2">
                <label v-for="tag in tagOptions" :key="tag" class="tag-choice"
                  ><input v-model="form.dietaryTags" type="checkbox" :value="tag" />
                  {{ tag }}</label
                >
              </div>
            </fieldset>
            <fieldset v-if="equipmentOptions.length" class="mt-4">
              <!-- Equipment is optional until the backend exposes its reference-data endpoint. -->
              <legend class="form-label mb-2">Required equipment</legend>
              <div class="d-flex flex-wrap gap-2">
                <label v-for="equipment in equipmentOptions" :key="equipment.id" class="tag-choice">
                  <input v-model="form.requiredEquipmentIds" type="checkbox" :value="equipment.id" />
                  {{ equipment.name }}
                </label>
              </div>
            </fieldset>
          </section>
          <section class="surface-card p-4 p-md-5 mt-4">
            <!-- Ingredient rows store the ingredient ID, quantity and display unit together. -->
            <div class="d-flex justify-content-between align-items-center mb-3">
              <h2 class="form-heading mb-0">Ingredients</h2>
              <button
                class="btn btn-outline-primary btn-sm rounded-pill"
                type="button"
                @click="addIngredient"
              >
                Add ingredient
              </button>
            </div>
            <div
              v-for="(row, index) in form.ingredients"
              :key="index"
              class="ingredient-row row g-2 align-items-end"
            >
              <div class="col-md-6">
                <label class="form-label">Ingredient</label
                ><select
                  v-model="row.ingredientId"
                  class="form-select"
                  @change="setIngredientUnit(row)"
                >
                  <option value="">Select ingredient</option>
                  <option
                    v-for="ingredient in ingredients"
                    :key="ingredient.id"
                    :value="ingredient.id"
                  >
                    {{ ingredient.name }}
                  </option>
                </select>
              </div>
              <div class="col-5 col-md-3">
                <label class="form-label">Quantity</label
                ><input
                  v-model="row.quantity"
                  class="form-control"
                  type="number"
                  min="0.01"
                  step="0.01"
                />
              </div>
              <div class="col-4 col-md-2">
                <label class="form-label">Unit</label
                ><input v-model="row.unit" class="form-control" />
              </div>
              <div class="col-3 col-md-1">
                <button
                  class="btn btn-link text-danger p-1"
                  type="button"
                  :disabled="form.ingredients.length === 1"
                  @click="removeIngredient(index)"
                >
                  Remove
                </button>
              </div>
            </div>
          </section>
          <section class="surface-card p-4 p-md-5 mt-4">
            <!-- Contributors can add or remove ordered method steps without leaving the form. -->
            <div class="d-flex justify-content-between align-items-center mb-3">
              <h2 class="form-heading mb-0">Method</h2>
              <button
                class="btn btn-outline-primary btn-sm rounded-pill"
                type="button"
                @click="addStep"
              >
                Add step
              </button>
            </div>
            <div v-for="(step, index) in form.steps" :key="index" class="step-row d-flex gap-2">
              <span>{{ index + 1 }}</span
              ><textarea
                v-model="form.steps[index]"
                class="form-control"
                rows="2"
                :aria-label="`Step ${index + 1}`"
              ></textarea
              ><button
                class="btn btn-link text-danger p-1 align-self-center"
                type="button"
                :disabled="form.steps.length === 1"
                @click="removeStep(index)"
              >
                Remove
              </button>
            </div>
          </section>
        </div>
        <aside class="col-lg-4">
          <section class="surface-card p-4 sticky-lg-top preview-card">
            <!-- Preview local uploads before submitting and retain the optional URL alternative. -->
            <h2 class="form-heading">Image preview</h2>
            <img class="preview-image" :src="previewUrl" alt="Recipe preview" />
            <input
              id="image-file"
              ref="imageInput"
              class="visually-hidden"
              type="file"
              accept="image/jpeg,image/png,image/webp"
              @change="selectImage"
            />
            <!-- A styled label triggers the visually hidden native file input. -->
            <label class="file-picker" for="image-file">Choose image</label>
            <span class="file-name">{{ selectedImage ? selectedImage.name : 'No file selected' }}</span>
            <p v-if="selectedImage" class="small text-secondary mt-2 mb-0">
              Selected: {{ selectedImage.name }}
            </p>
            <p v-if="imageError" class="text-danger small mt-2 mb-0">{{ imageError }}</p>
            <div class="image-url-field">
              <div class="image-url-heading">
                <label class="form-label mb-0" for="image">Image URL (optional)</label>
                <button
                  v-if="selectedImage || form.imageUrl"
                  class="btn btn-outline-danger btn-sm"
                  type="button"
                  @click="removeCurrentImage"
                >
                  Remove image
                </button>
              </div>
              <input
                id="image"
                v-model="form.imageUrl"
                class="form-control"
                type="url"
                placeholder="https://..."
              />
            </div>
            <button
              class="btn btn-primary rounded-pill w-100 mt-2"
              type="submit"
              :disabled="submitted || submitting"
            >
              {{ submitted ? 'Saved - opening recipe...' : submitting ? 'Saving...' : 'Submit recipe' }}
            </button>
          </section>
        </aside>
      </form>
    </div>
  </section>
</template>

<style scoped>
/* The introduction line length stays readable rather than spanning a wide desktop screen. */
.submission-intro {
  max-width: 46rem;
}

.form-heading {
  /* Section headings distinguish the form's logical recipe sections. */
  color: var(--um-ink);
  font-size: 1.35rem;
  font-weight: 800;
  letter-spacing: -0.03em;
}

.form-label {
  /* Labels use consistent small, bold text above inputs. */
  color: var(--um-ink);
  font-size: 0.82rem;
  font-weight: 750;
}

.form-control,
.form-select {
  /* Text inputs and selects use the shared rounded form-control styling. */
  border-color: var(--um-line);
  border-radius: 0.7rem;
  padding: 0.65rem 0.8rem;
}

.form-control:focus,
.form-select:focus {
  /* The focus ring gives keyboard users a clear brand-coloured indicator. */
  border-color: var(--um-green);
  box-shadow: 0 0 0 0.2rem rgba(49, 87, 44, 0.12);
}

.tag-choice {
  /* Dietary and equipment selections share compact checkbox-pill styling. */
  border: 1px solid var(--um-line);
  border-radius: 99px;
  padding: 0.38rem 0.65rem;
  font-size: 0.82rem;
  cursor: pointer;
}


.ingredient-row + .ingredient-row {
  /* Later ingredient rows are visually separated from the preceding row. */
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid var(--um-line);
}

.step-row + .step-row {
  /* Add vertical rhythm between consecutive method steps. */
  margin-top: 1rem;
}

.step-row > span {
  /* Step numbers use the same circular cue as the recipe-detail method view. */
  display: flex;
  width: 2rem;
  height: 2rem;
  flex: 0 0 2rem;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  color: var(--um-green);
  background: var(--um-green-light);
  font-weight: 800;
}

.preview-card {
  /* The sidebar stays visible beside a long form on larger screens. */
  top: 6rem;
}

.preview-image {
  /* A fixed crop makes URL and local-file previews visually comparable. */
  width: 100%;
  height: 14rem;
  border-radius: 0.8rem;
  object-fit: cover;
}

.file-picker {
  display: inline-block;
  margin-top: 1rem;
  border: 1px solid var(--um-green);
  border-radius: 0.5rem;
  padding: 0.5rem 0.8rem;
  color: #fff;
  background: var(--um-green);
  cursor: pointer;
  font-size: 0.85rem;
  font-weight: 700;
}

.file-name {
  display: inline-block;
  max-width: 100%;
  margin-left: 0.65rem;
  overflow: hidden;
  color: var(--um-muted);
  font-size: 0.82rem;
  text-overflow: ellipsis;
  vertical-align: middle;
  white-space: nowrap;
}

.image-url-field {
  margin-top: 1rem;
}

.image-url-field .form-label {
  display: block;
  margin-bottom: 0.45rem;
}

.image-url-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  margin-bottom: 0.45rem;
}

@media (max-width: 575.98px) {
  .ingredient-row .btn-link {
    font-size: 0.7rem;
  }
}
</style>
