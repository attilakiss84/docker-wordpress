FROM ubuntu:18.04
LABEL version="0.0.1"
LABEL description="Creates a wordpress installation on php-fpm & nginx basis. Entry point is the 5mins installation step."

# Update base installation and install tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-utils \
    && apt-get -y upgrade && apt-get -y dist-upgrade \
    && apt-get -y install git curl wget tar perl unzip rsync \
    && apt-get clean

# Install MySQL
ARG mysqluser=wordpress-blog
ARG mysqlpassword=wordpress-blog
ARG mysqldb=wordpress-blog
# MySQL default is 3306
ARG mysqlport=3316
RUN apt-get -y install mysql-server \
    && apt-get clean \
    && service mysql stop \
    && perl -i -pe "s/(port\s+=)\s+\d+/\1 ${mysqlport}/" /etc/mysql/mysql.conf.d/mysqld.cnf \
    && service mysql start

# Install Nginx
RUN apt-get -y install nginx nginx-extras \
    && apt-get clean \
    && rm /etc/nginx/sites-enabled/default \
    && service nginx restart

# Install PHP
RUN \
    # Installing PHP-fpm
    ln -fs /usr/share/zoneinfo/Europe/Helsinki /etc/localtime \
    && apt-get install -y tzdata \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && apt-get -y install php-fpm php-mysql php-curl php-gd php-imagick php-bcmath \
    && apt-get clean

# Install Wordpress
ARG phpuser=wordpress-blog
ARG subdomain=wordpress
ARG domain=localhost.com
ARG wwwport=8080
ARG dbtableprefix=wpb_
COPY nginx.conf php.conf setup.sql phpsetup.bash hash.bash /root/wordpress-blog/
RUN \
    # Create MySQL user and database
    cp /root/wordpress-blog/setup.sql /root/wordpress-blog/${subdomain}.${domain}.sql \
    && perl -i -pe "s:PASSWORD:'${mysqlpassword}':" /root/wordpress-blog/${subdomain}.${domain}.sql \
    && perl -i -pe "s:USERNAME:'${mysqluser}':g" /root/wordpress-blog/${subdomain}.${domain}.sql \
    && perl -i -pe "s:DB:\`${mysqldb}\`:g" /root/wordpress-blog/${subdomain}.${domain}.sql \
    && service mysql start \
    && mysql < /root/wordpress-blog/${subdomain}.${domain}.sql \
    && rm /root/wordpress-blog/${subdomain}.${domain}.sql
    #&& rm /root/wordpress-blog/setup.sql
RUN \
    # Create PHP user
    adduser ${phpuser} --gecos "" --no-create-home --disabled-password --shell=/bin/false  \
    && usermod -a -G ${phpuser} www-data && service nginx restart \
    && mkdir -p /var/www/${subdomain}.${domain}/chroot/src/public \
    && mkdir -p /var/www/${subdomain}.${domain}/chroot/tmp/session \
    # Creating log folder
    && mkdir /var/log/${subdomain}.${domain} \
    && chown -R ${phpuser}:${phpuser} /var/log/${subdomain}.${domain}
RUN \
    # Create PHP socket
    cp /root/wordpress-blog/php.conf /root/wordpress-blog/${subdomain}.${domain}.conf \
    && mv /root/wordpress-blog/phpsetup.bash /root/wordpress-blog/phpsetup && chmod 700 /root/wordpress-blog/phpsetup \
    && chmod 700 /root/wordpress-blog/hash.bash \
    # NOTE: Sed command's parameter interpolation really didn't work, that's why execution script
    && /root/wordpress-blog/phpsetup "${subdomain}.${domain}" "${phpuser}" "/root/wordpress-blog/${subdomain}.${domain}.conf" \
    && mv /root/wordpress-blog/${subdomain}.${domain}.conf /etc/php/7.2/fpm/pool.d/${subdomain}.${domain}.conf \
    && rm /etc/php/7.2/fpm/pool.d/www.conf \
    && service php7.2-fpm restart
    # && rm /root/wordpress-blog/php.conf && rm/root/wordpress-blog/phpsetup
RUN \
    # Adding domain to hosts file
    echo "127.0.0.1 ${subdomain}.${domain}" >> /etc/hosts
RUN \
    # Creating Nginx configuration
    cp /root/wordpress-blog/nginx.conf /root/wordpress-blog/${subdomain}.${domain} \
    && perl -i -pe "s/DOMAIN/${subdomain}.${domain}/g" /root/wordpress-blog/${subdomain}.${domain} \
    && perl -i -pe "s/WWW_PORT/${wwwport}/" /root/wordpress-blog/${subdomain}.${domain} \
    && mv /root/wordpress-blog/${subdomain}.${domain} /etc/nginx/sites-available/${subdomain}.${domain} \
    && ln -s /etc/nginx/sites-available/${subdomain}.${domain} /etc/nginx/sites-enabled/${subdomain}.${domain} \
    && nginx -t && service nginx reload
    # && rm /root/wordpress-blog/nginx.conf
RUN \
    # Getting WordPress
    wget -O /root/wordpress-blog/wordpress-latest.tar.gz https://wordpress.org/latest.tar.gz \
    && tar -xzvf /root/wordpress-blog/wordpress-latest.tar.gz -C /root
    #&& rm /root/wordpress-blog/wordpress-latest.tar.gz
RUN \
    # Setup WordPress
    cp /root/wordpress/wp-config-sample.php /root/wordpress/wp-config.php \
    && perl -i -pe "s/('DB_NAME',) 'database_name_here'/\1 '${mysqldb}'/" /root/wordpress/wp-config.php \
    && perl -i -pe "s/('DB_USER',) 'username_here'/\1 '${mysqluser}'/" /root/wordpress/wp-config.php \
    && perl -i -pe "s/('DB_PASSWORD',) 'password_here'/\1 '${mysqlpassword}'/" /root/wordpress/wp-config.php \
    && perl -i -pe "s/('DB_HOST',) 'localhost'/\1 '127.0.0.1:${mysqlport}'/" /root/wordpress/wp-config.php \
    && perl -i -pe "s/(table_prefix\s*=\s*')wp_/\1${dbtableprefix}/" /root/wordpress/wp-config.php \
    && perl -i -pe 'my $hash = `/bin/bash /root/wordpress-blog/hash.bash`; s/(define\(\s*'\''AUTH_KEY'\'',\s*'\'')put your unique phrase here*/\1$hash/;' /root/wordpress/wp-config.php \
    && perl -i -pe 'my $hash = `/bin/bash /root/wordpress-blog/hash.bash`; s/(define\(\s*'\''SECURE_AUTH_KEY'\'',\s*'\'')put your unique phrase here*/\1$hash/;' /root/wordpress/wp-config.php \
    && perl -i -pe 'my $hash = `/bin/bash /root/wordpress-blog/hash.bash`; s/(define\(\s*'\''LOGGED_IN_KEY'\'',\s*'\'')put your unique phrase here*/\1$hash/;' /root/wordpress/wp-config.php \
    && perl -i -pe 'my $hash = `/bin/bash /root/wordpress-blog/hash.bash`; s/(define\(\s*'\''NONCE_KEY'\'',\s*'\'')put your unique phrase here*/\1$hash/;' /root/wordpress/wp-config.php \
    && perl -i -pe 'my $hash = `/bin/bash /root/wordpress-blog/hash.bash`; s/(define\(\s*'\''AUTH_SALT'\'',\s*'\'')put your unique phrase here*/\1$hash/;' /root/wordpress/wp-config.php \
    && perl -i -pe 'my $hash = `/bin/bash /root/wordpress-blog/hash.bash`; s/(define\(\s*'\''SECURE_AUTH_SALT'\'',\s*'\'')put your unique phrase here*/\1$hash/;' /root/wordpress/wp-config.php \
    && perl -i -pe 'my $hash = `/bin/bash /root/wordpress-blog/hash.bash`; s/(define\(\s*'\''LOGGED_IN_SALT'\'',\s*'\'')put your unique phrase here*/\1$hash/;' /root/wordpress/wp-config.php \
    && perl -i -pe 'my $hash = `/bin/bash /root/wordpress-blog/hash.bash`; s/(define\(\s*'\''NONCE_SALT'\'',\s*'\'')put your unique phrase here*/\1$hash/;' /root/wordpress/wp-config.php
COPY installsmtpplugin.bash /root/wordpress-blog/
ARG smtppassword
RUN \
    # Doing optional cleanup & plugin installation
    ls -d /root/wordpress/wp-content/themes/*/ | grep invert twentynineteen | xargs rm -rf \
    && rm /root/wordpress/wp-content/plugins/hello.php \
    && mv /root/wordpress-blog/installsmtpplugin.bash /root/wordpress-blog/installsmtpplugin && chmod 700 /root/wordpress-blog/installsmtpplugin \
    && /root/wordpress-blog/installsmtpplugin "/root/wordpress/" "${smtppassword}"  \
    && wget -O /root/wordpress-blog/wordfence.zip https://downloads.wordpress.org/plugin/wordfence.7.3.5.zip \
    && unzip /root/wordpress-blog/wordfence.zip -d /root/wordpress/wp-content/plugins/ \
    && rm /root/wordpress-blog/wordfence.zip \
    && wget -O /root/wordpress-blog/enlighter.zip https://downloads.wordpress.org/plugin/enlighter.3.10.0.zip \
    && unzip /root/wordpress-blog/enlighter.zip -d /root/wordpress/wp-content/plugins/ \
    && rm /root/wordpress-blog/enlighter.zip
RUN \
    # Moving WordPress to hosting folder
    rm /root/wordpress/wp-config-sample.php \
    && mv /root/wordpress/* /var/www/${subdomain}.${domain}/chroot/src/public && rmdir /root/wordpress \
    && chown -R ${phpuser}:${phpuser} /var/www/${subdomain}.${domain}

# Boot script setup
COPY wordpress-startup.sh /root/wordpress-blog/wordpress-startup
RUN chmod 755 /root/wordpress-blog/wordpress-startup \
    && ln -s /root/wordpress-blog/wordpress-startup /usr/local/bin/wordpress-startup

# # Setup PHP-jail
# # NOTE: Disabled as by default inside the container don't have mount rights
# COPY phpjailsetup.bash /root/wordpress-blog/
# RUN \
#     # Getting jail software
#     git clone https://github.com/68b32/php-chroot-bind.git /root/php-chroot-bind \
#     && perl -i -pe "s/(_CHROOTS_CMD=\"ls -1d )\/home\/www\/\*\/chroot(\")/\1\/var\/www\/*\/chroot\2/" /root/php-chroot-bind/php-chroot-bind \
#     && ln -s /root/php-chroot-bind/php-chroot-bind /usr/local/sbin/php-chroot-bind
# RUN \
#     # Binding resources
#     /bin/bash /root/php-chroot-bind/php-chroot-bind bind
# RUN \
#     # Updating PHP configuration
#     mv /root/wordpress-blog/phpjailsetup.bash /root/wordpress-blog/phpjailsetup && chmod 700 /root/wordpress-blog/phpjailsetup \
#     && /root/wordpress-blog/phpjailsetup "/root/etc/php/7.2/fpm/pool.d/${subdomain}.${domain}.conf" \
#     && service php7.2-fpm restart
# RUN \
#     # Updating Nginx configuration
#     perl -i -pe 's/(fastcgi_param\s+SCRIPT_FILENAME\s+).+(\$fastcgi_script_name)/\1\/src\/public\2/' /etc/nginx/sites-available/${subdomain}.${domain} \
#     && nginx -t && service nginx reload
# RUN \
#     # Enable jailing in boot script
#     perl -i -pe "s/#\s*(php-chroot-bind)/\1/" /root/wordpress-blog/wordpress-startup

# Startup settings
EXPOSE ${wwwport}
ARG volumemountpoint
ENV wholedomain=$subdomain.$domain
ENV mountpoint=$volumemountpoint
# CMD ["wordpress-startup", "/var/www/${domain}/chroot/src/public/", "${volume-mount-point}"]
ENTRYPOINT ["/bin/bash", "-c", "wordpress-startup \"/var/www/${wholedomain}/chroot/src/public/\" \"${mountpoint}/\""]
# CMD ["/bin/bash"]
