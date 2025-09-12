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

-- Dumping structure for procedure wf_meta.convertRcpeBtch
DELIMITER //
CREATE PROCEDURE `convertRcpeBtch`()
BEGIN
-- drop the table
   drop table if exists whatsfresh.product_recipes
   ;
-- create product_recipes
	CREATE TABLE whatsfresh.product_recipes (
	   id BIGINT(10) NOT NULL AUTO_INCREMENT COMMENT 'Non-Intelligent ID', 
		product_id INT(10) UNSIGNED NOT NULL,
		ingredient_id INT(10) UNSIGNED NOT NULL,
		global_measure_unit_id INT(10) UNSIGNED NULL DEFAULT 51,
		measure_id INT(10) UNSIGNED NULL,
		ingredient_order INT(10) NOT NULL DEFAULT '0',
		quantity DOUBLE NOT NULL DEFAULT '0',
		comments varchar(1000) not NULL default '' COLLATE 'utf8mb4_unicode_ci',
		created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		created_by VARCHAR(50) NULL DEFAULT '-',
		updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		updated_by VARCHAR(50) NULL DEFAULT '-',
		deleted_at TIMESTAMP NULL DEFAULT NULL,
		deleted_by VARCHAR(50) NULL DEFAULT '-',
		oldUUID BINARY(16) NULL COMMENT 'old UUID',
		PRIMARY KEY (id) USING BTREE
	)
	COLLATE='utf8mb4_unicode_ci'
	ENGINE=InnoDB
	;
-- populate product_recipes
	insert into whatsfresh.product_recipes
	(	oldUUID, product_id, ingredient_id, global_measure_unit_id
	, ingredient_order, quantity, comments, created_at, created_by
	, updated_at, updated_by, deleted_at, deleted_by)
	select  a.id oldUUID, a.product_id, a.ingredient_id, a.global_measure_unit_id
	, a.ingredient_order, a.quantity, ifnull(a.comments,''), a.created_at, a.created_by
	, a.updated_at, a.updated_by, a.deleted_at, a.deleted_by
	from wf_stage.product_recipes a
	ORDER BY created_at
	;
	alter table whatsfresh.product_recipes add active CHAR(1) AS (case when (deleted_at is null) then 'Y' else '' end) stored
	;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
