#!/bin/bash

while inotifywait -q -r -e create,delete,modify,move,attrib --exclude "/\." /etc/nginx/ /etc/nginx/ext.d; 
do 
    nginx -t && nginx -s reload; 
done
