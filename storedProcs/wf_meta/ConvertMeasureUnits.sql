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

-- Dumping structure for procedure wf_meta.ConvertMeasureUnits
DELIMITER //
CREATE PROCEDURE `ConvertMeasureUnits`()
BEGIN
    -- Step 1: Drop and recreate the measures table
    DROP TABLE IF EXISTS whatsfresh.measures;
    CREATE TABLE whatsfresh.measures (
        id INT UNSIGNED NOT NULL AUTO_INCREMENT,
        account_id INT UNSIGNED NOT NULL,
        name VARCHAR(30) NOT NULL COLLATE 'utf8mb4_unicode_ci',
        abbrev VARCHAR(250) NOT NULL COLLATE 'utf8mb4_unicode_ci',
        oldID INT UNSIGNED NOT NULL DEFAULT '0',
        created_at TIMESTAMP NULL DEFAULT NULL,
        created_by varchar(50) NULL DEFAULT NULL,
        updated_at TIMESTAMP NULL DEFAULT NULL,
        updated_by varchar(50) NULL DEFAULT NULL,
        deleted_at TIMESTAMP NULL DEFAULT NULL,
        deleted_by varchar(50) NULL DEFAULT NULL,
        PRIMARY KEY (id) USING BTREE,
        INDEX acctIDX (account_id) USING BTREE,
        CONSTRAINT FK_measures_accounts FOREIGN KEY (account_id) 
            REFERENCES whatsfresh.accounts (id) ON UPDATE NO ACTION ON DELETE CASCADE
    )
    COLLATE='utf8mb4_unicode_ci'
    ENGINE=InnoDB;
    
    -- Step 2: Create account_settings table if it doesn't exist
    CREATE TABLE IF NOT EXISTS whatsfresh.account_settings (
        account_id INT UNSIGNED NOT NULL,
        default_measure_id INT UNSIGNED NULL,
        created_at TIMESTAMP NULL DEFAULT NULL,
        updated_at TIMESTAMP NULL DEFAULT NULL,
		  deleted_at TIMESTAMP NULL DEFAULT NULL,
        PRIMARY KEY (account_id),
        CONSTRAINT fk_account_settings_account 
            FOREIGN KEY (account_id) REFERENCES whatsfresh.accounts(id) ON DELETE CASCADE
    );
    
    -- Clear any existing default_measure_id values
    UPDATE whatsfresh.account_settings SET default_measure_id = NULL;
    
    DROP TEMPORARY TABLE IF EXISTS temp_account_measures;
    
    -- Step 3: Collect account-specific measure units by analyzing references
    CREATE TEMPORARY TABLE temp_account_measures (
        account_id INT UNSIGNED NOT NULL,
        global_measure_unit_id INT UNSIGNED NOT NULL,
        PRIMARY KEY (account_id, global_measure_unit_id)
    );
    
    -- Insert from products
    INSERT IGNORE INTO temp_account_measures (account_id, global_measure_unit_id)
    SELECT p.account_id, p.global_measure_unit_id
    FROM wf_stage.products p
    WHERE p.global_measure_unit_id IS NOT NULL;
    
    -- Insert from product_batches
    INSERT IGNORE INTO temp_account_measures (account_id, global_measure_unit_id)
    SELECT p.account_id, pb.global_measure_unit_id
    FROM wf_stage.product_batches pb
    JOIN wf_stage.products p ON pb.product_id = p.id
    WHERE pb.global_measure_unit_id IS NOT NULL;
    
    -- Insert from product_recipes
    INSERT IGNORE INTO temp_account_measures (account_id, global_measure_unit_id)
    SELECT p.account_id, pr.global_measure_unit_id
    FROM wf_stage.product_recipes pr
    JOIN wf_stage.products p ON pr.product_id = p.id
    WHERE pr.global_measure_unit_id IS NOT NULL;
    
    -- Insert from product_batch_ingredients
    INSERT IGNORE INTO temp_account_measures (account_id, global_measure_unit_id)
    SELECT p.account_id, pbi.global_measure_unit_id
    FROM wf_stage.product_batch_ingredients pbi
    JOIN wf_stage.product_batches pb ON pbi.product_batch_id = pb.id
    JOIN wf_stage.products p ON pb.product_id = p.id
    WHERE pbi.global_measure_unit_id IS NOT NULL;
    
    -- Insert from ingredient_batches
    INSERT IGNORE INTO temp_account_measures (account_id, global_measure_unit_id)
    SELECT i.account_id, ib.global_measure_unit_id
    FROM wf_stage.ingredient_batches ib
    JOIN wf_stage.ingredients i ON ib.ingredient_id = i.id
    WHERE ib.global_measure_unit_id IS NOT NULL;
    
    -- IMPORTANT: Ensure every account has the default "Undetermined" unit
    INSERT IGNORE INTO temp_account_measures (account_id, global_measure_unit_id)
    SELECT a.id, 51  -- ID 51 is the "-" "Undetermined" unit
    FROM wf_stage.accounts a;
    
    -- Step 4: Insert account-specific measures ONLY for combinations that exist
    INSERT INTO whatsfresh.measures 
        (account_id, name, abbrev, oldID, created_at)
    SELECT 
        tam.account_id,
        gmu.value AS name,
        gmu.hover_text AS abbrev,
        gmu.id AS oldID,
        NOW() AS created_at
    FROM 
        temp_account_measures tam
    JOIN 
        wf_stage.global_measure_units gmu ON tam.global_measure_unit_id = gmu.id
    WHERE 
        gmu.deleted_at IS NULL;
    
    -- Step 5: Record each account's default measure unit in account_settings
    INSERT INTO whatsfresh.account_settings (account_id, default_measure_id, created_at)
    SELECT m.account_id, m.id, NOW()
    FROM whatsfresh.measures m
    WHERE m.oldID = 51  -- ID 51 is the "-" "Undetermined" unit
    ON DUPLICATE KEY UPDATE default_measure_id = m.id, updated_at = NOW();
    
    -- Step 6: Update ONLY the measure_id column in all tables
    
    -- 1. Update ingredient_batches (ONLY measure_id)
    UPDATE whatsfresh.ingredient_batches ib
    JOIN whatsfresh.ingredients i ON ib.ingredient_id = i.id
    JOIN whatsfresh.measures m ON ib.global_measure_unit_id = m.oldID AND m.account_id = i.account_id
    SET 
        ib.measure_id = m.id
    WHERE ib.global_measure_unit_id IS NOT NULL;
    
    -- 2. Update product_batch_ingredients (ONLY measure_id)
    UPDATE whatsfresh.product_batch_ingredients pbi
    JOIN whatsfresh.product_batches pb ON pbi.product_batch_id = pb.id
    JOIN whatsfresh.products p ON pb.product_id = p.id
    JOIN whatsfresh.measures m ON pbi.global_measure_unit_id = m.oldID AND m.account_id = p.account_id
    SET 
        pbi.measure_id = m.id
    WHERE pbi.global_measure_unit_id IS NOT NULL;
    
    -- 3. Update product_batches (ONLY measure_id)
    UPDATE whatsfresh.product_batches pb
    JOIN whatsfresh.products p ON pb.product_id = p.id
    JOIN whatsfresh.measures m ON pb.global_measure_unit_id = m.oldID AND m.account_id = p.account_id
    SET 
        pb.measure_id = m.id
    WHERE pb.global_measure_unit_id IS NOT NULL;
    
    -- 4. Update product_recipes (ONLY measure_id)
    UPDATE whatsfresh.product_recipes pr
    JOIN whatsfresh.products p ON pr.product_id = p.id
    JOIN whatsfresh.measures m ON pr.global_measure_unit_id = m.oldID AND m.account_id = p.account_id
    SET 
        pr.measure_id = m.id
    WHERE pr.global_measure_unit_id IS NOT NULL;
    
    -- 5. Update products (ONLY measure_id)
    UPDATE whatsfresh.products p
    JOIN whatsfresh.measures m ON p.global_measure_unit_id = m.oldID AND m.account_id = p.account_id
    SET 
        p.measure_id = m.id
    WHERE p.global_measure_unit_id IS NOT NULL;
    
    -- Drop temporary table
    DROP TEMPORARY TABLE temp_account_measures;
END//
DELIMITER ;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
