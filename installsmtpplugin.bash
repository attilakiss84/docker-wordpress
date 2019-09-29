#!/bin/bash

WP_LOCATION=$1
SMTP_PASSWORD=$2

if [ -d "$WP_LOCATION" ]; then
    wget -O /root/wp-mail-smtp.zip https://downloads.wordpress.org/plugin/wp-mail-smtp.1.5.2.zip
    unzip /root/wp-mail-smtp.zip -d "${WP_LOCATION}wp-content/plugins/"
    rm /root/wp-mail-smtp.zip

    if [ ! -z "$SMTP_PASSWORD" ]; then
        # Escaping password for PHP
        SMTP_PASSWORD=$(echo "$SMTP_PASSWORD" | sed "s|'|"'\\\\'"'|g")

        sed -i "/^\/\* That's all/i // ** WP-MAIL-SMTP Plugin Settings ** //" "${WP_LOCATION}wp-config.php"
        sed -i "/^\/\* That's all/i define( 'WPMS_ON', true );" "${WP_LOCATION}wp-config.php"
        sed -i "/^\/\* That's all/i define( 'WPMS_SMTP_PASS', '$SMTP_PASSWORD' );" "${WP_LOCATION}wp-config.php"
        sed -i "/^\/\* That's all/{x;p;x}" "${WP_LOCATION}wp-config.php"
    fi
else
    exit 1
fi