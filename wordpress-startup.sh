#!/bin/sh

WWW_LOCATION=$1
VOLUME_MOUNT_POINT=$2
MOUNT_JAIL=$3

if [ ! -z "$VOLUME_MOUNT_POINT" ]
then
    if [ -d "$VOLUME_MOUNT_POINT/wordpress/" ]
    then
        rsync -ogr "$VOLUME_MOUNT_POINT/wordpress/www/" "$WWW_LOCATION"
        rsync -ogr "$VOLUME_MOUNT_POINT/wordpress/mysql/" "/var/lib/mysql/"
    else
        mkdir -p "$VOLUME_MOUNT_POINT/wordpress/www/"
        mkdir -p "$VOLUME_MOUNT_POINT/wordpress/mysql/"
    fi

    trap 'rsync -ogr $WWW_LOCATION $VOLUME_MOUNT_POINT/wordpress/www/ && rsync -ogr /var/lib/mysql/ $VOLUME_MOUNT_POINT/wordpress/mysql/' 0
fi

service mysql start
if [ ! -z "$MOUNT_JAIL" ]
then
    php-chroot-bind bind
fi
service php7.2-fpm start
service nginx start
/bin/bash
