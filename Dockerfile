ARG BUILD_IMAGE=usgs/hazdev-base-images:latest-node
ARG FROM_IMAGE=usgs/hazdev-base-images:latest-php


FROM ${BUILD_IMAGE} as buildenv


# php required for pre-install
RUN yum install -y \
    php

COPY . /hazdev-geoserve-ws
WORKDIR /hazdev-geoserve-ws

# Creates /hazdev-geoserve-ws/.theme folder
RUN /bin/bash --login -c "\
    npm install -g grunt-cli && \
    npm run clean && \
    npm install --no-save hazdev-template \
    "



FROM ${FROM_IMAGE}


COPY --from=buildenv \
    /hazdev-geoserve-ws/node_modules/hazdev-template/dist/ \
    /var/www/apps/hazdev-template/

COPY --from=buildenv \
    /hazdev-geoserve-ws/src/ \
    /var/www/apps/hazdev-geoserve-ws/

COPY --from=buildenv \
    /hazdev-geoserve-ws/src/lib/docker_template_config.php \
    /var/www/html/_config.inc.php

COPY --from=buildenv \
    /hazdev-geoserve-ws/src/lib/docker_template_httpd.conf \
    /etc/httpd/conf.d/hazdev-template.conf

# Configure the application and install it.
# A full config.ini is generated, however only the MOUNT_PATH is used as this
# time. MOUNT_PATH sets up the alias in httpd.conf. All other configuration
# parameters should be read from the environment at container runtime.
RUN /bin/bash --login -c "\
    php /var/www/apps/hazdev-geoserve-ws/lib/pre-install.php --non-interactive --skip-db && \
    ln -s /var/www/apps/hazdev-geoserve-ws/conf/httpd.conf /etc/httpd/conf.d/hazdev-geoserve-ws.conf \
    "

# this is set in usgs/hazdev-base-images:latest-php, and repeated here for clarity
# EXPOSE 80
