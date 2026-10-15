<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { api } from '../services/api'

const props = defineProps({ id: { type: String, required: true } })
const recipe = ref(null)
const loading = ref(true)
// Rating state controls the selected score and the short confirmation message.
const selectedRating = ref(0)
const ratingSaved = ref(false)
// Saved recipes are available to students, not recipe contributors.
const saved = ref(false)
const user = ref(null)

// One modal supports reporting either this recipe or an individual comment.
const reportOpen = ref(false)
const reportReason = ref('')
const reportMessage = ref('')
// Comment fields keep draft input separate from API success/error feedback.
const commentText = ref('')
const commentMessage = ref('')
const commentError = ref(false)

// A null target means the report concerns the recipe; otherwise it concerns a comment.
const reportTarget = ref(null)
const reportCustomText = ref('')

// Report reasons differ because recipe and comment moderation have different contexts.
const commentReasons = [
  'Spam or advertising',
  'Offensive or inappropriate language',
  'Misleading information',
  'Off-topic or irrelevant',
  'Other concern',
]

const recipeReasons = [
  'Incorrect recipe information',
  'Missing allergy warning',
  'Inappropriate image or content',
  'Other concern',
]

// Total preparation time is calculated for display rather than stored redundantly.
const totalTime = computed(() => (recipe.value ? recipe.value.prepTime + recipe.value.cookTime : 0))

// Compare allergen tags case-insensitively with the current student's profile.
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
  if (currentUser?.role === 'student') {
    // Saving recipes is a student-only action.
    const savedIds = await api.getSavedRecipeIds()
    saved.value = savedIds.includes(Number(props.id))
  }
  loading.value = false
})

async function rateRecipe(rating) {
  // Update the visible stars immediately, then replace recipe statistics from the API response.
  selectedRating.value = rating
  recipe.value = await api.addRecipeRating(props.id, rating)
  ratingSaved.value = true
}
async function toggleSaved() {
  // The backend returns the source-of-truth saved state after toggling favourites.
  saved.value = (await api.toggleSavedRecipe(props.id)).saved
}

function openReportRecipe() {
  // Clear prior modal values before opening a report about the recipe itself.
  reportTarget.value = null
  reportReason.value = ''
  reportCustomText.value = ''
  reportOpen.value = true
}

function openReportComment(comment) {
  // Save the chosen comment so the shared reporting form can build the correct payload.
  reportTarget.value = comment
  reportReason.value = ''
  reportCustomText.value = ''
  reportOpen.value = true
}
async function submitReport() {
  try {
    const finalReason =
      reportReason.value === 'Other concern' && reportCustomText.value.trim()
        ? `Other concern: ${reportCustomText.value.trim()}`
        : reportReason.value

    // Use one endpoint for reports while preserving the reported content type.
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

    // Reset all report state so a later report starts with an empty form.
    reportReason.value = ''
    reportCustomText.value = ''
    reportTarget.value = null
  } catch (error) {
    reportMessage.value = error.message
  }
}

async function submitComment() {
  // Avoid sending an empty comment to the API.
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
            <!-- The large image gives the recipe immediate visual context. -->
            <div class="col-lg-6 detail-image-wrap">
              <img class="recipe-image" :src="recipe.imageUrl" :alt="recipe.title" />
            </div>
            <!-- Core recipe information and role-aware actions sit beside the image. -->
            <div class="col-lg-6 p-4 p-md-5 d-flex flex-column justify-content-center">
              <!-- Cuisine and dietary tags are concise metadata for browsing decisions. -->
              <div class="d-flex flex-wrap gap-2 mb-3">
                <span class="soft-badge">{{ recipe.cuisine }}</span
                ><span v-for="tag in recipe.dietaryTags" :key="tag" class="detail-tag">{{
                  tag
                }}</span>
              </div>
              <!-- The cost shown here is per serving, not the full recipe cost. -->
              <h1 class="detail-title">{{ recipe.title }}</h1>
              <p class="detail-copy">
                A practical student recipe with clear portions, simple ingredients and estimated
                cost per serving.
              </p>
              <!-- Time, per-serving cost and servings form the key planning metadata. -->
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
              <!-- Students can plan or save; every signed-in role can report content. -->
              <div class="d-flex align-items-center justify-content-between flex-wrap gap-3">
                <div class="d-flex align-items-center gap-2">
                  <span class="recipe-rating">{{ recipe.rating }} / 5</span
                  ><span class="text-secondary small">from {{ recipe.reviewCount }} ratings</span>
                </div>
                <!-- Student's main next step is to put this recipe into a meal plan. -->
                <div class="d-flex gap-2">
                  <RouterLink
                    v-if="user?.role === 'student'"
                    class="btn btn-primary rounded-pill btn-sm"
                    :to="{ path: '/calendar', query: { recipe: recipe.id } }"
                  >
                    Plan this recipe
                  </RouterLink>
                  <button v-if="user?.role === 'student'" class="btn btn-outline-primary rounded-pill btn-sm" @click="toggleSaved">
                    {{ saved ? 'Saved to favourites' : 'Save recipe' }}
                  </button>
                  <button class="btn btn-outline-secondary btn-sm" @click="openReportRecipe">
                    Report recipe
                  </button>
                </div>
              </div>
            </div>
          </div>
        </article>

        <!-- Warn only when normalised recipe allergens match the student's saved allergies. -->
        <div v-if="allergyWarnings.length" class="alert alert-warning mt-4 mb-0">
          <strong>Allergy warning:</strong> this recipe contains {{ allergyWarnings.join(', ') }}.
        </div>
        <div v-if="recipe.requiredEquipment?.length" class="surface-card p-3 mt-4">
          <!-- Required equipment is shown when the recipe/database supplies it. -->
          <strong class="me-2">Required equipment:</strong>
          <span v-for="equipment in recipe.requiredEquipment" :key="equipment.id" class="detail-tag me-2">
            {{ equipment.name }}
          </span>
        </div>

        <div class="row g-4 mt-1">
          <!-- Ingredient quantities use the recipe's stored serving size. -->
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
          <!-- Method steps are numbered separately from their text for clearer scanning. -->
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
        <!-- Five buttons make the one-to-five rating scale explicit and keyboard accessible. -->

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

        <!-- Comments provide student feedback and can be independently reported. -->
        <section class="mt-5">
          <div class="d-flex align-items-end justify-content-between mb-3">
            <div>
              <p class="eyebrow">Student feedback</p>
              <h2 class="section-heading mb-0">Comments</h2>
            </div>
            <span class="text-secondary small">{{ recipe.comments.length }} shown</span>
          </div>
          <!-- Existing comments are rendered before the student-only comment form. -->
          <div v-if="recipe.comments.length" class="row g-3">
            <div v-for="comment in recipe.comments" :key="comment.id" class="col-md-6">
              <article class="surface-card p-4 h-100">
                <div class="d-flex justify-content-between gap-2">
                  <strong>{{ comment.author }}</strong
                  ><span v-if="comment.rating" class="recipe-rating">{{ comment.rating }} / 5</span>
                  <!-- Each signed-in user may report an individual comment for review. -->
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
          <!-- The empty state explains why no comment cards appear yet. -->
          <div v-else class="empty-state p-4">
            No comments yet. Be the first student to share a helpful tip.
          </div>
          <!-- Contributors can view feedback but only students submit comments. -->
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
        <!-- Report submission feedback remains visible after the modal closes. -->
        <p v-if="reportMessage" class="alert alert-success mt-4 mb-0">{{ reportMessage }}</p>
      </template>

      <div v-if="reportOpen" class="modal-backdrop-custom" @click.self="reportOpen = false">
        <section
          class="report-modal surface-card">
          <h2 id="report-title" class="section-heading">
            {{ reportTarget ? 'Report comment' : 'Report recipe' }}</h2>
          <p class="text-secondary">
            {{ reportTarget
              ? 'Tell the administrator why this comment needs review.'
              : 'Tell the administrator why this recipe needs review.' }}
          </p>

          <!-- Reasons are selected from the correct list for a recipe or comment report. -->
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
          <!-- The modal actions either discard local state or send the report payload. -->
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
/* A constrained empty state avoids an overly wide error card on large screens. */
.detail-empty {
  max-width: 35rem;
}

.back-link {
  /* The return link uses the brand colour without competing with primary actions. */
  color: var(--um-green);
  font-size: 0.9rem;
  font-weight: 750;
}

.detail-image-wrap {
  /* Reserve image height to prevent the main recipe card from jumping during loading. */
  min-height: 22rem;
}

.detail-title,
.section-heading {
  /* Page and section headings share the same bold product typography. */
  color: var(--um-ink);
  font-weight: 800;
  letter-spacing: -0.045em;
}

.detail-title {
  font-size: 2.5rem;
}

.detail-copy {
  /* Supporting recipe copy is muted so title and actions retain hierarchy. */
  color: var(--um-muted);
  margin: 1rem 0;
}

.detail-tag {
  /* Dietary and equipment labels use a neutral tag treatment. */
  border-radius: 99px;
  padding: 0.38rem 0.65rem;
  background: #f4efe6;
  color: #676454;
  font-size: 0.76rem;
  font-weight: 750;
}

.col-4 strong {
  /* Each metadata value occupies its own line above its label. */
  display: block;
  color: var(--um-green);
  font-size: 1.1rem;
}

.col-4 span {
  display: block;
  color: var(--um-muted);
  font-size: 0.72rem;
}

.recipe-rating {
  /* The warm colour separates rating data from green planning metadata. */
  color: #9c5a0c;
  font-weight: 800;
}

.section-heading {
  font-size: 1.45rem;
}

.ingredient-list li {
  /* Ingredient rows pair a flexible name with a non-wrapping quantity. */
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.85rem 0;
  border-bottom: 1px solid var(--um-line);
  font-size: 0.94rem;
}

.ingredient-list li:last-child {
  /* The final ingredient does not need a divider. */
  border: 0;
}

.ingredient-list strong {
  color: var(--um-green);
  white-space: nowrap;
}

.method-list {
  /* Remove browser list styling because step numbers are custom elements. */
  list-style: none;
  padding: 0;
}

.method-list li {
  display: flex;
  gap: 1rem;
  padding: 0.85rem 0;
}

.method-list p {
  margin: 0.25rem 0 0;
  line-height: 1.6;
}

.step-number {
  /* A consistent circular number makes longer methods easy to follow. */
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

.rating-actions {
  /* Rating controls remain evenly spaced touch targets. */
  display: flex;
  gap: 0.45rem;
}

.rating-actions button {
  width: 2.25rem;
  height: 2.25rem;
  border: 1px solid #d7d1c4;
  border-radius: 50%;
  color: var(--um-muted);
  background: #fff;
  font-weight: 800;
}

.rating-actions button.selected,
.rating-actions button:hover {
  /* Selected and hovered scores share the coral active-state styling. */
  border-color: var(--um-coral);
  color: #fff;
  background: var(--um-coral);
}

.saved-note {
  color: var(--um-green);
  font-size: 0.86rem;
  font-weight: 700;
}
.modal-backdrop-custom {
  /* The overlay covers the page and centres the report form above its content. */
  position: fixed;
  z-index: 1050;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  background: rgba(0, 0, 0, 0.45);
}
.report-modal {
  /* Keep report text fields readable on both desktop and mobile. */
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

.report-comment-btn {
  /* Reporting is visually secondary to the comment content itself. */
  font-size: 0.76rem;
  font-weight: 700;
  text-decoration: none;
}
.report-comment-btn:hover {
  color: var(--um-coral) !important;
}
@media (max-width: 991.98px) {
  .detail-image-wrap {
    height: 18rem;
  }
}
</style>
