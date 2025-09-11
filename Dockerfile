# Inherit from the upsteam farmOS 3.x image.
# Upgrade here for new farmos version
FROM farmos/farmos:3.4.5

# Install `jq` to help in extracting the farmOS version below.
RUN apt-get update && apt-get install -y jq

# Create a fresh /var/farmOS directory.
RUN rm -r /var/farmOS && mkdir /var/farmOS

# Copy composer.json and composer.lock into the image.
COPY project/composer.json /var/farmOS/composer.json
COPY project/composer.lock /var/farmOS/composer.lock
# Add permission fix script to the image.
COPY project/drupal_fix_permissions.sh /var/farmOS/web/drupal_fix_permissions.sh
RUN chmod +x /var/farmOS/web/drupal_fix_permissions.sh

# Build the farmOS codebase with Composer as the www-data user in /var/farmOS
# with the --no-dev flag.
RUN (cd /var/farmOS; composer install --no-dev)

# Set the version in farm.info.yml to match the version locked by Composer.
# This is optional but is useful because the version will appear as the
# "Installation Profile" version at `/admin/reports/status` in farmOS.
RUN sed -i "s|version: 3.4.5|version: $(jq -r '.packages[] | select(.name == "farmos/farmos").version' /var/farmOS/composer.lock)|g" /var/farmOS/web/profiles/farm/farm.info.yml

# Copy the farmOS codebase into /opt/drupal.
RUN rm -r /opt/drupal && cp -rp /var/farmOS /opt/drupal

# Choose the production php.ini
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
