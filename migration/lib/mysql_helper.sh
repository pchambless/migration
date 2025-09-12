#!/bin/bash
# MySQL connection helper functions

# Execute MySQL command on production server
mysql_prod() {
    local cmd="$1"
    mysql --defaults-group-suffix=-prod --protocol=TCP -e "$cmd" 2>/dev/null
}

# Execute MySQL command on test server  
mysql_test() {
    local cmd="$1"
    mysql --defaults-group-suffix=-test --protocol=TCP -e "$cmd" 2>/dev/null
}

# Execute MySQL command on test server with database specified
mysql_test_db() {
    local database="$1"
    local cmd="$2"
    mysql --protocol=TCP -h localhost -P "$TEST_PORT" -u "$TEST_USER" -p "$database" -e "$cmd" 2>/dev/null
}

# Get count from production table
mysql_prod_count() {
    local table="$1"
    mysql --protocol=TCP -h localhost -P "$PROD_PORT" -u "$PROD_USER" -p -sN -e "SELECT COUNT(*) FROM whatsfresh.$table" 2>/dev/null || echo "0"
}

# Get count from test table
mysql_test_count() {
    local table="$1"
    mysql --protocol=TCP -h localhost -P "$TEST_PORT" -u "$TEST_USER" -p -sN -e "SELECT COUNT(*) FROM whatsfresh.$table" 2>/dev/null || echo "0"
}

# Dump table from production
mysqldump_prod() {
    local table="$1"
    local output_file="$2"
    mysqldump --protocol=TCP -h localhost -P "$PROD_PORT" -u "$PROD_USER" -p \
        --single-transaction \
        --add-drop-table \
        whatsfresh "$table" > "$output_file" 2>/dev/null
}

# Import to test server
mysql_test_import() {
    local database="$1"
    local input_file="$2"
    mysql --protocol=TCP -h localhost -P "$TEST_PORT" -u "$TEST_USER" -p "$database" < "$input_file" 2>/dev/null
}