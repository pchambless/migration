#!/bin/bash
# migrate.sh

CONFIG="./config.json"
SOURCE_DB=$(jq -r '.source' "$CONFIG")
TARGET_DB=$(jq -r '.target' "$CONFIG")
TABLES=($(jq -r '.tables[]' "$CONFIG"))
PROCS=($(jq -r '.procedures[]' "$CONFIG"))

echo "🔁 Copying data from $SOURCE_DB to $TARGET_DB..."
mysqldump "$SOURCE_DB" | mysql "$TARGET_DB"

echo "🧹 Dropping tables in $TARGET_DB..."
for TABLE in "${TABLES[@]}"; do
  echo "  ⛔ Dropping $TABLE..."
  mysql "$TARGET_DB" -e "DROP TABLE IF EXISTS whatsfresh.$TABLE;"
done

echo "🔧 Running stored procedures..."
for PROC in "${PROCS[@]}"; do
  echo "  🛠️ Calling $PROC..."
  mysql "$TARGET_DB" -e "CALL wf_meta.$PROC();"
done

echo "✅ Migration complete."