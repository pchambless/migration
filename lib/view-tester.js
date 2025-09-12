/**
 * View testing utilities
 */

const getViews = async (conn, dbName) => {
  const [rows] = await conn.query(`
    SELECT TABLE_NAME
    FROM INFORMATION_SCHEMA.VIEWS
    WHERE TABLE_SCHEMA = ?
    ORDER BY TABLE_NAME
  `, [dbName]);
  return rows.map(row => row.TABLE_NAME);
};

const testView = async (conn, dbName, viewName) => {
  try {
    const startTime = Date.now();
    await conn.query(`SELECT COUNT(*) FROM \`${dbName}\`.\`${viewName}\` LIMIT 1`);
    const duration = Date.now() - startTime;
    return { success: true, duration };
  } catch (err) {
    return {
      success: false,
      error: err.message,
      sqlState: err.sqlState,
      errno: err.errno
    };
  }
};

module.exports = { getViews, testView };