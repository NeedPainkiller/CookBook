#!/bin/bash

CERT_DIR=/home/rainbow/certs
HARBOR_DIR=/home/rainbow/harbor

# copy ssl certs
sudo cp ${CERT_DIR}/ssl.* ${HARBOR_DIR}/config/proxy/

cd $HARBOR_DIR
docker-compose restart