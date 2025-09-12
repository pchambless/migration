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

-- Dumping structure for procedure wf_meta.convertProdBtch
DELIMITER //
CREATE PROCEDURE `convertProdBtch`()
BEGIN
-- drop the table
   drop table if exists whatsfresh.product_batches
   ;
-- create product_batches
	CREATE TABLE whatsfresh.product_batches (
	id BIGINT(10) NOT NULL AUTO_INCREMENT COMMENT 'Non-Intelligent ID',
	product_id INT(10) UNSIGNED NOT NULL,
	batch_start TIMESTAMP NULL DEFAULT NULL,
	batch_number VARCHAR(50) NOT NULL DEFAULT '-',
	location VARCHAR(255) NOT NULL,
	batch_quantity DOUBLE NULL DEFAULT NULL,
	global_measure_unit_id INT(10) UNSIGNED NOT NULL DEFAULT '51',
	measure_id INT(10) UNSIGNED NULL,
	best_by_date DATE NULL DEFAULT NULL,
	comments TEXT NOT NULL,
	recipe_multiply_factor DOUBLE NULL DEFAULT NULL,
	created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	created_by VARCHAR(50) NOT NULL DEFAULT '-',
	updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	updated_by VARCHAR(50) NULL DEFAULT '-',
	deleted_at TIMESTAMP NULL DEFAULT NULL,
	deleted_by VARCHAR(50) NULL DEFAULT '-',
	oldUUID BINARY(16) NULL COMMENT 'Non-Intelligent binary UUID.',
	PRIMARY KEY (id) USING BTREE
	)
	COLLATE='utf8mb4_unicode_ci'
	ENGINE=InnoDB
	;
-- populate product_batches
	insert into whatsfresh.product_batches
	(oldUUID, product_id, batch_start, batch_number
	, location, batch_quantity, global_measure_unit_id, best_by_date
	, comments, recipe_multiply_factor, created_at, created_by
	, updated_by, updated_at, deleted_by, deleted_at)
	select  id, product_id, batch_start, batch_number
	, location, batch_quantity, global_measure_unit_id, best_by_date
	, comments, recipe_multiply_factor, created_at, created_by
	, updated_by, updated_at, deleted_by, deleted_at
	from wf_stage.product_batches 
	where  year(created_at) + 7 >  year(now())
	ORDER BY created_at, batch_number
	;
	alter table whatsfresh.product_batches add active CHAR(1) AS (case when (deleted_at is null) then 'Y' else '' end) stored
	;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
