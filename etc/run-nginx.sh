#!/bin/bash

CERT_DIR=/home/rainbow/certs
NGINX_DIR=/home/rainbow/nginx

# logs
mkdir -p ${NGINX_DIR}/logs
 
# copy ssl certs
cp ${CERT_DIR}/ssl.* ${NGINX_DIR}/

# stop nginx
docker rm -f nginx

# start nginx
docker run -d --name nginx \
        --restart=always \
        -p 80:80 -p 443:443 \
        -v ${NGINX_DIR}:/etc/config:ro \
        -v ${NGINX_DIR}/nginx.conf:/etc/nginx/nginx.conf:ro \
        -v ${NGINX_DIR}/logs:/var/log/nginx \
        --net=host \
         nginx:1.19.10