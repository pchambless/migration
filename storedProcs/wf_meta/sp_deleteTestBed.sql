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

-- Dumping structure for procedure wf_meta.sp_deleteTestBed
DELIMITER //
CREATE PROCEDURE `sp_deleteTestBed`()
BEGIN
	delete b from whatsfresh.product_batch_ingredients b
	join 
	(select prd_btch_ingr_id
	from   whatsfresh.v_prd_btch_ingr_dtl
	where acct_id = 3) a
	on b.id = a.prd_btch_ingr_id
	;delete b 
	from whatsfresh.product_batch_tasks b
	join 
	(select prd_task_id
	from   whatsfresh.v_prd_btch_task_dtl
	where acct_id = 3) a
	on b.id = a.prd_task_id
	;delete b 
	from whatsfresh.product_batches b
	join 
	(select prd_btch_id
	from   whatsfresh.v_prd_btch_dtl
	where acct_id = 3) a
	on b.id = a.prd_btch_id
	;delete b 
	from whatsfresh.ingredient_batches b
	join 
	(select ingr_btch_id
	from   whatsfresh.v_ingr_btch_dtl
	where acct_id = 3) a
	on b.id = a.ingr_btch_id
	;delete b 
	from whatsfresh.product_recipes b
	join 
	(select prd_rcpe_id
	from   whatsfresh.v_prd_rcpe_dtl
	where acct_id = 3) a
	on b.id = a.prd_rcpe_id
	;delete from whatsfresh.products
	where account_id = 3
	;delete from whatsfresh.ingredients
	where account_id = 3
	;delete from whatsfresh.product_types
	where account_id = 3
	;delete from whatsfresh.ingredient_types
	where account_id = 3
	;delete from whatsfresh.shop_event
	where account_id = 3
/*
	;delete from whatsfresh.tasks
	where account_id = 3
	;delete from whatsfresh.vendors
	where account_id = 3
	;delete from whatsfresh.brands
	where account_id = 3
	;delete from whatsfresh.workers
	where account_id = 3
*/
	;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
