#!/bin/bash
# set -x

[ -z ${CERT_DIR} ] && echo "ERROR: CERT_DIR not defined" && exit 0;

DOMAIN=$1
EMAIL=$2

[ -z "${DOMAIN}" -o -z "${EMAIL}" ] && echo "Usage: certbot.sh <*.domain.com> <email>" && exit 1
[ -z "${SECRET_AWS_ROUTE53_KEY}" -o -z "${SECRET_AWS_ROUTE53_SECRET}" ] && echo "SECRET_AWS_ROUTE53_KEY or SECRET_AWS_ROUTE53_SECRET not defined" && exit 1

DOMAIN_DIR=${DOMAIN#\*.}

if [[ ${DOMAIN} =~ ^\* ]]; then
  DOMAIN+=,${DOMAIN#\*.}
fi

PRIVATE_KEY_PATH=${CERT_DIR}/ssl.key
PUBLIC_KEY_PATH=${CERT_DIR}/ssl.crt
BOTH_KEY_PATH=${CERT_DIR}/ssl.pem

echo "PRIVATE_KEY_PATH : $PRIVATE_KEY_PATH"
echo "PUBLIC_KEY_PATH : $PUBLIC_KEY_PATH"
echo "BOTH_KEY_PATH : $BOTH_KEY_PATH"


[ -z "${SECRET_AWS_ROUTE53_KEY}" ] && echo "NOT DEFINED env - SECRET_AWS_ROUTE53_KEY"&& exit 1
[ -z "${SECRET_AWS_ROUTE53_SECRET}" ] && echo "NOT DEFINED env - SECRET_AWS_ROUTE53_SECRET" && exit 1

mkdir -p $CERT_DIR/letsencrypt

if test -d $CERT_DIR/letsencrypt/live/${DOMAIN_DIR};
then #renew
    docker run -i --rm --name certbot \
    -v $CERT_DIR/letsencrypt:/etc/letsencrypt \
    -v $CERT_DIR/letsencrypt:/var/lib/letsencrypt \
    -e AWS_ACCESS_KEY_ID=$SECRET_AWS_ROUTE53_KEY \
    -e AWS_SECRET_ACCESS_KEY=$SECRET_AWS_ROUTE53_SECRET \
    certbot/dns-route53 renew;
else # 1st time generation
    docker run -i --rm --name certbot \
    -v $CERT_DIR/letsencrypt:/etc/letsencrypt \
    -v $CERT_DIR/letsencrypt:/var/lib/letsencrypt \
    -e  AWS_ACCESS_KEY_ID=$SECRET_AWS_ROUTE53_KEY \
    -e  AWS_SECRET_ACCESS_KEY=$SECRET_AWS_ROUTE53_SECRET \
    certbot/dns-route53 certonly --dns-route53 \
        --email=${EMAIL} --no-eff-email --agree-tos \
        -d ${DOMAIN};
fi

sudo cp $CERT_DIR/letsencrypt/live/${DOMAIN_DIR}/privkey.pem ${PRIVATE_KEY_PATH}
sudo cp $CERT_DIR/letsencrypt/live/${DOMAIN_DIR}/fullchain.pem ${PUBLIC_KEY_PATH}
if [ -z "${BOTH_KEY_PATH}" ]; then
  BOTH_KEY_PATH="${PUBLIC_KEY_PATH%.crt}.pem"
fi
echo "... updaing private+public key - ${BOTH_KEY_PATH}";
sudo cat ${PRIVATE_KEY_PATH} ${PUBLIC_KEY_PATH} > ${BOTH_KEY_PATH}
exit 0;

