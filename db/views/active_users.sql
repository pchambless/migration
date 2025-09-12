-- Example Database View: Active Users
-- File: active_users.sql

CREATE OR REPLACE VIEW active_users AS
SELECT 
    id,
    username,
    email,
    created_at,
    updated_at
FROM users
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY created_at DESC;