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

-- Dumping structure for procedure wf_meta.convertIngrBtch
DELIMITER //
CREATE PROCEDURE `convertIngrBtch`()
BEGIN
-- drop the table
   drop table if exists whatsfresh.ingredient_batches
   ;
-- create ingredientBatches
	CREATE TABLE whatsfresh.ingredient_batches (
	id BIGINT(10) NOT NULL AUTO_INCREMENT COMMENT 'Non-Intelligent ID',
	ingredient_id INT(10) UNSIGNED NOT NULL,
	shop_event_id int(10) unsigned not null default 0,
	vendor_id INT(10) UNSIGNED NOT NULL,
	brand_id INT(10) UNSIGNED NULL DEFAULT NULL,
	lot_number VARCHAR(255) NOT NULL DEFAULT '',
	batch_number VARCHAR(50) NOT NULL DEFAULT '-',
	purchase_date DATE NOT NULL,
	purchase_quantity FLOAT NOT NULL DEFAULT '0',
	global_measure_unit_id INT(10) UNSIGNED NOT NULL DEFAULT '51',
	measure_id INT(10) UNSIGNED NULL,
	unit_quantity FLOAT NOT NULL DEFAULT '0',
	unit_price DECIMAL(13,4) NULL DEFAULT NULL,
	purchase_total_amount DECIMAL(13,2) NULL DEFAULT NULL,
	best_by_date DATE NULL DEFAULT NULL,
	comments TEXT NOT NULL,
	created_at TIMESTAMP NULL DEFAULT current_timestamp,
	created_by VARCHAR(50) NOT NULL DEFAULT '-',
	updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	updated_by VARCHAR(50) NULL DEFAULT '-',
	deleted_at TIMESTAMP NULL DEFAULT NULL,
	deleted_by VARCHAR(50) NULL DEFAULT '-',
	oldUUID BINARY(16) NULL COMMENT 'old UUID.',
	PRIMARY KEY (id) USING BTREE
	)
	COLLATE='utf8mb4_unicode_ci'
	ENGINE=InnoDB
	AUTO_INCREMENT=1
	;
-- recreate ingredient_batches with increment.
	insert into whatsfresh.ingredient_batches
	(oldUUID, ingredient_id, vendor_id, brand_id, lot_number
	,batch_number, purchase_date, purchase_quantity, global_measure_unit_id
	,unit_quantity, unit_price, purchase_total_amount, best_by_date
	,comments, created_at, created_by, updated_at, updated_by
	,deleted_at, deleted_by)
	select  id, b.ingredient_id, b.vendor_id, b.brand_id, b.lot_number
	, b.batch_number, b.purchase_date, b.purchase_quantity, b.global_measure_unit_id
	, b.unit_quantity, b.unit_price, b.purchase_total_amount, b.best_by_date
	, b.comments, b.created_at, b.created_by, b.updated_at, b.updated_by
	, b.deleted_at, b.deleted_by
	from wf_stage.ingredient_batches b
	where  year(b.created_at) + 7 >  year(now())
	ORDER BY created_at, batch_number
	; 
	alter table whatsfresh.ingredient_batches add active CHAR(1) AS (case when (deleted_at is null) then 'Y' else '' end) stored
	;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
