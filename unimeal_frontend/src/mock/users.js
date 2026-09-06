export const currentUser = {
  id: 1,
  displayName: 'Michael Zhao',
  email: 'michael@unimeal.test',
  role: 'student',
  weeklyBudget: 45,
  cookingSkill: 'Beginner',
  kitchenAccess: 'Shared kitchen',
  dietaryPreferences: ['Vegetarian'],
  allergies: [],
  favouriteCuisines: ['Italian', 'Japanese'],
}

export const adminOverview = {
  statistics: [
    { label: 'Active users', value: 128, note: '+8 this week' },
    { label: 'Published recipes', value: 46, note: '+4 this week' },
    { label: 'Weekly meal plans', value: 73, note: '57 completed' },
    { label: 'Open reports', value: 3, note: 'Needs review' },
  ],
  reports: [
    { id: 1, targetType: 'Recipe', targetTitle: 'Creamy Tomato Pasta', reporter: 'Ava Lee', reason: 'Image may not match the recipe', status: 'Open', createdAt: '2026-09-03' },
    { id: 2, targetType: 'Comment', targetTitle: 'Comment on Chickpea Coconut Curry', reporter: 'Leo Wang', reason: 'Inappropriate language', status: 'In review', createdAt: '2026-09-02' },
    { id: 3, targetType: 'Recipe', targetTitle: 'Quick Noodle Bowl', reporter: 'Priya Shah', reason: 'Missing allergy warning', status: 'Open', createdAt: '2026-09-01' },
  ],
  users: [
    { id: 1, displayName: 'Michael Zhao', email: 'michael@unimeal.test', role: 'student', status: 'Active' },
    { id: 2, displayName: 'Ava Lee', email: 'ava@unimeal.test', role: 'contributor', status: 'Active' },
    { id: 3, displayName: 'Leo Wang', email: 'leo@unimeal.test', role: 'student', status: 'Suspended' },
  ],
  ingredientCategories: [
    { id: 1, name: 'Pantry', description: 'Dry goods, grains and canned food' },
    { id: 2, name: 'Produce', description: 'Fresh fruit and vegetables' },
    { id: 3, name: 'Protein', description: 'Meat, eggs and plant proteins' },
  ],
}
