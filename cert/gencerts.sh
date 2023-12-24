#!/bin/bash

# 경로를 합치는 함수 정의
join_paths() {
    local path1=$1
    local path2=$2

    # 슬래시 추가 및 중복 제거
    echo "$path1/$path2" | sed 's#/\+#/#g'
}

# 파일 존재여부 확인
is_file_exists() {
    local file_path=$1

    if [ -f "$file_path" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# 파일 내용에서 원하는 "키"에 해당하는 "값" 추출
get_value() {
    local file_path=$1
    local key=$2

    value=$(grep "^$key=" "$file_path" | cut -d= -f2)
    echo $value
}

# 인증서 만료일 조회
get_expire_date() {
    cert_file_path = $1
    expire_date=$(openssl x509 -in "$cert_file_path" -noout -enddate | cut -d= -f2)
    echo $expire_date
}

# 인증서 만료일 이 30일 이하인지 확인
is_expire_soon() {
    cert_file_path = $1
    expire_date=$(get_expire_date "$cert_file_path")
    expire_date_timestamp=$(date -d "$expire_date" +%s)
    now_timestamp=$(date +%s)
    expire_soon_timestamp=$(date -d "+30 days" +%s)

    if [ $expire_date_timestamp -lt $expire_soon_timestamp ]; then
        echo "true"
    else
        echo "false"
    fi
}

# gencerts.sh 파일 경로 및 .secret 파일 조회
script_file_path=$(readlink -f "$0")
script_dir_path=$(dirname "$script_file_path")
secret_file_name=".secret"
secret_file_path=$(join_paths "$script_dir_path" "$secret_file_name")

export CERT_DIR=$script_dir_path
echo "USER : $USER | CERT_DIR : $CERT_DIR"

# .secret 파일이 존재하지 않으면 종료
if [ $(is_file_exists "$secret_file_path") = "false" ]; then
    echo "File not found: $secret_file_path"
    exit 1
fi

exit 0
# .secret > *.aaa.bbb
DOMAIN=$(get_value "$secret_file_path" "DOMAIN")
# .secret > ADMIN_EMAIL=yourmail@mail.com
ADMIN_EMAIL=$(get_value "$secret_file_path" "ADMIN_EMAIL")
# .secret > SECRET_AWS_ROUTE53_KEY=AWS IAM KEY
export SECRET_AWS_ROUTE53_KEY=$(get_value "$secret_file_path" "SECRET_AWS_ROUTE53_KEY")
# .secret > SECRET_AWS_ROUTE53_SECRET=AWS IAM SECRET
export SECRET_AWS_ROUTE53_SECRET=$(get_value "$secret_file_path" "SECRET_AWS_ROUTE53_SECRET")

echo "DOMAIN : $DOMAIN | ADMIN_EMAIL : $ADMIN_EMAIL"

# remove a previous dir
sudo rm -rf ${CERT_DIR}/letsencrypt

# generate ssl certs
${CERT_DIR}/certbot.sh ${DOMAIN} ${ADMIN_EMAIL} > ${CERT_DIR}/certbot.log 2>&1

# chown certs to USER_NAME
sudo chown ${USER}:${USER} ${CERT_DIR}/ssl.*

# Restart Nginx
# ${CERT_DIR}/restart-nginx.sh >> ${CERT_DIR}/certbot.log 2>&1

# Restart Harbor
# ${CERT_DIR}/restart-harbor.sh >> ${CERT_DIR}/certbot.log 2>&1
