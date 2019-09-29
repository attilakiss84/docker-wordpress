#!/bin/bash

DOMAIN=$1
PHPUSER=$2
FILE=$3

# MUST have replacements
perl -i -pe "s/DOMAIN/$DOMAIN/g" "$FILE"
perl -i -pe "s/PHP_USER/$PHPUSER/g" "$FILE"
perl -i -pe "s/(php_admin_value\[session.save_path\]\s+=\s+)(\/tmp\/session)/\1\/var\/www\/DOMAIN\/chroot\2/" "$FILE"
