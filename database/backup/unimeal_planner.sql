-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: unimeal_planner
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `unimeal_planner`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `unimeal_planner` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `unimeal_planner`;

--
-- Table structure for table `allergies`
--

DROP TABLE IF EXISTS `allergies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `allergies` (
  `allergy_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `allergy_name` varchar(80) NOT NULL,
  PRIMARY KEY (`allergy_id`),
  UNIQUE KEY `uq_allergies_name` (`allergy_name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `allergies`
--

LOCK TABLES `allergies` WRITE;
/*!40000 ALTER TABLE `allergies` DISABLE KEYS */;
INSERT INTO `allergies` VALUES (1,'Dairy'),(2,'Egg'),(3,'Peanut');
/*!40000 ALTER TABLE `allergies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `budget_periods`
--

DROP TABLE IF EXISTS `budget_periods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `budget_periods` (
  `budget_period_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `period_start` date NOT NULL,
  `period_end` date NOT NULL,
  `budget_amount` decimal(10,2) NOT NULL,
  PRIMARY KEY (`budget_period_id`),
  UNIQUE KEY `uq_budget_periods_user_dates` (`user_id`,`period_start`,`period_end`),
  CONSTRAINT `fk_budget_periods_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `ck_budget_periods_amount` CHECK ((`budget_amount` >= 0)),
  CONSTRAINT `ck_budget_periods_dates` CHECK ((`period_end` >= `period_start`))
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `budget_periods`
--

LOCK TABLES `budget_periods` WRITE;
/*!40000 ALTER TABLE `budget_periods` DISABLE KEYS */;
INSERT INTO `budget_periods` VALUES (1,1,'2026-08-10','2026-08-16',60.00),(8,24,'2026-09-07','2026-09-13',45.00);
/*!40000 ALTER TABLE `budget_periods` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `content_reports`
--

DROP TABLE IF EXISTS `content_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `content_reports` (
  `content_report_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `reporter_user_id` bigint unsigned NOT NULL,
  `recipe_id` bigint unsigned DEFAULT NULL,
  `recipe_comment_id` bigint unsigned DEFAULT NULL,
  `reason` varchar(255) NOT NULL,
  `status` enum('open','reviewing','resolved','dismissed') NOT NULL DEFAULT 'open',
  `reviewed_by_user_id` bigint unsigned DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`content_report_id`),
  KEY `fk_reports_reporter` (`reporter_user_id`),
  KEY `fk_reports_recipe` (`recipe_id`),
  KEY `fk_reports_comment` (`recipe_comment_id`),
  KEY `fk_reports_reviewer` (`reviewed_by_user_id`),
  KEY `idx_reports_status_created` (`status`,`created_at`),
  CONSTRAINT `fk_reports_comment` FOREIGN KEY (`recipe_comment_id`) REFERENCES `recipe_comments` (`recipe_comment_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reports_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`recipe_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reports_reporter` FOREIGN KEY (`reporter_user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `fk_reports_reviewer` FOREIGN KEY (`reviewed_by_user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `ck_reports_subject` CHECK (((`recipe_id` is not null) <> (`recipe_comment_id` is not null)))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `content_reports`
--

LOCK TABLES `content_reports` WRITE;
/*!40000 ALTER TABLE `content_reports` DISABLE KEYS */;
/*!40000 ALTER TABLE `content_reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cuisines`
--

DROP TABLE IF EXISTS `cuisines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cuisines` (
  `cuisine_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `cuisine_name` varchar(60) NOT NULL,
  PRIMARY KEY (`cuisine_id`),
  UNIQUE KEY `uq_cuisines_name` (`cuisine_name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cuisines`
--

LOCK TABLES `cuisines` WRITE;
/*!40000 ALTER TABLE `cuisines` DISABLE KEYS */;
INSERT INTO `cuisines` VALUES (1,'Chinese'),(8,'European'),(5,'Indian'),(2,'Italian'),(4,'Japanese'),(6,'Mediterranean'),(7,'Middle Eastern'),(3,'New Zealand');
/*!40000 ALTER TABLE `cuisines` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dietary_tags`
--

DROP TABLE IF EXISTS `dietary_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dietary_tags` (
  `dietary_tag_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `tag_name` varchar(60) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`dietary_tag_id`),
  UNIQUE KEY `uq_dietary_tags_name` (`tag_name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dietary_tags`
--

LOCK TABLES `dietary_tags` WRITE;
/*!40000 ALTER TABLE `dietary_tags` DISABLE KEYS */;
INSERT INTO `dietary_tags` VALUES (1,'Vegetarian','No meat or fish'),(2,'Vegan','No animal-derived ingredients'),(3,'Gluten-Free','Prepared without gluten-containing ingredients'),(4,'High Protein','Higher-protein recipe'),(5,'Budget','Low-cost student-friendly recipe');
/*!40000 ALTER TABLE `dietary_tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ingredient_allergens`
--

DROP TABLE IF EXISTS `ingredient_allergens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ingredient_allergens` (
  `ingredient_id` bigint unsigned NOT NULL,
  `allergy_id` smallint unsigned NOT NULL,
  PRIMARY KEY (`ingredient_id`,`allergy_id`),
  KEY `fk_ia_allergy` (`allergy_id`),
  CONSTRAINT `fk_ia_allergy` FOREIGN KEY (`allergy_id`) REFERENCES `allergies` (`allergy_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ia_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ingredient_allergens`
--

LOCK TABLES `ingredient_allergens` WRITE;
/*!40000 ALTER TABLE `ingredient_allergens` DISABLE KEYS */;
INSERT INTO `ingredient_allergens` VALUES (5,1);
/*!40000 ALTER TABLE `ingredient_allergens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ingredient_categories`
--

DROP TABLE IF EXISTS `ingredient_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ingredient_categories` (
  `ingredient_category_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `category_name` varchar(60) NOT NULL,
  PRIMARY KEY (`ingredient_category_id`),
  UNIQUE KEY `uq_ingredient_categories_name` (`category_name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ingredient_categories`
--

LOCK TABLES `ingredient_categories` WRITE;
/*!40000 ALTER TABLE `ingredient_categories` DISABLE KEYS */;
INSERT INTO `ingredient_categories` VALUES (3,'Dairy'),(1,'Grains'),(5,'Pantry'),(2,'Produce'),(4,'Protein');
/*!40000 ALTER TABLE `ingredient_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ingredients`
--

DROP TABLE IF EXISTS `ingredients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ingredients` (
  `ingredient_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `ingredient_category_id` smallint unsigned NOT NULL,
  `ingredient_name` varchar(120) NOT NULL,
  `default_measurement_unit_id` smallint unsigned DEFAULT NULL,
  `estimated_unit_cost` decimal(12,4) NOT NULL DEFAULT '0.0000',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`ingredient_id`),
  UNIQUE KEY `uq_ingredients_name` (`ingredient_name`),
  KEY `fk_ingredients_default_unit` (`default_measurement_unit_id`),
  KEY `idx_ingredients_category_active` (`ingredient_category_id`,`is_active`),
  CONSTRAINT `fk_ingredients_category` FOREIGN KEY (`ingredient_category_id`) REFERENCES `ingredient_categories` (`ingredient_category_id`),
  CONSTRAINT `fk_ingredients_default_unit` FOREIGN KEY (`default_measurement_unit_id`) REFERENCES `measurement_units` (`measurement_unit_id`),
  CONSTRAINT `ck_ingredients_estimated_unit_cost` CHECK ((`estimated_unit_cost` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ingredients`
--

LOCK TABLES `ingredients` WRITE;
/*!40000 ALTER TABLE `ingredients` DISABLE KEYS */;
INSERT INTO `ingredients` VALUES (1,1,'Rice',1,0.0020,1),(2,2,'Tomato',5,0.5000,1),(3,2,'Onion',5,0.4000,1),(4,4,'Egg',5,0.4500,1),(5,3,'Milk',3,0.0020,1),(6,1,'Bread',5,0.2500,1),(7,2,'Broccoli',1,0.0050,1),(8,2,'Carrot',5,0.3000,1),(9,4,'Chicken',1,0.0080,1),(10,4,'Chickpeas',1,0.0030,1),(11,5,'Coconut Milk',3,0.0060,1),(12,3,'Cream',3,0.0080,1),(13,2,'Cucumber',5,0.6000,1),(14,5,'Cumin',1,0.0200,1),(15,2,'Garlic',5,0.1000,1),(16,5,'Hummus',1,0.0100,1),(17,4,'Lentils',1,0.0020,1),(18,2,'Mushrooms',1,0.0070,1),(19,1,'Pasta',1,0.0030,1),(20,1,'Wrap',5,0.4000,1);
/*!40000 ALTER TABLE `ingredients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `meal_plan_entries`
--

DROP TABLE IF EXISTS `meal_plan_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `meal_plan_entries` (
  `meal_plan_entry_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `meal_plan_id` bigint unsigned NOT NULL,
  `recipe_id` bigint unsigned NOT NULL,
  `planned_date` date NOT NULL,
  `meal_type` enum('breakfast','lunch','dinner','snack') NOT NULL,
  `servings` tinyint unsigned NOT NULL,
  `notes` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`meal_plan_entry_id`),
  UNIQUE KEY `uq_mpe_slot` (`meal_plan_id`,`planned_date`,`meal_type`),
  KEY `idx_mpe_recipe_date` (`recipe_id`,`planned_date`),
  CONSTRAINT `fk_mpe_meal_plan` FOREIGN KEY (`meal_plan_id`) REFERENCES `meal_plans` (`meal_plan_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mpe_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`recipe_id`),
  CONSTRAINT `ck_mpe_servings` CHECK ((`servings` between 1 and 50))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `meal_plan_entries`
--

LOCK TABLES `meal_plan_entries` WRITE;
/*!40000 ALTER TABLE `meal_plan_entries` DISABLE KEYS */;
INSERT INTO `meal_plan_entries` VALUES (1,1,1,'2026-08-10','dinner',2,'Use pantry rice if available.'),(6,6,3,'2026-09-08','breakfast',2,NULL);
/*!40000 ALTER TABLE `meal_plan_entries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `meal_plans`
--

DROP TABLE IF EXISTS `meal_plans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `meal_plans` (
  `meal_plan_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `week_start_date` date NOT NULL,
  `plan_name` varchar(100) NOT NULL DEFAULT 'Weekly meal plan',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`meal_plan_id`),
  UNIQUE KEY `uq_meal_plans_user_week` (`user_id`,`week_start_date`),
  CONSTRAINT `fk_meal_plans_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `meal_plans`
--

LOCK TABLES `meal_plans` WRITE;
/*!40000 ALTER TABLE `meal_plans` DISABLE KEYS */;
INSERT INTO `meal_plans` VALUES (1,1,'2026-08-10','Week 4 student meal plan','2026-09-06 09:25:16','2026-09-06 09:25:16'),(6,24,'2026-09-07','Weekly meal plan','2026-09-07 20:48:09','2026-09-07 20:48:09');
/*!40000 ALTER TABLE `meal_plans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `measurement_units`
--

DROP TABLE IF EXISTS `measurement_units`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `measurement_units` (
  `measurement_unit_id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `unit_name` varchar(40) NOT NULL,
  `unit_symbol` varchar(12) NOT NULL,
  `unit_type` enum('weight','volume','count','other') NOT NULL,
  PRIMARY KEY (`measurement_unit_id`),
  UNIQUE KEY `uq_measurement_units_name` (`unit_name`),
  UNIQUE KEY `uq_measurement_units_symbol` (`unit_symbol`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `measurement_units`
--

LOCK TABLES `measurement_units` WRITE;
/*!40000 ALTER TABLE `measurement_units` DISABLE KEYS */;
INSERT INTO `measurement_units` VALUES (1,'gram','g','weight'),(2,'kilogram','kg','weight'),(3,'millilitre','ml','volume'),(4,'litre','L','volume'),(5,'piece','pc','count'),(6,'tablespoon','tbsp','volume'),(7,'teaspoon','tsp','volume'),(8,'cup','cup','volume');
/*!40000 ALTER TABLE `measurement_units` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `notification_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `notification_type` enum('meal_reminder','shopping_reminder','recipe_update','system') NOT NULL,
  `title` varchar(160) NOT NULL,
  `message` text NOT NULL,
  `scheduled_for` timestamp NULL DEFAULT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`notification_id`),
  KEY `idx_notifications_user_read_scheduled` (`user_id`,`read_at`,`scheduled_for`),
  CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,1,'meal_reminder','Dinner plan reminder','Tomato Rice Bowl is planned for dinner on Monday.','2026-08-10 09:00:00',NULL,'2026-09-06 09:25:16');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pantry_items`
--

DROP TABLE IF EXISTS `pantry_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pantry_items` (
  `pantry_item_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `ingredient_id` bigint unsigned NOT NULL,
  `measurement_unit_id` smallint unsigned NOT NULL,
  `quantity` decimal(10,3) NOT NULL,
  `expiry_date` date DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`pantry_item_id`),
  UNIQUE KEY `uq_pantry_item` (`user_id`,`ingredient_id`,`measurement_unit_id`),
  KEY `fk_pantry_ingredient` (`ingredient_id`),
  KEY `fk_pantry_unit` (`measurement_unit_id`),
  CONSTRAINT `fk_pantry_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`),
  CONSTRAINT `fk_pantry_unit` FOREIGN KEY (`measurement_unit_id`) REFERENCES `measurement_units` (`measurement_unit_id`),
  CONSTRAINT `fk_pantry_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `ck_pantry_quantity` CHECK ((`quantity` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pantry_items`
--

LOCK TABLES `pantry_items` WRITE;
/*!40000 ALTER TABLE `pantry_items` DISABLE KEYS */;
INSERT INTO `pantry_items` VALUES (1,1,1,1,500.000,'2026-09-01','2026-09-06 09:25:16');
/*!40000 ALTER TABLE `pantry_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recipe_comments`
--

DROP TABLE IF EXISTS `recipe_comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recipe_comments` (
  `recipe_comment_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `recipe_id` bigint unsigned NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `comment_text` text NOT NULL,
  `is_hidden` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`recipe_comment_id`),
  KEY `fk_recipe_comments_user` (`user_id`),
  KEY `idx_recipe_comments_recipe_created` (`recipe_id`,`created_at`),
  CONSTRAINT `fk_recipe_comments_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`recipe_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_recipe_comments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `ck_recipe_comments_text` CHECK ((char_length(trim(`comment_text`)) > 0))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recipe_comments`
--

LOCK TABLES `recipe_comments` WRITE;
/*!40000 ALTER TABLE `recipe_comments` DISABLE KEYS */;
INSERT INTO `recipe_comments` VALUES (1,1,1,'Affordable, quick and easy to make after class.',0,'2026-09-06 09:25:16','2026-09-06 09:25:16');
/*!40000 ALTER TABLE `recipe_comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recipe_dietary_tags`
--

DROP TABLE IF EXISTS `recipe_dietary_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recipe_dietary_tags` (
  `recipe_id` bigint unsigned NOT NULL,
  `dietary_tag_id` smallint unsigned NOT NULL,
  PRIMARY KEY (`recipe_id`,`dietary_tag_id`),
  KEY `fk_rdt_tag` (`dietary_tag_id`),
  CONSTRAINT `fk_rdt_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`recipe_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rdt_tag` FOREIGN KEY (`dietary_tag_id`) REFERENCES `dietary_tags` (`dietary_tag_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recipe_dietary_tags`
--

LOCK TABLES `recipe_dietary_tags` WRITE;
/*!40000 ALTER TABLE `recipe_dietary_tags` DISABLE KEYS */;
INSERT INTO `recipe_dietary_tags` VALUES (1,1);
/*!40000 ALTER TABLE `recipe_dietary_tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recipe_ingredients`
--

DROP TABLE IF EXISTS `recipe_ingredients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recipe_ingredients` (
  `recipe_ingredient_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `recipe_id` bigint unsigned NOT NULL,
  `ingredient_id` bigint unsigned NOT NULL,
  `measurement_unit_id` smallint unsigned NOT NULL,
  `quantity` decimal(10,3) NOT NULL,
  `preparation_note` varchar(160) DEFAULT NULL,
  `sort_order` smallint unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`recipe_ingredient_id`),
  UNIQUE KEY `uq_recipe_ingredients_line` (`recipe_id`,`ingredient_id`,`measurement_unit_id`,`sort_order`),
  KEY `fk_ri_unit` (`measurement_unit_id`),
  KEY `idx_ri_ingredient` (`ingredient_id`),
  CONSTRAINT `fk_ri_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`),
  CONSTRAINT `fk_ri_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`recipe_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ri_unit` FOREIGN KEY (`measurement_unit_id`) REFERENCES `measurement_units` (`measurement_unit_id`),
  CONSTRAINT `ck_ri_quantity` CHECK ((`quantity` > 0)),
  CONSTRAINT `ck_ri_sort_order` CHECK ((`sort_order` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recipe_ingredients`
--

LOCK TABLES `recipe_ingredients` WRITE;
/*!40000 ALTER TABLE `recipe_ingredients` DISABLE KEYS */;
INSERT INTO `recipe_ingredients` VALUES (1,1,1,1,200.000,NULL,1),(2,1,2,5,2.000,NULL,2),(3,1,3,5,1.000,NULL,3),(4,2,4,5,2.000,NULL,1),(5,2,5,3,100.000,NULL,2),(6,2,6,5,2.000,NULL,3);
/*!40000 ALTER TABLE `recipe_ingredients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recipe_ratings`
--

DROP TABLE IF EXISTS `recipe_ratings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recipe_ratings` (
  `user_id` bigint unsigned NOT NULL,
  `recipe_id` bigint unsigned NOT NULL,
  `rating` tinyint unsigned NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`,`recipe_id`),
  KEY `fk_recipe_ratings_recipe` (`recipe_id`),
  CONSTRAINT `fk_recipe_ratings_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`recipe_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_recipe_ratings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `ck_recipe_ratings_value` CHECK ((`rating` between 1 and 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recipe_ratings`
--

LOCK TABLES `recipe_ratings` WRITE;
/*!40000 ALTER TABLE `recipe_ratings` DISABLE KEYS */;
INSERT INTO `recipe_ratings` VALUES (1,1,5,'2026-09-06 09:25:16','2026-09-06 09:25:16');
/*!40000 ALTER TABLE `recipe_ratings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recipe_steps`
--

DROP TABLE IF EXISTS `recipe_steps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recipe_steps` (
  `recipe_step_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `recipe_id` bigint unsigned NOT NULL,
  `step_number` smallint unsigned NOT NULL,
  `instruction` text NOT NULL,
  PRIMARY KEY (`recipe_step_id`),
  UNIQUE KEY `uq_recipe_steps_order` (`recipe_id`,`step_number`),
  CONSTRAINT `fk_recipe_steps_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`recipe_id`) ON DELETE CASCADE,
  CONSTRAINT `ck_recipe_steps_number` CHECK ((`step_number` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recipe_steps`
--

LOCK TABLES `recipe_steps` WRITE;
/*!40000 ALTER TABLE `recipe_steps` DISABLE KEYS */;
INSERT INTO `recipe_steps` VALUES (1,1,1,'Cook the rice according to the package instructions.'),(2,1,2,'Saute onion and tomato, then serve over rice.');
/*!40000 ALTER TABLE `recipe_steps` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recipes`
--

DROP TABLE IF EXISTS `recipes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recipes` (
  `recipe_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `author_user_id` bigint unsigned NOT NULL,
  `cuisine_id` smallint unsigned DEFAULT NULL,
  `title` varchar(160) NOT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `description` text,
  `preparation_minutes` smallint unsigned NOT NULL DEFAULT '0',
  `cooking_minutes` smallint unsigned NOT NULL DEFAULT '0',
  `servings` tinyint unsigned NOT NULL,
  `difficulty` enum('easy','medium','hard') NOT NULL DEFAULT 'easy',
  `estimated_cost` decimal(10,2) NOT NULL DEFAULT '0.00',
  `status` enum('draft','published','archived') NOT NULL DEFAULT 'draft',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`recipe_id`),
  KEY `idx_recipes_discovery` (`status`,`difficulty`,`estimated_cost`),
  KEY `idx_recipes_author` (`author_user_id`),
  KEY `idx_recipes_cuisine` (`cuisine_id`),
  FULLTEXT KEY `ft_recipes_title_description` (`title`,`description`),
  CONSTRAINT `fk_recipes_author` FOREIGN KEY (`author_user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `fk_recipes_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `cuisines` (`cuisine_id`) ON DELETE SET NULL,
  CONSTRAINT `ck_recipes_cost` CHECK ((`estimated_cost` >= 0)),
  CONSTRAINT `ck_recipes_servings` CHECK ((`servings` between 1 and 50))
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recipes`
--

LOCK TABLES `recipes` WRITE;
/*!40000 ALTER TABLE `recipes` DISABLE KEYS */;
INSERT INTO `recipes` VALUES (1,2,1,'Tomato Rice Bowl',NULL,'A low-cost vegetarian rice bowl for a busy student.',10,20,2,'easy',4.50,'published','2026-09-06 09:25:16','2026-09-06 09:25:16'),(2,2,3,'Egg on Toast',NULL,'A simple breakfast recipe with egg, milk and bread.',5,10,1,'easy',2.80,'published','2026-09-06 09:25:16','2026-09-06 09:25:16'),(3,2,5,'Chickpea Coconut Curry','https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=900&q=80','A vegan coconut curry for an affordable dinner.',10,25,1,'easy',4.20,'published','2026-09-06 09:25:16','2026-09-06 09:25:16'),(4,2,2,'Creamy Tomato Pasta','https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=900&q=80','A creamy vegetarian pasta for a quick student dinner.',5,20,1,'easy',4.80,'published','2026-09-06 09:25:16','2026-09-06 09:25:16'),(5,2,8,'Garlic Mushroom Toast','https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=900&q=80','Crisp toast topped with garlic mushrooms.',5,15,1,'easy',3.20,'published','2026-09-06 09:25:16','2026-09-06 09:25:16'),(6,2,6,'Mediterranean Veggie Wrap','https://images.unsplash.com/photo-1626700051175-6818013e1d4f?auto=format&fit=crop&w=900&q=80','A quick vegetarian wrap with hummus and cucumber.',10,5,1,'easy',3.90,'published','2026-09-06 09:25:16','2026-09-06 09:25:16'),(7,2,7,'Spiced Lentil Soup','https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=900&q=80','A budget-friendly lentil soup with warming spices.',10,35,1,'medium',3.50,'published','2026-09-06 09:25:16','2026-09-06 09:25:16'),(8,2,4,'Teriyaki Chicken Rice Bowl','https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=900&q=80','A simple chicken rice bowl with broccoli.',10,20,1,'easy',5.60,'published','2026-09-06 09:25:16','2026-09-06 09:25:16');
/*!40000 ALTER TABLE `recipes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `role_id` tinyint unsigned NOT NULL AUTO_INCREMENT,
  `role_name` varchar(30) NOT NULL,
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uq_roles_role_name` (`role_name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (3,'administrator'),(2,'contributor'),(1,'student');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `saved_recipes`
--

DROP TABLE IF EXISTS `saved_recipes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `saved_recipes` (
  `user_id` bigint unsigned NOT NULL,
  `recipe_id` bigint unsigned NOT NULL,
  `saved_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`,`recipe_id`),
  KEY `fk_saved_recipes_recipe` (`recipe_id`),
  CONSTRAINT `fk_saved_recipes_recipe` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`recipe_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_saved_recipes_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `saved_recipes`
--

LOCK TABLES `saved_recipes` WRITE;
/*!40000 ALTER TABLE `saved_recipes` DISABLE KEYS */;
INSERT INTO `saved_recipes` VALUES (1,1,'2026-09-06 09:25:16');
/*!40000 ALTER TABLE `saved_recipes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shopping_list_items`
--

DROP TABLE IF EXISTS `shopping_list_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shopping_list_items` (
  `shopping_list_item_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `shopping_list_id` bigint unsigned NOT NULL,
  `ingredient_id` bigint unsigned DEFAULT NULL,
  `measurement_unit_id` smallint unsigned NOT NULL,
  `item_name` varchar(160) NOT NULL,
  `quantity` decimal(10,3) NOT NULL,
  `estimated_unit_cost` decimal(10,2) DEFAULT NULL,
  `actual_cost` decimal(10,2) DEFAULT NULL,
  `is_purchased` tinyint(1) NOT NULL DEFAULT '0',
  `purchased_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`shopping_list_item_id`),
  KEY `fk_sli_ingredient` (`ingredient_id`),
  KEY `fk_sli_unit` (`measurement_unit_id`),
  KEY `idx_sli_list_purchased` (`shopping_list_id`,`is_purchased`),
  CONSTRAINT `fk_sli_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sli_list` FOREIGN KEY (`shopping_list_id`) REFERENCES `shopping_lists` (`shopping_list_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sli_unit` FOREIGN KEY (`measurement_unit_id`) REFERENCES `measurement_units` (`measurement_unit_id`),
  CONSTRAINT `ck_sli_actual_cost` CHECK (((`actual_cost` is null) or (`actual_cost` >= 0))),
  CONSTRAINT `ck_sli_estimated_cost` CHECK (((`estimated_unit_cost` is null) or (`estimated_unit_cost` >= 0))),
  CONSTRAINT `ck_sli_purchase_time` CHECK ((((`is_purchased` = false) and (`purchased_at` is null)) or ((`is_purchased` = true) and (`purchased_at` is not null)))),
  CONSTRAINT `ck_sli_quantity` CHECK ((`quantity` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shopping_list_items`
--

LOCK TABLES `shopping_list_items` WRITE;
/*!40000 ALTER TABLE `shopping_list_items` DISABLE KEYS */;
INSERT INTO `shopping_list_items` VALUES (1,1,1,1,'Rice',200.000,0.01,NULL,0,NULL),(2,1,2,5,'Tomato',2.000,0.80,NULL,0,NULL);
/*!40000 ALTER TABLE `shopping_list_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shopping_lists`
--

DROP TABLE IF EXISTS `shopping_lists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shopping_lists` (
  `shopping_list_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `meal_plan_id` bigint unsigned DEFAULT NULL,
  `list_name` varchar(100) NOT NULL DEFAULT 'Shopping list',
  `status` enum('active','completed','archived') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`shopping_list_id`),
  KEY `fk_shopping_lists_meal_plan` (`meal_plan_id`),
  KEY `idx_shopping_lists_user_status` (`user_id`,`status`),
  CONSTRAINT `fk_shopping_lists_meal_plan` FOREIGN KEY (`meal_plan_id`) REFERENCES `meal_plans` (`meal_plan_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_shopping_lists_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shopping_lists`
--

LOCK TABLES `shopping_lists` WRITE;
/*!40000 ALTER TABLE `shopping_lists` DISABLE KEYS */;
INSERT INTO `shopping_lists` VALUES (1,1,1,'Week 4 groceries','active','2026-09-06 09:25:16','2026-09-06 09:25:16');
/*!40000 ALTER TABLE `shopping_lists` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_allergies`
--

DROP TABLE IF EXISTS `user_allergies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_allergies` (
  `user_id` bigint unsigned NOT NULL,
  `allergy_id` smallint unsigned NOT NULL,
  PRIMARY KEY (`user_id`,`allergy_id`),
  KEY `fk_ua_allergy` (`allergy_id`),
  CONSTRAINT `fk_ua_allergy` FOREIGN KEY (`allergy_id`) REFERENCES `allergies` (`allergy_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ua_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_allergies`
--

LOCK TABLES `user_allergies` WRITE;
/*!40000 ALTER TABLE `user_allergies` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_allergies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_dietary_preferences`
--

DROP TABLE IF EXISTS `user_dietary_preferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_dietary_preferences` (
  `user_id` bigint unsigned NOT NULL,
  `dietary_tag_id` smallint unsigned NOT NULL,
  PRIMARY KEY (`user_id`,`dietary_tag_id`),
  KEY `fk_udp_tag` (`dietary_tag_id`),
  CONSTRAINT `fk_udp_tag` FOREIGN KEY (`dietary_tag_id`) REFERENCES `dietary_tags` (`dietary_tag_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_udp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_dietary_preferences`
--

LOCK TABLES `user_dietary_preferences` WRITE;
/*!40000 ALTER TABLE `user_dietary_preferences` DISABLE KEYS */;
INSERT INTO `user_dietary_preferences` VALUES (1,1);
/*!40000 ALTER TABLE `user_dietary_preferences` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `role_id` tinyint unsigned NOT NULL,
  `email` varchar(254) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `display_name` varchar(80) NOT NULL,
  `cooking_skill` enum('beginner','intermediate','advanced') NOT NULL DEFAULT 'beginner',
  `kitchen_access` enum('none','limited','shared','full') NOT NULL DEFAULT 'shared',
  `favourite_cuisines_note` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uq_users_email` (`email`),
  KEY `idx_users_role_active` (`role_id`,`is_active`),
  CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`),
  CONSTRAINT `ck_users_email` CHECK ((`email` like _utf8mb4'%_@_%._%')),
  CONSTRAINT `ck_users_password_hash` CHECK ((char_length(`password_hash`) >= 20))
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,1,'student.alice@unimeal.test','$2b$12$z55vKHzHo6z7Twi9krFDb.Wwwm5e8j36GOwlnFvGCpcjiIMkZUFW6','Alice Student','beginner','shared','Chinese, Italian',1,'2026-09-06 09:25:16','2026-09-06 09:25:16'),(2,2,'contributor.ben@unimeal.test','$2b$12$yxZBPbcFfhxixwJ1E5mKQeGYgshMPHuvbJ8yvq1xmsH0SowRDhmzW','Ben Contributor','advanced','full','Chinese',1,'2026-09-06 09:25:16','2026-09-06 09:25:16'),(3,3,'admin@unimeal.test','$2b$12$T9hjocV3mVwUQ2qOLhNDV.1UiQhILkmeZWhwKybXV2zlDg9oxPA8y','UniMeal Administrator','intermediate','full',NULL,1,'2026-09-06 09:25:16','2026-09-06 09:25:16'),(4,1,'student.michael@unimeal.test','$2b$12$wGqxGaBOFmgzYVjYHecpQOtTPKV9kjPOKDU27oOyaHC0VHDDlJ1Ou','Michael Student','beginner','shared','Italian, Japanese, Indian',1,'2026-09-06 09:25:16','2026-09-06 09:25:16'),(24,1,'123@qq.com','pbkdf2_sha256$600000$fbd9db044405e1fa1080cd9d7ad5800e$315a1b332816b40fa84d1b6b87e62b89e2d1e14ef2f5cbb2f846b7674459fda6','Yukino','beginner','shared',NULL,1,'2026-09-07 20:47:55','2026-09-07 20:47:55');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `vw_recipe_cards`
--

DROP TABLE IF EXISTS `vw_recipe_cards`;
/*!50001 DROP VIEW IF EXISTS `vw_recipe_cards`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_recipe_cards` AS SELECT 
 1 AS `id`,
 1 AS `title`,
 1 AS `image_url`,
 1 AS `cuisine`,
 1 AS `difficulty`,
 1 AS `estimated_recipe_cost`,
 1 AS `estimated_cost_per_serving`,
 1 AS `cook_time`,
 1 AS `rating`,
 1 AS `review_count`,
 1 AS `dietary_tags`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'unimeal_planner'
--

--
-- Dumping routines for database 'unimeal_planner'
--

--
-- Current Database: `unimeal_planner`
--

USE `unimeal_planner`;

--
-- Final view structure for view `vw_recipe_cards`
--

/*!50001 DROP VIEW IF EXISTS `vw_recipe_cards`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_recipe_cards` AS select `r`.`recipe_id` AS `id`,`r`.`title` AS `title`,`r`.`image_url` AS `image_url`,coalesce(`c`.`cuisine_name`,'Unclassified') AS `cuisine`,(case `r`.`difficulty` when 'easy' then 'Easy' when 'medium' then 'Medium' when 'hard' then 'Hard' end) AS `difficulty`,`r`.`estimated_cost` AS `estimated_recipe_cost`,round((`r`.`estimated_cost` / nullif(`r`.`servings`,0)),2) AS `estimated_cost_per_serving`,(`r`.`preparation_minutes` + `r`.`cooking_minutes`) AS `cook_time`,coalesce((select round(avg(`rr`.`rating`),1) from `recipe_ratings` `rr` where (`rr`.`recipe_id` = `r`.`recipe_id`)),0.0) AS `rating`,(select count(0) from `recipe_ratings` `rr` where (`rr`.`recipe_id` = `r`.`recipe_id`)) AS `review_count`,coalesce((select group_concat(`dt`.`tag_name` order by `dt`.`tag_name` ASC separator ', ') from (`recipe_dietary_tags` `rdt` join `dietary_tags` `dt` on((`dt`.`dietary_tag_id` = `rdt`.`dietary_tag_id`))) where (`rdt`.`recipe_id` = `r`.`recipe_id`)),'') AS `dietary_tags` from (`recipes` `r` left join `cuisines` `c` on((`c`.`cuisine_id` = `r`.`cuisine_id`))) where (`r`.`status` = 'published') */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-08  4:52:42
