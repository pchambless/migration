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

-- Dumping structure for procedure wf_meta.convertProdIngr_Map
DELIMITER //
CREATE PROCEDURE `convertProdIngr_Map`()
BEGIN
-- drop the table if it exists
	drop table if exists whatsfresh.product_batch_ingredients
	;
	CREATE TABLE whatsfresh.product_batch_ingredients (
	id BIGINT(10) NOT NULL AUTO_INCREMENT COMMENT 'Non-Intelligent ID',
	product_batch_id BIGINT NOT NULL,
	product_recipe_id BIGINT NOT NULL,
	ingredient_batch_id BIGINT NULL DEFAULT NULL,
	comments varchar(1000) NOT NULL default '',
	ingredient_quantity DECIMAL(10,3) NOT NULL DEFAULT '0.000',
	global_measure_unit_id INT(10) UNSIGNED NOT NULL DEFAULT '51',
	measure_id INT(10) UNSIGNED NULL,
	created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
	created_by VARCHAR(50) NOT NULL DEFAULT '-',
	updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	updated_by VARCHAR(50) NULL DEFAULT '-',
	deleted_at TIMESTAMP NULL DEFAULT NULL,
	deleted_by VARCHAR(50) NULL DEFAULT '-',
	oldUUID BINARY(16) NULL COMMENT 'oldUUID',
	PRIMARY KEY (id) USING BTREE
	)
	COLLATE='utf8mb4_unicode_ci'
	ENGINE=InnoDB
;
-- Populate the table
	insert into whatsfresh.product_batch_ingredients
	(oldUUID, product_batch_id, ingredient_batch_id, product_recipe_id
	, comments, ingredient_quantity, global_measure_unit_id, created_at, created_by, updated_at, updated_by
	, deleted_at, deleted_by)
	select  a.id oldUUID, b.id product_batch_id, c.ID ingredient_batch_id, d.id product_recipe_id
	, a.comments, a.ingredient_quantity, a.global_measure_unit_id, a.created_at, a.created_by, a.updated_at, a.updated_by
	, a.deleted_at, a.deleted_by
	from wf_stage.product_batch_ingredients a
	join whatsfresh.product_batches b
	on   a.product_batch_id = b.oldUUID
	join whatsfresh.product_recipes d
	on   a.product_recipe_id = d.oldUUID
	left join whatsfresh.ingredient_batches c
	on   a.ingredient_batch_id = c.oldUUID
	where  year(a.created_at) + 7 >  year(now())
	ORDER BY a.created_at
	;
	alter table whatsfresh.product_batch_ingredients add active CHAR(1) AS (case when (deleted_at is null) then 'Y' else '' end) stored
	;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
