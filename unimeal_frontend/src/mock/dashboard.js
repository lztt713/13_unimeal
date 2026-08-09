import { recipes } from './recipes'

export const dashboard = {
  student: { name: 'Michael' },
  tonightRecipeId: 3,
  weeklyBudget: 45,
  spent: 27.6,
  favouriteRecipeIds: [1, 2, 4],
}

export const dashboardRecipes = {
  tonight: recipes.find((recipe) => recipe.id === dashboard.tonightRecipeId),
  favourites: recipes.filter((recipe) => dashboard.favouriteRecipeIds.includes(recipe.id)),
}
