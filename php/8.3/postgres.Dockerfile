FROM dockette/debian:bullseye

# PHP
ENV PHP_MODS_DIR=/etc/php/8.3/mods-available
ENV PHP_CLI_DIR=/etc/php/8.3/cli
ENV PHP_CLI_CONF_DIR=${PHP_CLI_DIR}/conf.d
ENV PHP_CGI_DIR=/etc/php/8.3/cgi
ENV PHP_CGI_CONF_DIR=${PHP_CGI_DIR}/conf.d
ENV PHP_FPM_DIR=/etc/php/8.3/fpm
ENV PHP_FPM_CONF_DIR=${PHP_FPM_DIR}/conf.d
ENV PHP_FPM_POOL_DIR=${PHP_FPM_DIR}/pool.d
ENV TZ=Asia/Jakarta

# INSTALLATION
RUN apt update && apt dist-upgrade -y && \
    # DEPENDENCIES #############################################################
    apt install -y wget curl apt-transport-https ca-certificates lsb-release git unzip && \
    # PHP DEB.SURY.CZ ##########################################################
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list && \
    apt update && \
    apt dist-upgrade -y && \
    apt install -y --no-install-recommends \
        # not available in bullseye: php8.3-apc \
        php8.3-apcu \
        php8.3-bz2 \
        php8.3-bcmath \
        php8.3-calendar \
        php8.3-cli \
        php8.3-cgi \
        php8.3-ctype \
        php8.3-curl \
        php8.3-fpm \
        php8.3-gettext \
        php8.3-gd \
        php8.3-intl \
        php8.3-imap \
        php8.3-ldap \
        php8.3-mbstring \
        php8.3-memcached \
        # not available in bullseye: php8.3-mongo \
        php8.3-mysql \
        php8.3-pdo \
        php8.3-pgsql \
        php8.3-redis \
        php8.3-soap \
        php8.3-sqlite3 \
        php8.3-zip \
        php8.3-xmlrpc \
        php8.3-xsl && \
    # COMPOSER #################################################################
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --2 && \
    # PHP MOD(s) ###############################################################
    ln -s ${PHP_MODS_DIR}/custom.ini ${PHP_CLI_CONF_DIR}/999-custom.ini && \
    ln -s ${PHP_MODS_DIR}/custom.ini ${PHP_CGI_CONF_DIR}/999-custom.ini && \
    ln -s ${PHP_MODS_DIR}/custom.ini ${PHP_FPM_CONF_DIR}/999-custom.ini && \
    # CLEAN UP #################################################################
    rm ${PHP_FPM_POOL_DIR}/www.conf && \
    apt-get clean -y && \
    apt-get autoclean -y && \
    apt-get remove -y wget curl lsb-release && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/*

# FILES (it overrides originals)
ADD conf.d/custom.ini ${PHP_MODS_DIR}/custom.ini
ADD fpm/php-fpm.conf ${PHP_FPM_DIR}/php-fpm.conf

# START CUSTOMIZE
ARG TIMEZONE=Asia/Jakarta
ARG NODE_VERSION=18
ARG COMPOSER_VERSION=2

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
    && apt update && apt dist-upgrade -y && apt install -y \
        php8.3-dev \
        php8.3-sybase \
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
    && apt-get remove -y curl \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/*

# Global Config for GIT
ARG GIT_USER_NAME
ARG GIT_USER_EMAIL
RUN git config --global init.defaultBranch main
RUN git config --global user.name "${GIT_USER_NAME}"
RUN git config --global user.email "${GIT_USER_EMAIL}"
RUN echo .DS_Store >> ~/.gitignore_global
RUN git config --global core.excludesfile ~/.gitignore_global

# FILES (it overrides originals)
ADD ./conf.d/custom.ini ${PHP_MODS_DIR}/custom.ini
RUN ln -s ${PHP_MODS_DIR}/custom.ini ${PHP_CLI_CONF_DIR}/991-custom.ini && \
    ln -s ${PHP_MODS_DIR}/custom.ini ${PHP_CGI_CONF_DIR}/991-custom.ini && \
    ln -s ${PHP_MODS_DIR}/custom.ini ${PHP_FPM_CONF_DIR}/991-custom.ini

COPY ./conf.d/openssl.cnf /etc/ssl/openssl.cnf

# Aliases
RUN echo 'alias art="php artisan"' >> ~/.bashrc \
    && echo 'alias serve="php artisan serve --host=0.0.0.0 --port=80"' >> ~/.bashrc
# END CUSTOMIZE

CMD ["php-fpm8.3"]
