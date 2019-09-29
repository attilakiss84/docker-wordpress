#!/bin/bash

# sed command is added because escaping is needed in the PHP file
< /dev/urandom tr -dc "[:graph:]" | head -c64 | sed -E "s/'/\\\'/g" ;printf %s ;
