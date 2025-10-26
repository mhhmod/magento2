# --- Build stage: create Mage-OS project (no Marketplace keys) ---
FROM composer:2 AS build
WORKDIR /app
# Give Composer enough memory
ENV COMPOSER_MEMORY_LIMIT=-1
RUN composer create-project --repository=https://repo.mage-os.org/ \
    mage-os/project-community-edition /app --no-dev --prefer-dist

# --- Runtime: PHP 8.2 + Apache + required extensions ---
FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    git curl unzip libzip-dev libpng-dev libjpeg-dev libfreetype6-dev \
    libicu-dev libxml2-dev libxslt1.1 libxslt1-dev libonig-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install gd intl pdo_mysql zip bcmath soap xsl \
 && a2enmod rewrite headers \
 && rm -rf /var/lib/apt/lists/*

# PHP tweaks
RUN { \
      echo "memory_limit=1024M"; \
      echo "max_execution_time=180"; \
      echo "opcache.enable=1"; \
      echo "opcache.memory_consumption=128"; \
    } > /usr/local/etc/php/conf.d/magento.ini

WORKDIR /var/www/html
# Copy the app that already includes composer.json/lock
COPY --from=build /app /var/www/html

# --- Ensure vendor/ exists even if build stage was cached/trimmed ---
# 1) bring composer into the runtime image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
# 2) install dependencies (no dev) – creates vendor/
RUN COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --prefer-dist --no-interaction

# Serve from /pub
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/pub|g' /etc/apache2/sites-available/000-default.conf \
 && sed -i 's|<Directory /var/www/>|<Directory /var/www/html/pub/>|g' /etc/apache2/apache2.conf

# Entry + permissions
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
 && chown -R www-data:www-data /var/www/html \
 && find var generated pub/static pub/media app/etc -type d -exec chmod 770 {} \; \
 && find var generated pub/static pub/media app/etc -type f -exec chmod 660 {} \;

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
