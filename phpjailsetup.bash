#!/bin/bash

FILE=$1

perl -i -pe "s/;(chroot\s+=)/\1/" "$FILE"
perl -i -pe "s/;(chdir\s+=)/\1/" "$FILE"
perl -i -pe "s/;(php_admin_value\[open_basedir\]\s+=)/\1/" "$FILE"
perl -i -pe "s/;(php_admin_value\[sys_temp-dir\]\s+=)/\1/" "$FILE"
perl -i -pe "s/;(php_admin_value\[upload_tmp_dir\]\s+=)/\1/" "$FILE"
perl -i -pe "s/;(php_admin_value\[soap.wsdl_cache_dir\]\s+=)/\1/" "$FILE"
perl -i -pe "s/;(php_admin_value\[sendmail_path\]\s+=)/\1/" "$FILE"
perl -i -pe "s/;(php_admin_value\[session.entropy_file\]\s+=)/\1/" "$FILE"
perl -i -pe "s/;(php_admin_value\[openssl.capath\]\s+=)/\1/" "$FILE"
