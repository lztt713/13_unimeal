<script setup>
// Featured meals data (hardcoded static data, since home page is public)
const featuredMeals = [
  {
    title: 'Creamy Tomato Pasta',
    cookTime: 25,
    note: 'Vegetarian · from $4.80 per serving',
    imageUrl:
      'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=900&q=80',
  },
  {
    title: 'Chickpea Coconut Curry',
    cookTime: 35,
    note: 'Vegan and gluten free · from $4.20 per serving',
    imageUrl:
      'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=900&q=80',
  },
  {
    title: 'Mediterranean Veggie Wrap',
    cookTime: 15,
    note: 'Quick lunch idea · from $3.90 per serving',
    imageUrl:
      'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?auto=format&fit=crop&w=900&q=80',
  },
]
</script>

<template>
  <section class="home-page">
    <div class="container py-5">
      <div class="row align-items-center g-4 py-lg-4">
        <div class="col-lg-6 order-2">
          <h1 class="display-5 fw-bold">Plan affordable meals for student life.</h1>
          <p class="lead text-secondary mt-3">
            UniMeal helps students find recipes, plan meals for the week, make a shopping list, and
            keep track of a food budget.
          </p>
          <!-- Clear first-time choices: create an account or return to an existing one. -->
          <div class="d-flex flex-wrap gap-2 mt-4">
            <RouterLink class="btn btn-primary rounded-pill px-4" to="/register">Get started</RouterLink
            ><RouterLink class="btn btn-outline-primary rounded-pill px-4" to="/login">I already have an account</RouterLink>
          </div>
        </div>
        <!-- Lead with a visual on small screens and desktop alike. -->
        <div class="col-lg-6 order-1">
          <img
            class="hero-image"
            src="https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=900&q=80"
            alt="Fresh ingredients for a meal"
          />
        </div>
      </div>


        <section class="mt-5">
        <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-3">
          <div>
            <h2 class="h3 fw-bold mb-1">Featured meal ideas</h2>
            <p class="text-secondary mb-0">
              A few affordable examples of what students can explore after logging in.
            </p>
          </div>
          <RouterLink class="btn btn-outline-primary" to="/login">Log in to explore</RouterLink>
        </div>
        <div class="row g-3">
           <!-- Loop through featuredMeals array to render 3 recipe cards -->
          <div v-for="meal in featuredMeals" :key="meal.title" class="col-md-4">
            <article class="featured-meal h-100">
              <img :src="meal.imageUrl" :alt="meal.title" />
              <div class="p-3">
                <div class="d-flex justify-content-between align-items-center gap-2">
                  <h3 class="h5 mb-0">{{ meal.title }}</h3>
                  <span class="small text-secondary">{{ meal.cookTime }} min</span>
                </div>
                <p class="mb-0 mt-2 text-secondary">{{ meal.note }}</p>
              </div>
            </article>
          </div>
        </div>
      </section>
      <section class="how-it-works mt-5">
        <div class="text-center mx-auto how-it-works-heading">
          <p class="eyebrow">Made for student life</p>
          <h2 class="h3 fw-bold">A simple path from preference to plate.</h2>
          <p class="text-secondary mb-0">Set your needs once, then let each page guide your next step.</p>
        </div>
        <div class="row g-3 mt-2">
          <div class="col-md-4">
            <article class="journey-step h-100">
              <span>1</span><h3 class="h5">Tell us about you</h3>
              <p class="mb-0">Set your budget, dietary needs and kitchen access.</p>
            </article>
          </div>
          <div class="col-md-4">
            <article class="journey-step h-100">
              <span>2</span><h3 class="h5">Plan your week</h3>
              <p class="mb-0">Choose recipes and add them to the days you want to cook.</p>
            </article>
          </div>
          <div class="col-md-4">
            <article class="journey-step h-100">
              <span>3</span><h3 class="h5">Shop with clarity</h3>
              <p class="mb-0">Use one combined list and see what is still left to buy.</p>
            </article>
          </div>
        </div>
      </section>
      <!-- Section 2: Four feature cards (whole card clickable → /login) -->
      <section class="mt-5">
        <h2 class="h3 fw-bold">What can you do with UniMeal?</h2>
        <div class="row g-3 mt-1">

          <div class="col-md-6 col-lg-3">
             <!-- position-relative 是 stretched-link 生效的必要条件 -->
            <article class="card feature-card feature-1 h-100 position-relative">
              <div class="card-body">
                 <!-- 卡片内容：编号、标题、描述 -->
                <span class="feature-number">01</span>
                <h3 class="h5">Find recipes</h3>
                <p class="card-text text-secondary">
                  Search recipes by cuisine, cost, difficulty, and dietary preference.
                </p>
                <span class="card-arrow">→</span>
                 <!-- stretched-link 让它铺满整张卡片 -->
                <RouterLink class="stretched-link" to="/login">
                </RouterLink>
              </div>
            </article>
          </div>
          <div class="col-md-6 col-lg-3">
            <article class="card feature-card feature-2 h-100 position-relative">
              <div class="card-body">
                <span class="feature-number">02</span>
                <h3 class="h5">Plan meals</h3>
                <p class="card-text text-secondary">
                  Choose meals for each day of the week and update the plan when needed.
                </p>
                <span class="card-arrow">→</span>
                 <!-- stretched-link 让它铺满整张卡片 -->
                <RouterLink class="stretched-link" to="/login">
                </RouterLink>
              </div>
            </article>
          </div>
          <div class="col-md-6 col-lg-3">
            <article class="card feature-card feature-3 h-100 position-relative">
              <div class="card-body">
                <span class="feature-number">03</span>
                <h3 class="h5">Build a shopping list</h3>
                <p class="card-text text-secondary">
                  Combine ingredients from planned recipes into one list.
                </p>
                <span class="card-arrow">→</span>
                 <!-- stretched-link 让它铺满整张卡片 -->
                <RouterLink class="stretched-link" to="/login">
                </RouterLink>
              </div>
            </article>
          </div>
          <div class="col-md-6 col-lg-3">
            <article class="card feature-card feature-4 h-100 position-relative">
              <div class="card-body">
                <span class="feature-number">04</span>
                <h3 class="h5">Manage your budget</h3>
                <p class="card-text text-secondary">
                  Compare estimated food spending with your weekly budget.
                </p>
                <span class="card-arrow">→</span>
                 <!-- stretched-link 让它铺满整张卡片 -->
                <RouterLink class="stretched-link" to="/login">
                </RouterLink>
              </div>
            </article>
          </div>
        </div>
      </section>



        <!--Role cards (matching the 3 user roles in the brief) -->
      <section class="mt-5 border-top pt-4">
        <h2 class="h3 fw-bold">Who is UniMeal for?</h2>
        <div class="row g-3 mt-1">
          <div class="col-md-4">
            <article class="role-card role-student h-100">
              <h3 class="h5">Students</h3>
              <p class="text-secondary mb-0">
                Plan meals, save recipes, manage a shopping list, and monitor a budget.
              </p>
            </article>
          </div>
          <div class="col-md-4">
            <article class="role-card role-contributor h-100">
              <h3 class="h5">Recipe contributors</h3>
              <p class="text-secondary mb-0">
                Submit and manage recipes with ingredients, steps, costs, and dietary tags.
              </p>
            </article>
          </div>
          <div class="col-md-4">
            <article class="role-card role-admin h-100">
              <h3 class="h5">Administrators</h3>
              <p class="text-secondary mb-0">
                Review reported content and manage users, recipes, and ingredient categories.
              </p>
            </article>
          </div>
        </div>
      </section>
    </div>
  </section>
</template>



<style scoped>
/* .home-page {
  background: var(--um-cream);
} */
 /* ===== 首页所有标题统一深灰色 ===== */
.home-page h1,
.home-page h2,
.home-page h3 {
  color: #212529;
}
/* ===== 首页所有图片：最高 20rem，宽度 100%，裁切不变形 ===== */
.home-page img {
  max-height: 20rem;
  width: 100%;
  object-fit: cover;
}
.home-page .hero-image {
  display: block;
  width: 100%;
  min-height: 15rem;
  max-height: 22rem;
  border: 1px solid var(--um-line);
  border-radius: 1rem;
  object-fit: cover;
}
.how-it-works-heading {
  max-width: 42rem;
}
.journey-step {
  padding: 1.4rem;
  border: 1px solid var(--um-line);
  border-radius: 0.75rem;
  background: #fff;
}
.journey-step span {
  display: inline-flex;
  width: 1.9rem;
  height: 1.9rem;
  align-items: center;
  justify-content: center;
  margin-bottom: 0.8rem;
  border-radius: 50%;
  color: #fff;
  background: var(--um-green);
  font-weight: 800;
}
.journey-step h3 {
  color: var(--um-ink);
}
.journey-step p {
  color: var(--um-muted);
}
.card {
  /* ===== 通用卡片：浅灰绿边框 + 圆角 + 无阴影 ===== */
  border-color: var(--um-line);
  border-radius: 0.375rem;
  box-shadow: none;
}
/* ===== 功能卡片：顶部装饰线 + 悬停上浮动画 ===== */
.feature-card {
  border-top: 3px solid var(--um-green);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  cursor: pointer;/* 鼠标变手型，提示可点击  */
}
.feature-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 28px rgba(36, 48, 36, 0.12);
}
.feature-card .card-body {
  padding: 1.25rem;
}
/* 右下角的箭头*/
.card-arrow {
  position: absolute;
  bottom: 1rem;
  right: 1.25rem;
  color: var(--um-green);
  font-size: 1.2rem;
  font-weight: 700;
}
/* Feature number badge (01, 02, 03, 04) */
.feature-number {
  display: inline-block;
  margin-bottom: 0.8rem;
  padding: 0.2rem 0.45rem;
  border-radius: 0.25rem;
  color: var(--um-green);
  background: var(--um-green-light);
  font-size: 0.75rem;
  font-weight: 700;
}
.feature-card h3 {
  color: var(--um-green);
}
.feature-2 {
  border-top-color: #4d7b78;
}
.feature-2 .feature-number {
  color: #315f5c;
  background: #e1efee;
}
.feature-3 {
  border-top-color: #b37a32;
}
.feature-3 .feature-number {
  color: #875a1f;
  background: #fff1d8;
}
.feature-4 {
  border-top-color: var(--um-coral);
}
.feature-4 .feature-number {
  color: #9c4f35;
  background: #fae6df;
}
.role-card {
  padding: 1rem 1.1rem;
  border-left: 3px solid var(--um-green);
  background: #fff;
}
.role-card h3 {
  color: var(--um-green);
}
.role-contributor {
  border-left-color: #4d7b78;
}
.role-admin {
  border-left-color: var(--um-coral);
}
/* Featured meal card: border + rounded corners */
.featured-meal {
  overflow: hidden;
  border: 1px solid var(--um-line);
  border-radius: 0.375rem;
  background: #fff;
}

.featured-meal img {
  display: block;
  width: 100%;
  height: 10rem;
  object-fit: cover;
}
</style>
