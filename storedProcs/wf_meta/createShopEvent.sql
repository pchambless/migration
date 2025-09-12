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

-- Dumping structure for procedure wf_meta.createShopEvent
DELIMITER //
CREATE PROCEDURE `createShopEvent`()
BEGIN
-- drop the table
   drop table if exists whatsfresh.shop_event
   ;
-- Create the table
	CREATE TABLE whatsfresh.shop_event (
	id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Non-Intelligent ID',
	account_id INT UNSIGNED NOT NULL,
	shop_date TIMESTAMP NULL DEFAULT (CURRENT_TIMESTAMP),
	vendor_id INT UNSIGNED NOT NULL,
	total_amount DECIMAL(13,2) NULL DEFAULT NULL,
	comments TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
	created_at TIMESTAMP NULL DEFAULT (CURRENT_TIMESTAMP),
	created_by VARCHAR(50) NOT NULL DEFAULT '-',
	updated_at TIMESTAMP NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
	updated_by VARCHAR(50) NULL DEFAULT '-',
	deleted_at TIMESTAMP NULL DEFAULT NULL,
	deleted_by VARCHAR(50) NULL DEFAULT '-',
	PRIMARY KEY (id) USING BTREE
	)
	COLLATE='utf8mb4_unicode_ci'
	ENGINE=InnoDB
	AUTO_INCREMENT=1
	;
-- Populate Shop Event	
	insert into whatsfresh.shop_event
	(account_id, vendor_id, shop_date, created_by)
	select distinct b.account_id, vendor_id, date_format(purchase_date,'%Y-%m-%d'), 2 
	from whatsfresh.ingredient_batches a
	join whatsfresh.ingredients b
	on   a.ingredient_id = b.id
	order by date_format(purchase_date,'%Y-%m-%d')
	;
-- update ingredient batches with the shop event ID.
	UPDATE whatsfresh.ingredient_batches ib
	JOIN whatsfresh.v_shop_event a 
	ON date_format(ib.purchase_date,'%Y-%m-%d') = a.shop_date
	and ib.vendor_id = a.vendor_id
	join whatsfresh.ingredients b
	on  a.account_id = b.account_id
	and ib.ingredient_id = b.id
	SET ib.shop_event_id = a.shop_event_id
	;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
