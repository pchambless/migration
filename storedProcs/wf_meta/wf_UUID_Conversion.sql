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

-- Dumping structure for procedure wf_meta.wf_UUID_Conversion
DELIMITER //
CREATE PROCEDURE `wf_UUID_Conversion`()
BEGIN
-- Drop tables in the order they need to be dropped because of Indexes and constraints
	drop table if exists whatsfresh.product_batch_ingredients;
	drop table if exists whatsfresh.product_batch_tasks;
	drop table if exists whatsfresh.product_recipes;
	drop table if exists whatsfresh.product_batches;
	drop table if exists whatsfresh.products;
	drop table if exists whatsfresh.ingredient_batches;
	drop table if exists whatsfresh.shop_event;
	drop table if exists whatsfresh.measures;         
	drop table if exists whatsfresh.account_settings; 
	
-- Run the Conversions
	CALL wf_meta.convertIngrBtch();
	CALL wf_meta.convertProd;
	CALL wf_meta.convertProdBtch();
	CALL wf_meta.convertRcpeBtch();
	CALL wf_meta.convertTaskBtch();
	call wf_meta.convertProdIngr_Map();
	call wf_meta.createShopEvent();
	call wf_meta.ConvertMeasureUnits();
	
	call wf_meta.convertIndices()
;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
