-- --------------------------------------------------------
-- Host:                         159.223.104.19
-- Server version:               8.0.42-0ubuntu0.20.04.1 - (Ubuntu)
-- Server OS:                    Linux
-- HeidiSQL Version:             12.11.0.7065
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Dumping structure for procedure wf_meta.copyToWhatsfresh
DELIMITER //
CREATE PROCEDURE `copyToWhatsfresh`()
    DETERMINISTIC
BEGIN
      -- Disable foreign key checks for faster bulk operations
      SET FOREIGN_KEY_CHECKS = 0;

      -- Start transaction for atomicity
      START TRANSACTION;
       -- Clear existing tables (any order is fine with FK checks disabled)
      DROP TABLE IF EXISTS whatsfresh.accounts;
      DROP TABLE IF EXISTS whatsfresh.accounts_users;
      DROP TABLE IF EXISTS whatsfresh.brands;
      DROP TABLE IF EXISTS whatsfresh.global_measure_units;
      DROP TABLE IF EXISTS whatsfresh.ingredients;
      DROP TABLE IF EXISTS whatsfresh.ingredient_batches;
      DROP TABLE IF EXISTS whatsfresh.ingredient_types;
      DROP TABLE IF EXISTS whatsfresh.products;
      DROP TABLE IF EXISTS whatsfresh.product_batches;
      DROP TABLE IF EXISTS whatsfresh.product_batch_ingredients;
      DROP TABLE IF EXISTS whatsfresh.product_batch_tasks;
      DROP TABLE IF EXISTS whatsfresh.product_recipes;
      DROP TABLE IF EXISTS whatsfresh.product_types;
      DROP TABLE IF EXISTS whatsfresh.tasks;
      DROP TABLE IF EXISTS whatsfresh.users;
      DROP TABLE IF EXISTS whatsfresh.vendors;
      DROP TABLE IF EXISTS whatsfresh.workers;

      -- Copy accounts (parent table - must be first)
      CREATE TABLE whatsfresh.accounts LIKE wf_stage.accounts;
		INSERT INTO whatsfresh.accounts SELECT * FROM wf_stage.accounts;

      CREATE TABLE whatsfresh.users LIKE wf_stage.users;
		INSERT INTO whatsfresh.users SELECT * FROM wf_stage.users;

      -- Copy accounts_users 
      CREATE TABLE whatsfresh.accounts_users LIKE wf_stage.accounts_users;
		INSERT INTO whatsfresh.accounts_users SELECT * FROM wf_stage.accounts_users;

      -- Copy lookup/reference tables
      CREATE TABLE whatsfresh.brands LIKE wf_stage.brands;
		INSERT INTO whatsfresh.brands SELECT * FROM wf_stage.brands;

      CREATE TABLE whatsfresh.vendors LIKE wf_stage.vendors;
		INSERT INTO whatsfresh.vendors SELECT * FROM wf_stage.vendors;

      CREATE TABLE whatsfresh.workers LIKE wf_stage.workers;
		INSERT INTO whatsfresh.workers SELECT * FROM wf_stage.workers;

      CREATE TABLE whatsfresh.ingredient_types LIKE wf_stage.ingredient_types;
      INSERT INTO whatsfresh.ingredient_types SELECT * FROM wf_stage.ingredient_types;

      CREATE TABLE whatsfresh.product_types LIKE wf_stage.product_types;
      INSERT INTO whatsfresh.product_types SELECT * FROM wf_stage.product_types;

      CREATE TABLE whatsfresh.tasks LIKE wf_stage.tasks;
      INSERT INTO whatsfresh.tasks SELECT * FROM wf_stage.tasks;

      CREATE TABLE whatsfresh.ingredients LIKE wf_stage.ingredients;
      INSERT INTO whatsfresh.ingredients SELECT * FROM wf_stage.ingredients;

      CREATE TABLE whatsfresh.products LIKE wf_stage.products;
      INSERT INTO whatsfresh.products SELECT * FROM wf_stage.products;

      -- Re-enable foreign key checks
      SET FOREIGN_KEY_CHECKS = 1;

      -- Commit transaction
      COMMIT;

  END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
