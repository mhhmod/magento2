#!/usr/bin/env bash
set -e
cd /var/www/html

# Install once (idempotent)
if [ ! -f app/etc/env.php ]; then
  echo ">> First-time Magento install..."
  bin/magento setup:install \
    --base-url="${BASE_URL:-http://localhost/}" \
    --db-host="${DB_HOST:-127.0.0.1}" \
    --db-name="${DB_NAME:-magento}" \
    --db-user="${DB_USER:-root}" \
    --db-password="${DB_PASSWORD:-root}" \
    --backend-frontname="${ADMIN_PATH:-admin}" \
    --admin-firstname="${ADMIN_FIRSTNAME:-Store}" \
    --admin-lastname="${ADMIN_LASTNAME:-Owner}" \
    --
