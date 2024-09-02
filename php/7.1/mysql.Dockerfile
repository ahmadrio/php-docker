FROM dockette/php:7.1-fpm

ARG TIMEZONE=Asia/Jakarta
ARG NODE_VERSION=16
ARG COMPOSER_VERSION=1

RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

RUN apt update && apt dist-upgrade -y \
    && apt install -y wkhtmltopdf libpng-dev \
# NodeJS installation
    && apt install -y ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt install -y nodejs npm \
    && npm install -g yarn \
# PHP extensions
    && apt install -y \
        php7.1-dev \
        php7.1-sybase \
# PHP Snappy
    && git clone --recursive --depth=1 https://github.com/kjdev/php-ext-snappy.git \
    && cd php-ext-snappy \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -rf php-ext-snappy \
# Set composer version
    && composer self-update --${COMPOSER_VERSION} \
# Clean up
    && apt-get clean -y \
    && apt-get autoclean -y \
    && apt-get remove -y wget curl lsb-release \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/*

# FILES (it overrides originals)
ADD ./conf.d/custom.ini ${PHP_MODS_DIR}/custom.ini
RUN ln -s ${PHP_MODS_DIR}/custom.ini ${PHP_CLI_CONF_DIR}/991-custom.ini && \
    ln -s ${PHP_MODS_DIR}/custom.ini ${PHP_CGI_CONF_DIR}/991-custom.ini && \
    ln -s ${PHP_MODS_DIR}/custom.ini ${PHP_FPM_CONF_DIR}/991-custom.ini

# Global Config for GIT
ARG GIT_USER_NAME
ARG GIT_USER_EMAIL
RUN git config --global init.defaultBranch main
RUN git config --global user.name "${GIT_USER_NAME}"
RUN git config --global user.email "${GIT_USER_EMAIL}"
RUN echo .DS_Store >> ~/.gitignore_global
RUN git config --global core.excludesfile ~/.gitignore_global

COPY ./conf.d/openssl.cnf /etc/ssl/openssl.cnf

# Aliases
RUN echo 'alias art="php artisan"' >> ~/.bashrc \
    && echo 'alias serve="php artisan serve --host=0.0.0.0 --port=80"' >> ~/.bashrc
