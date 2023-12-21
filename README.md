# Docker PHP

Workspace docker ini bertujuan untuk mempermudah teman-teman untuk develop projek yang dimana projek tersebut memiliki versi package yang harus sesuai dengan production. Semoga ini bermanfaat buat teman-teman.

## Preferensi:

- Docker (rekomendasi versi 4.18.0)
- PHP (7.1, 7.2, 7.3, 7.4, 8.1)
- Composer
- NodeJS
- MySQL
- SQL Server

## Struktur Folder

```
|--- Sites/
|    |--- projek-1-php71/
|    |    |--- app/
|    |    |--- bootstrap/
|    |    |--- config/
|    |    |--- ...
|    |--- projek-2-php73/
|    |    |--- app/
|    |    |--- bootstrap/
|    |    |--- config/
|    |    |--- ...
|    |--- php-docker/
|    |    |--- php/
|    |    |--- docker-compose.yml
|    |    |--- ...
```

## Caranya:

- Buat folder baru. contoh: `$ mkdir Sites`
- Masuk ke folder yang sudah dibuat. `$ cd Sites/`
- Clone repository didalam folder tersebut. `$ git clone [url]`
- Setelah clone, masuk ke folder yang sudah di clone. `$ cd php-docker/`
- Copy file `.env.example` kemudian ubah menjadi `.env` dan ubah pengaturan sesuai yang di inginkan
- Copy file `docker-compose.yml.example` kemudian ubah menjadi `docker-compose.yml` dan ubah pengaturan sesuai yang di inginkan
- Jika semua sudah siap, maka jalankan build docker dengan cara: `$ docker-compose build`
- Jika sudah berhasil build, maka di jalankan containernya dengan cara: `$ docker-compose up -d php`

## Contoh menjalankan projek
- Masuk ke dalam container: `$ docker-compose exec php bash`
- Kemudian jalankan install laravel: `/var/www/: composer create-project laravel/laravel new-project`
- Jika sudah berhasil, masuk ke dalam folder projek, kemudian jalankan aplikasinya:
```bash
$ /var/www/: cd new-project
$ /var/www/new-project/: serve
```
- Buka browser dengan url: `http://localhost`
- Done!

## Package docker compose yang dapat digunakan:

- MySQL

```yaml
services:
    mysql:
        image: "mysql:${MYSQL_VERSION}"
        environment:
            - MYSQL_ROOT_PASSWORD=${MYSQL_PASSWORD}
            - TZ=${TIMEZONE}
        volumes:
            - database-mysql:/var/lib/mysql
        ports:
            - ${MYSQL_PORT:-3306}:3306
        networks:
            - pace

volumes:
    database-mysql:
        driver: local
```

- PHPMyAdmin

```yaml
services:
    phpmyadmin:
        image: "phpmyadmin/phpmyadmin:${PHPMYADMIN_VERSION}"
        restart: always
        environment:
            PMA_HOST: mysql
            PMA_USER: root
            PMA_PASSWORD: ${MYSQL_PASSWORD}
            UPLOAD_LIMIT: 300M
        ports:
            - ${PHPMYADMIN_PORT:-8080}:8080
        networks:
            - pace
```

- Adminer (SQL Server Client)

```yaml
adminer:
    image: adminer
    restart: always
    environment:
        ADMINER_PLUGINS: 'tables-filter'
    ports:
        - ${ADMINER_PORT:-8081}:8080
    networks:
        - pace
```

- Ngrok

```yaml
ngrok:
    image: wernight/ngrok:latest
    depends_on:
        - nginx
    environment:
        NGROK_PROTOCOL: http
        NGROK_PORT: nginx:80
        NGROK_AUTH: ${NGROK_AUTH}
        NGROK_HEADER: localhost
    ports:
        - 4040:4040
    networks:
        - pace
```

## Kontribusi:

Silakan bantu saya untuk mengembangkan versi php workspace di docker-compose ini. terimakasih.
