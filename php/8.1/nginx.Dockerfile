ARG PHP_VERSION
FROM php:${PHP_VERSION}-fpm

ARG NODE_VERSION
ARG COMPOSER_VERSION
ARG TIMEZONE
ARG GIT_USER_NAME
ARG GIT_USER_EMAIL

RUN apt-get update -yqq && \
    curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update -yqq && \
    apt-get install -yqq \
    curl git nano \
    nodejs \
    unzip zip \
    yarn \
    libpng-dev \
    sqlite3 \
    ghostscript

RUN curl -sSLf \
    -o /usr/local/bin/install-php-extensions \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions
RUN install-php-extensions gd
RUN install-php-extensions intl curl json
RUN install-php-extensions mysqli pdo_mysql

RUN install-php-extensions pdo_odbc
RUN install-php-extensions pdo_sqlsrv
RUN install-php-extensions pdo_dblib
RUN install-php-extensions odbc
RUN install-php-extensions sqlsrv

RUN install-php-extensions ldap
RUN install-php-extensions bz2
RUN install-php-extensions exif
RUN install-php-extensions gettext gmp gnupg imap memcache
RUN install-php-extensions oauth opcache opcache
RUN install-php-extensions pgsql redis
RUN install-php-extensions soap
RUN install-php-extensions xml
RUN install-php-extensions zip
RUN install-php-extensions bcmath
RUN install-php-extensions imagick
RUN install-php-extensions snappy && \
    apt-get update -yqq && apt-get install wkhtmltopdf -yqq

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN if [ ${COMPOSER_VERSION} > 0 && ${COMPOSER_VERSION} <= 2 ]; then \
    composer self-update --${COMPOSER_VERSION}; \
    fi

RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo ${TIMEZONE} > /etc/timezone \
    && printf '[PHP]\ndate.timezone = "%s"\n', ${TIMEZONE} > /usr/local/etc/php/conf.d/tzone.ini \
    && "date"

# Global Config for GIT
RUN git config --global init.defaultBranch main
RUN git config --global user.name "${GIT_USER_NAME}"
RUN git config --global user.email "${GIT_USER_EMAIL}"
RUN echo .DS_Store >> ~/.gitignore_global
RUN git config --global core.excludesfile ~/.gitignore_global

COPY conf.d/openssl.cnf /etc/ssl/openssl.cnf
ADD conf.d/custom.ini /usr/local/etc/php/conf.d/laravel.ini
RUN usermod -u 1000 www-data
RUN sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/g' /etc/ImageMagick-6/policy.xml

# Aliases
RUN echo 'alias art="php artisan"' >> ~/.bashrc

WORKDIR /var/www

EXPOSE 9000
CMD ["php-fpm"]
