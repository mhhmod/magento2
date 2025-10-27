#!/usr/bin/env bash
set -e
cd /var/www/html

# Make Apache listen on Railway's random PORT if provided
if [ -n "$PORT" ] && [ "$PORT" != "80" ]; then
  sed -i "s/Listen 80/Listen $PORT/" /etc/apache2/ports.conf
  sed -i "s/*:80/*:$PORT/" /etc/apache2/sites-available/000-default.conf
fi

# First-time install
if [ ! -f app/etc/env.php ]; then
  echo ">> Running first-time Magento installation..."
  bin/magento setup:install \
    --base-url="${BASE_URL:-http://localhost/}" \
    --db-host="${DB_HOST:-127.0.0.1}" \
    --db-name="${DB_NAME:-magento}" \
    --db-user="${DB_USER:-root}" \
    --db-password="${DB_PASSWORD:-root}" \
    --backend-frontname="${ADMIN_PATH:-admin}" \
    --admin-firstname="${ADMIN_FIRSTNAME:-Store}" \
    --admin-lastname="${ADMIN_LASTNAME:-Owner}" \
    --admin-email="${ADMIN_EMAIL:-admin@example.com}" \
    --admin-user="${ADMIN_USER:-admin}" \
    --admin-password="${ADMIN_PASS:-Admin123!}" \
    --language="en_US" \
    --currency="USD" \
    --timezone="UTC" \
    --use-rewrites=1 \
    --search-engine="opensearch" || true

  # If OpenSearch is not present on free tier, fall back to MySQL search
  if ! bin/magento indexer:show-mode >/dev/null 2>&1 ; then
    echo ">> Falling back to MySQL search engine..."
    bin/magento config:set catalog/search/engine mysql || true
    bin/magento setup:upgrade || true
  fi

  bin/magento deploy:mode:set production || true
  bin/magento cache:flush || true
fi

exec "$@"
