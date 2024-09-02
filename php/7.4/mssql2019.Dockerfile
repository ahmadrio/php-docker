FROM dockette/debian:bullseye

# PHP
ENV PHP_MODS_DIR=/etc/php/7.4/mods-available
ENV PHP_CLI_DIR=/etc/php/7.4/cli
ENV PHP_CLI_CONF_DIR=${PHP_CLI_DIR}/conf.d
ENV PHP_CGI_DIR=/etc/php/7.4/cgi
ENV PHP_CGI_CONF_DIR=${PHP_CGI_DIR}/conf.d
ENV PHP_FPM_DIR=/etc/php/7.4/fpm
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
        # not available in bullseye: php7.4-apc \
        php7.4-apcu \
        php7.4-bz2 \
        php7.4-bcmath \
        php7.4-calendar \
        php7.4-cli \
        php7.4-cgi \
        php7.4-ctype \
        php7.4-curl \
        php7.4-fpm \
        php7.4-gettext \
        php7.4-gd \
        php7.4-intl \
        php7.4-imap \
        php7.4-ldap \
        php7.4-mbstring \
        php7.4-memcached \
        # not available in bullseye: php7.4-mongo \
        php7.4-mysql \
        php7.4-pdo \
        php7.4-pgsql \
        php7.4-redis \
        php7.4-soap \
        php7.4-sqlite3 \
        php7.4-zip \
        php7.4-xmlrpc \
        php7.4-xsl && \
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
ARG NODE_VERSION=16
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
    && apt install -y \
        php7.4-dev \
        php7.4-sybase \
# SQL Server 2019 Extensions
    && curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc \
    && curl https://packages.microsoft.com/config/debian/11/prod.list | tee /etc/apt/sources.list.d/mssql-release.list \
    && apt update && ACCEPT_EULA=Y apt install -y unixodbc-dev msodbcsql18 mssql-tools \
    && pecl install -f sqlsrv \
    && pecl install -f pdo_sqlsrv \
    && printf "; priority=20\nextension=sqlsrv.so\n" > ${PHP_MODS_DIR}/sqlsrv.ini \
    && printf "; priority=30\nextension=pdo_sqlsrv.so\n" > ${PHP_MODS_DIR}/pdo_sqlsrv.ini \
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
    ln -s ${PHP_MODS_DIR}/custom.ini ${PHP_FPM_CONF_DIR}/991-custom.ini && \
    ln -s ${PHP_MODS_DIR}/sqlsrv.ini ${PHP_CLI_CONF_DIR}/20-sqlsrv.ini && \
    ln -s ${PHP_MODS_DIR}/sqlsrv.ini ${PHP_CGI_CONF_DIR}/20-sqlsrv.ini && \
    ln -s ${PHP_MODS_DIR}/sqlsrv.ini ${PHP_FPM_CONF_DIR}/20-sqlsrv.ini && \
    ln -s ${PHP_MODS_DIR}/pdo_sqlsrv.ini ${PHP_CLI_CONF_DIR}/30-pdo_sqlsrv.ini && \
    ln -s ${PHP_MODS_DIR}/pdo_sqlsrv.ini ${PHP_CGI_CONF_DIR}/30-pdo_sqlsrv.ini && \
    ln -s ${PHP_MODS_DIR}/pdo_sqlsrv.ini ${PHP_FPM_CONF_DIR}/30-pdo_sqlsrv.ini

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

CMD ["php-fpm7.4"]
