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

-- Dumping structure for procedure wf_meta.convertIndices
DELIMITER //
CREATE PROCEDURE `convertIndices`()
BEGIN
	alter table whatsfresh.ingredient_batches
	add unique index (ingredient_id, batch_number) using BTREE,
	add index ib_ingrBtch_idx (id) using BTREE,
	add index ib_ingr_idx (ingredient_id) using BTREE,
	add INDEX ib_vndr_idx (vendor_id) USING BTREE,
	add INDEX ib_brnd_idx (brand_id) USING BTREE,
	add INDEX ib_measure_idx (measure_id) USING BTREE,
	add INDEX ib_btch_idx (batch_number) USING BTREE,
	add index ib_shop_idx (shop_event_id) using btree
	;
	alter table whatsfresh.product_batches
	add unique index (product_id, batch_number) using BTREE,
	add index pb_prodBtch_idx (id) using BTREE,
	add index pb_prod_idx (product_id) using BTREE,
	add INDEX pb_measure_idx (measure_id) USING BTREE,
	add INDEX pb_btch_idx (batch_number) USING BTREE
	;
	alter table whatsfresh.product_recipes
	add unique index (id, ingredient_id) using BTREE,
	add index pr_prodRcpe_idx (id) using BTREE,
	add index pr_prod_idx (product_id) using BTREE,
	add index pr_ingr_idx (ingredient_id) using BTREE
	;
   alter table whatsfresh.product_batch_ingredients
	add UNIQUE INDEX prodIngrRcpe_idx (product_batch_id, product_recipe_id, ingredient_batch_id) USING BTREE,
	add index pbi_prodBtch_idx (product_batch_id) using BTREE,
	add index pbi_ingrBtch_idx (ingredient_batch_id) using BTREE,
	add index pbi_rcpe_idx (product_recipe_id) using BTREE
	;
	alter table whatsfresh.product_batch_tasks
	add index pbt_task_idx (task_id) using btree,
	add index pbt_btch_idx (product_batch_id) using btree
	;
	alter table whatsfresh.shop_event
	add index se_shop_idx (id) using btree
	;
	 -- Add active generated columns (1/0 format instead of Y/blank) to all main entity tables
  ALTER TABLE whatsfresh.accounts
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;

  ALTER TABLE whatsfresh.users
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;

  ALTER TABLE whatsfresh.products
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;

  ALTER TABLE whatsfresh.ingredients
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;

  ALTER TABLE whatsfresh.brands
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;

  ALTER TABLE whatsfresh.vendors
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;

  ALTER TABLE whatsfresh.workers
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;

  ALTER TABLE whatsfresh.ingredient_types
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;

  ALTER TABLE whatsfresh.product_types
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;

  ALTER TABLE whatsfresh.tasks
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;
   
  ALTER TABLE whatsfresh.measures
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;
   
  ALTER TABLE whatsfresh.accounts_users
   MODIFY COLUMN created_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN updated_by VARCHAR(50) NULL DEFAULT NULL,
   MODIFY COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL,
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED
   ;
  
  ALTER TABLE whatsfresh.ingredient_batches
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED;

  ALTER TABLE whatsfresh.product_batches
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED;

  ALTER TABLE whatsfresh.product_recipes
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED;

  ALTER TABLE whatsfresh.product_batch_ingredients
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED;

  ALTER TABLE whatsfresh.product_batch_tasks
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED;
   
  
      
  ALTER TABLE whatsfresh.shop_event
   ADD COLUMN active TINYINT(1) AS (case when (deleted_at is null) then 1 else 0 end) STORED;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
