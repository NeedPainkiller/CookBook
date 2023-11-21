#!/bin/bash

export USER=rainbow
export CERT_DIR=/home/${USER}/certs

DOMAIN=*.aaa.bbb
ADMIN_EMAIL=

export SECRET_AWS_ROUTE53_KEY=""
export SECRET_AWS_ROUTE53_SECRET=""

# remove a previous dir
sudo rm -rf ${CERT_DIR}/letsencrypt

# generate ssl certs
${CERT_DIR}/certbot.sh ${DOMAIN} ${ADMIN_EMAIL} > ${CERT_DIR}/certbot.log 2>&1

# chown certs to USER_NAME
sudo chown ${USER}:${USER} ${CERT_DIR}/ssl.*

# Restart Nginx
${CERT_DIR}/restart-nginx.sh >> ${CERT_DIR}/certbot.log 2>&1

# Restart Harbor
${CERT_DIR}/restart-harbor.sh >> ${CERT_DIR}/certbot.log 2>&1
