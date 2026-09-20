-- AI-generated recipe illustrations; assets are in unimeal_frontend/public/images/recipes.
USE unimeal_planner;
START TRANSACTION;
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/tomato-rice-bowl.png' WHERE r.title='Tomato Rice Bowl' AND u.email='contributor.ben@unimeal.test';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/egg-on-toast.png' WHERE r.title='Egg on Toast' AND u.email='contributor.ben@unimeal.test';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/chickpea-coconut-curry-20260920.png' WHERE r.title='Chickpea Coconut Curry' AND u.email='contributor.ben@unimeal.test';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/creamy-tomato-pasta-20260920.png' WHERE r.title='Creamy Tomato Pasta' AND u.email='contributor.ben@unimeal.test';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/garlic-mushroom-toast-20260920.png' WHERE r.title='Garlic Mushroom Toast' AND u.email='contributor.ben@unimeal.test';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/mediterranean-veggie-wrap-20260920.png' WHERE r.title='Mediterranean Veggie Wrap' AND u.email='contributor.ben@unimeal.test';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/spiced-lentil-soup-20260920.png' WHERE r.title='Spiced Lentil Soup' AND u.email='contributor.ben@unimeal.test';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/teriyaki-chicken-rice-bowl-20260920.png' WHERE r.title='Teriyaki Chicken Rice Bowl' AND u.email='contributor.ben@unimeal.test';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/tomato-and-hummus-toast-20260920.png' WHERE r.title='Tomato and Hummus Toast' AND u.email='yuki@qq.com';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/chickpea-cucumber-wrap-20260920.png' WHERE r.title='Chickpea Cucumber Wrap' AND u.email='yuki@qq.com';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/chicken-and-broccoli-pasta-20260920.png' WHERE r.title='Chicken and Broccoli Pasta' AND u.email='yuki@qq.com';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/mushroom-egg-fried-rice-20260920.png' WHERE r.title='Mushroom Egg Fried Rice' AND u.email='yuki@qq.com';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/creamy-mushroom-risotto-20260920.png' WHERE r.title='Creamy Mushroom Risotto' AND u.email='yuki@qq.com';
UPDATE recipes r JOIN users u ON u.user_id=r.author_user_id SET r.image_url='/images/recipes/handmade-egg-pasta-with-mushrooms-20260920.png' WHERE r.title='Handmade Egg Pasta with Mushrooms' AND u.email='yuki@qq.com';
COMMIT;
