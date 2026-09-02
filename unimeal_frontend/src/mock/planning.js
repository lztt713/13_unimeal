function toDateKey(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function dateAtWeekOffset(offset) {
  const today = new Date()
  const mondayOffset = (today.getDay() + 6) % 7
  const date = new Date(today.getFullYear(), today.getMonth(), today.getDate() - mondayOffset + offset)
  return toDateKey(date)
}

export const weeklyPlan = {
  id: 1,
  weekStartDate: dateAtWeekOffset(0),
  entries: [
    { id: 1, plannedDate: dateAtWeekOffset(1), mealType: 'Dinner', recipeId: 3, plannedServings: 2 },
    { id: 2, plannedDate: dateAtWeekOffset(3), mealType: 'Dinner', recipeId: 1, plannedServings: 2 },
    { id: 3, plannedDate: dateAtWeekOffset(5), mealType: 'Lunch', recipeId: 4, plannedServings: 2 },
  ],
}

export const budgetSummary = {
  period: { startDate: dateAtWeekOffset(0), endDate: dateAtWeekOffset(6), budgetAmount: 45 },
  actualSpent: 27.6,
  categories: [
    { label: 'Planned meals', amount: 19.4 },
    { label: 'Pantry top-ups', amount: 5.2 },
    { label: 'Snacks', amount: 3.0 },
  ],
}
