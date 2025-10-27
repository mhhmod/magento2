# -------- Stage 1: build Magento (Alpine; no apt-get here) --------
FROM composer:2 AS build
WORKDIR /app
ENV COMPOSER_MEMORY_LIMIT=-1
RUN apk add --no-cache git unzip
# Build project + vendor here; ignore platform reqs in build stage only
RUN composer create-project --repository=https://repo.mage-os.org/ \
  mage-os/project-community-edition /app \
  --no-dev --prefer-dist --ignore-platform-reqs

# -------- Stage 2: runtime (Debian PHP 8.2 + Apache + full PHP extensions) --------
FROM php:8.2-apache

# System libs + headers
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl unzip libzip-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
    libicu-dev libxml2-dev libxslt1-dev \
 && rm -rf /var/lib/apt/lists/*

# PHP extensions Magento/Mage-OS needs
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd intl pdo_mysql zip bcmath soap xsl sockets ftp mbstring \
 && a2enmod rewrite headers

# PHP tuning
RUN { \
  echo "memory_limit=1024M"; \
  echo "max_execution_time=180"; \
  echo "opcache.enable=1"; \
  echo "opcache.memory_consumption=128"; \
} > /usr/local/etc/php/conf.d/magento.ini

WORKDIR /var/www/html
# Copy app *including vendor/* from build stage (no composer install in runtime)
COPY --from=build /app /var/www/html

# Serve from /pub
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/pub|g' /etc/apache2/sites-available/000-default.conf \
 && sed -i 's|<Directory /var/www/>|<Directory /var/www/html/pub/>|g' /etc/apache2/apache2.conf

# Entrypoint + permissions
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
 && chown -R www-data:www-data /var/www/html \
 && find var generated pub/static pub/media app/etc -type d -exec chmod 770 {} \; \
 && find var generated pub/static pub/media app/etc -type f -exec chmod 660 {} \;

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
