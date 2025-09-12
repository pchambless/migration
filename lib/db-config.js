/**
 * Database configuration utilities
 * Uses existing .my.cnf configuration
 */

const getDbConfig = (database) => {
  return {
    host: 'localhost',
    port: 13307,
    database: database,
    // Credentials come from ~/.my.cnf [client-test] section
    connectTimeout: 10000,
    acquireTimeout: 10000,
    timeout: 10000
  };
};

module.exports = { getDbConfig };