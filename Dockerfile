# Inherit from the upsteam farmOS 3.x image.
# Upgrade here for new farmos version
FROM farmos/farmos:4.0.0

# Switch to root for package installation and filesystem ops.
USER root

# Install system packages, PHP 8.4 and build deps for PECL extensions.
# Add sury.org PHP repo if necessary to get PHP 8.4 packages.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		apt-transport-https \
		lsb-release \
		gnupg \
		wget \
		build-essential \
		pkg-config \
		autoconf \
		automake \
		libtool \
		unzip \
		zip \
		git \
		libgeos-dev \
		libgeos++-dev \
		jq \
	&& wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add - \
	&& echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		php8.4-cli \
		php8.4-common \
		php8.4-dev \
		php8.4-xml \
		php8.4-mbstring \
		php8.4-zip \
		php8.4-pgsql \
		php8.4-gd \
		php8.4-intl \
		php8.4-curl \
	&& pecl channel-update pecl.php.net || true \
	&& printf "\n" | pecl install geos || true \
	&& { echo "extension=geos.so" > /etc/php/8.4/mods-available/geos.ini; phpenmod -v 8.4 geos || true; } \
	&& rm -rf /var/lib/apt/lists/*

# Ensure composer is available globally.
RUN php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" \
	&& php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
	&& rm /tmp/composer-setup.php

# Remove any existing /var/farmOS (files may be owned by root in base image)
# and create a fresh directory owned by www-data.
RUN rm -rf /var/farmOS && mkdir -p /var/farmOS && chown -R www-data:www-data /var/farmOS

# Copy composer.json and permission script into the image.
COPY project/composer.json /var/farmOS/composer.json
COPY project/drupal_fix_permissions.sh /var/farmOS/web/drupal_fix_permissions.sh
RUN chmod +x /var/farmOS/web/drupal_fix_permissions.sh && chown www-data:www-data /var/farmOS/web/drupal_fix_permissions.sh

# Ensure ownership and permissions so `www-data` can write into /var/farmOS
RUN chown -R www-data:www-data /var/farmOS && chmod -R ug+rwX,o+rX /var/farmOS

# Install PHP dependencies inside the image as www-data.
USER www-data
RUN cd /var/farmOS && composer install --no-dev --prefer-dist --no-interaction

# Set the version in farm.info.yml to match the version locked by Composer.
USER root
RUN sed -i "s|version: 4.0.0|version: $(jq -r '.packages[] | select(.name == "farmos/farmos").version' /var/farmOS/composer.lock)|g" /var/farmOS/web/profiles/farm/farm.info.yml || true

# Copy the farmOS codebase into /opt/drupal.
RUN rm -rf /opt/drupal && cp -rp /var/farmOS /opt/drupal && chown -R www-data:www-data /opt/drupal

# Choose the production php.ini
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" || true
USER www-data
