# Magento Dockerfile for Railway (small + PHP 8.2)
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libicu-dev libonig-dev libxml2-dev zip unzip git curl libxslt1-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd intl pdo pdo_mysql zip bcmath soap xsl

# Enable Apache Rewrite module
RUN a2enmod rewrite

# Copy Magento source
WORKDIR /var/www/html
COPY . /var/www/html

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
