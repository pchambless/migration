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

-- Dumping structure for procedure wf_meta.sp_delete_account
DELIMITER //
CREATE PROCEDURE `sp_delete_account`(
	IN i_acct_id INT
)
BEGIN
	delete b from product_batch_ingredients b
	join 
	(select prd_btch_ingr_id
	from   v_prd_btch_ingr_dtl
	where acct_id = i_acct_id) a
	on b.id = a.prd_btch_ingr_id
	;delete b from product_batch_tasks b
	join 
	(select prd_task_id
	from   v_prd_btch_task_dtl
	where acct_id = i_acct_id) a
	on b.id = a.prd_task_id
	;delete b from product_batches b
	join 
	(select prd_btch_id
	from   v_prd_btch_dtl
	where acct_id = i_acct_id) a
	on b.id = a.prd_btch_id
	;delete b from ingredient_batches b
	join 
	(select ingr_btch_id
	from   v_ingr_btch_dtl
	where acct_id = i_acct_id) a
	on b.id = a.ingr_btch_id
	;delete b from product_recipes b
	join 
	(select prd_rcpe_id
	from   v_prd_rcpe_dtl
	where acct_id = i_acct_id) a
	on b.id = a.prd_rcpe_id
	;delete from products
	where account_id = i_acct_id
	;delete from ingredients
	where account_id = i_acct_id
	;delete from product_types
	where account_id = i_acct_id
	;delete from ingredient_types
	where account_id = i_acct_id
	;delete from vendors 
	where account_id = i_acct_id
	;delete from brands
	where account_id = i_acct_id
	;delete from tasks
	where account_id = i_acct_id
	;delete from workers
	where account_id = i_acct_id
	;END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
