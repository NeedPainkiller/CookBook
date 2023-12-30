# SSL / TLS

## SSL / TLS {id="tls_1"}

- SSL (Secure Sockets Layer) 는 넷스케이프에서 개발한 프로토콜로, 인터넷 상에서 데이터를 안전하게 전송하기 위해 고안된 프로토콜입니다.

### SSL / TLS 차이 {id="tls_1_1"}

| 구분     | SSL                                                 | TLS                                                        |
|--------|-----------------------------------------------------|------------------------------------------------------------|
| 의미     | SSL은 Secure Sockets Layer 즉, 보안 소켓 계층을 의미합니다.       | TLS는 Transport Layer Security 즉, 전송 계층 보안을 의미합니다.          |
| 버전 기록  | SSL은 이제 TLS로 대체되었습니다. SSL은 버전 1.0, 2.0 및 3.0이 있습니다. | TLS는 SSL의 업그레이드된 버전입니다. TLS는 버전 1.0, 1.1, 1.2 및 1.3이 있습니다. |
| 사용     | 이제 모든 SSL 버전이 더 이상 사용되지 않습니다.                       | TLS 버전 1.2 및 1.3이 현재 사용되고 있습니다.                            |
| 알림 메시지 | SSL에는 두 가지 유형의 알림 메시지만 있습니다. 알림 메시지는 암호화되지 않습니다.    | TLS 알림 메시지는 암호화되며 더 다양합니다.                                 |
| 메시지 인증 | SSL은 MAC을 사용합니다.                                    | TLS는 HMAC을 사용합니다.                                          |
| 암호 그룹  | SSL은 알려진 보안 취약점이 있는 이전 알고리즘을 지원합니다.                 | TLS는 고급 암호화 알고리즘을 사용합니다.                                   |
| 핸드셰이크  | SSL 핸드셰이크는 복잡하고 느립니다.                               | TLS 핸드셰이크는 단계가 적고 연결 속도가 빠릅니다.                             |

## TLS / SSL 인증서 발급하기 (Let's Encrypt) {id="tls_2"}

### 사전 지식 {id="tls_2_1"}

- SSL 인증서는 인증기관(CA)에서 발급받아야 합니다.
- 인증서 발급을 위해서는 도메인 소유권을 증명해야 합니다.
- 도메인 소유권 증명은 DNS TXT 레코드를 이용합니다.
- DNS TXT 레코드는 도메인의 DNS 서버에 등록해야 합니다.
- DNS 서버는 도메인을 구매한 업체에서 제공합니다.
- DNS 서버에 등록한 DNS TXT 레코드는 인증기관에서 확인합니다.
- 인증기관은 도메인 소유권을 확인한 후 SSL 인증서를 발급합니다.

### Installation & Requirements {id="tls_2_2"}

- Docker
- 도메인 (가비아 등에서 구매)
- AWS (Route 53)

### AWS 설정 {id="tls_2_3"}
<procedure>
<step>
    <p>AWS 계정 생성</p>
    <p>❗계정 생성 후 AWS IMA 에서 MFA (Multi-Factor Authentication) 등록 할 것</p>
</step>
<step>
    <p>AWS Route 53 등록</p>
    <p>도메인 제공업체에서 구매한 도메인으로 등록 할 것</p>
    <img src="route53-1.png" alt=""/>
</step>
<step>
    <p>AWS Route 53의 Nameserver 주소를 도메인 제공업체의 네임서버에 등록</p>
    <p>Route 53 에 명시된 "NS" 참조</p>
    <img src="gabia-1.png" alt=""/>
</step>
<step>
    <p>AWS IAM 에서 Route53 에 접근 가능한 사용자 (매니저) 생성</p>
    <p>AmazonRoute53FullAccess 권한으로 등록</p>
    <img src="aws-iam-1.png" alt=""/>
    <img src="aws-iam-2.png" alt=""/>
</step>
<step>
    <p>매니저 AccessKey, SecretAccessKey 발급</p>
    <img src="aws-iam-3.png" alt=""/>
    <img src="aws-iam-4.png" alt=""/>
    <img src="aws-iam-5.png" alt=""/>
</step>
</procedure>

### TLS / SSL 인증서 발급 스크립트 {id="tls_2_4 {id="tls_2"}"}
#### certbot.sh {id="tls_2_4_1"}
```Bash
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
```
#### gencert.sh {id="tls_2_4_2"}
```Bash
#!/bin/bash

# 경로를 합치는 함수 정의
join_paths() {
    local path1=$1
    local path2=$2

    # 슬래시 추가 및 중복 제거
    echo "$path1/$path2" | sed 's#/\+#/#g'
}

# 파일 내용에서 원하는 "키"에 해당하는 "값" 추출
get_value() {
    local file_path=$1
    local key=$2

    value=$(grep "^$key=" "$file_path" | cut -d= -f2)
    echo $value
}

# gencerts.sh 파일 경로 및 .secret 파일 조회
script_file_path=$(readlink -f "$0")
script_dir_path=$(dirname "$script_file_path")
secret_file_name=".secret"
secret_file_path=$(join_paths "$script_dir_path" "$secret_file_name")

export CERT_DIR=$script_dir_path
echo "USER : $USER | CERT_DIR : $CERT_DIR"

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
```

### TLS / SSL 인증서 발급 {id="tls_2_5"}
<procedure>
    <step>
        <p>.secret 파일 생성</p>
        <code-block lang="shell">
            #.secret
            DOMAIN=*.aaa.bbb
            ADMIN_EMAIL=yourmail@mail.com
            SECRET_AWS_ROUTE53_KEY={AWS IAM AccessKey}
            SECRET_AWS_ROUTE53_SECRET={AWS IAM SecretAccessKey}
        </code-block>
        <list>
            <li>도메인은 Wildcard 형태로 기입 (<code>*.xxx.com</code>)</li>
            <li>letsencrypt 에서 구분을 위해 사용하는 이메일 기입</li>
            <li>AWS IAM 에서 발급한 <code>AccessKey</code>,<code>SecretAccessKey</code> 기입</li>
            <li>.secret 파일은 <code>.gitignore</code> 에 등록되어 있으므로 파일명을 변경하지 말 것</li>
        </list>
    </step>
    <step>
        <p>SSL 인증서 발급</p>
        <code-block lang="bash">
            ./gencerts.sh
        </code-block>
    </step>
        <step>
        <p>SSL 인증서 파일 확인</p>
        <code>ssl.crt</code>
        <list>
            <li>CRT 파일은 X.509 표준에 따라 인증서의 공개 키를 포함하는 파일입니다.</li>
            <li>주로 서버 인증서나 클라이언트 증명서에 사용됩니다.</li>
            <li>이 파일은 공개 키, 서버 또는 클라이언트의 정보 및 서명된 인증서의 유효 기간 등을 포함합니다.</li>
            <li>주로 웹 서버에서 HTTPS 연결에 사용되며, 클라이언트와 서버 간의 통신을 암호화하고 보안을 제공합니다.</li>
        </list>
        <code>ssl.key</code>
        <list>
            <li>KEY 파일은 인증서와 연결된 비밀 키(Private Key)를 포함합니다.</li>
            <li>이 파일은 암호화 및 디지털 서명 생성에 사용되는 중요한 비밀 정보를 담고 있습니다.</li>
            <li>일반적으로 서버에서는 이 비밀 키를 안전하게 보관해야 하며, 이 키를 사용하여 인증서의 유효성을 확인하거나 암호화된 통신을 해독할 수 있습니다.</li>
        </list>
        <code>ssl.pem</code>
        <list>
            <li>PEM (Privacy Enhanced Mail)은 주로 인증서 및 개인 키를 저장하는 데 사용되는 파일 형식입니다.</li>
            <li>PEM 파일은 BASE64로 인코딩된 ASCII 텍스트로 구성되어 있습니다.</li>
            <li>주로 CRT와 KEY를 포함하며, 때로는 인증 기관의 중간 인증서나 기타 보안 관련 정보도 포함될 수 있습니다.</li>
            <li>OpenSSL 및 다른 유틸리티에서 사용되는 표준 형식 중 하나입니다.</li>
        </list>
    </step>
</procedure>

### TLS / SSL 인증서 갱신 자동화 {id="tls_2_6"}
- letsencrypt 인증서는 90일마다 갱신해야 합니다.
- 인증서 갱신은 인증서 발급과 동일한 방법으로 수행합니다.
- crontab 을 이용하여 인증서 갱신을 자동화 할 수 있습니다.

```Bash
# Run gencerts.sh at 00:00 on every 1st day of a month
0 0 1 * * /.../gencerts.sh
```
## 인증서 파일 형식의 차이점

### 인코딩 

- .der
  - Distinguished Encoding Representation (DER)
  - 바이너리 DER 형식으로 인코딩된 인증서
  - 인증서를 인코딩하는 방식 중 하나로 인코딩된 인증서는 바이너리 형태로 저장되어있어서 인코딩된 인증서를 열어보면 이해할 수 없는 문자열이 나온다.
- .pem
  - Privacy Enhanced Mail (PEM)
  - Base64인코딩된 ASCII text file
  - X.509 v3 파일의 한 형태 (X.509 v3은 인증서의 표준 형식)
  - 본래 secure email 에 사용되는 인코딩 포멧이었는데 본 용도로 쓰지 않고 인증서 또는 키값을 저장하는데 많이 사용된다.
  - -----BEGIN XXX-----, -----END XXX-----로 묶여 있으며, 담고있는 내용이 무엇인지에 따라 XXX 위치에 CERTIFICATE, RSA PRIVATE KEY 등의 키워드가 들어있다
  - 인증서(Certificate = public key), 비밀키(private key), 인증서 발급 요청을 위해 생성하는 CSR (certificate signing request) 등을 저장하는데 사용된다.

#### 인코딩 변환
- DER -> PEM
```Bash
openssl x509 -inform der -in certificate.cer -out certificate.pem 
```

- PEM -> DER
```Bash
openssl x509 -outform der -in certificate.pem -out certificate.der

# 암호화 없는 DER 로 변환하려면 아래 명령어 사용
openssl pkcs8 -topk8 -inform PEM -outform DER -in private.key -out private.der -nocrypt 
```

### 확장자
- .crt, .cer
  - 인증서를 나타내는 확장자
  - CER 과 CRT 는 같은 기능을 하지만, CER은 주로 윈도우에서 사용되고, CRT는 유닉스 계열에서 사용된다.
  - 인코딩 형식은 DER, PEM 두가지가 사용되지만, 파일 명 만으로는 어떤 인코딩 형식인지 알 수 없다.
- .key
  - 개인 또는 공개 PKCS#8 키
- .p12
  - PKCS#12 형식, 하나 또는 그이상의 certificate(public)과 그에 대응하는 private key를 포함하고 있는 key store 파일이며 패스워드로 암호화 되어있다. 열어서 내용을 확인하려면 패스워드가 필요하다.
- .pfx
  - PKCS#12는 Microsoft의 PFX파일을 계승하여 만들어진 포멧이라 pfx와 p12를 구분없이 동일하게 사용하기도 한다.

## 인증서 표준
|표준 | 설명                                                                 |
|-----|--------------------------------------------------------------------|
|X.509 | 인증서의 표준 형식                                                         |
|PKCS#5 | 비밀번호 기반의 암호화를 위해 사용되는 표준 형식                                        |
|PKCS#7 | 인증서 체인을 저장하는데 사용되는 표준 형식                                           |
|PKCS#8 | 개인 키를 저장하는데 사용되는 표준 형식, PEM 인코딩을 사용                                |
|PKCS#10 | 인증서 발급 요청을 저장하는데 사용되는 표준 형식|
|PKCS#12 | 인증서와 개인 키를 저장하는데 사용되는 표준 형식, 단일 파일에 여러 인증서 정보를 합쳐 보관하는 방식에 대한 표준이다 |

- X.509
  - public key infrastructure (PKI)에 대한 ITU-T의 표준 (RFC 5280)
  - 공개키(public key) 인증서의 format, revocation list(더이상 유효하지 않은 인증서들에 대한 정보 배포), certification path(chain) validation 알고리즘 등을 정의
  - 보통 X.509 인증서라 하면 RFC 5280에 따라서 인코딩되거나 서명된 디지털 문서를 의미
  - X.509 인증서는 인증서의 발급자, 유효 기간, 공개키, 서명 알고리즘 등의 정보를 포함하고 있다.
  - X.509 인증서는 DER 형식 또는 PEM 형식으로 인코딩된다.

### PKCS Padding

#### PKCS5Padding, PKCS7Padding
- 대칭키 알고리즘(ex: AES)을 사용 할 때 암호화 하려는 데이터의 길이가 긴 경우 ECB (Electronic Codebook), CBC(Cipher Block Chain) 등의 block cipher 방식을를 사용해서 데이터를 암호화 하게된다. 
- 블록단위로 잘라서 암호화/복호화가 진행되기 때문에 정해진 마지막 블록의 사이즈와 실제 데이터의 크기가 맞지 않는 경우가 생길 수 있다. 
- 이때 마지막 블록의 빈 공간을 채워넣는(padding) 방식을 말한다.

##### 예시
- 예를 들어 데이터가 17바이트인데 block size가 8바이트라면 총 3개의 블록이 필요하고 마지막 블록은 7바이트가 남기때문에 이부분을 특정 값으로 채워넣어서 암호화를 진행한다.
- PKCS5Padding과 PKCS7Padding 둘다 빈 공간에 값을 채워넣는 규칙은 다음과 같다.
  - 마지막 블록에 1바이트가 남는다면 01을 채워넣고 (01은 1바이트를 16진수 표기한 값)
  - 마지막 블록에 2바이트가 남는다면 02 02를 채워넣음
  - 마지막 블록에 3바이트가 남는다면 03 03 03를 채워넣음
- 대신 PKCS5Padding과 PKCS7Padding의 경우 block size의 제약 조건이 다르다.
  - PKCS5Padding의 경우 block size 8바이트로 고정
  - PKCS7Padding의 경우 block size 최대 255바이트까지 지원

#### PKCS1Padding
- PKCS1Padding는 앞서말한 PKCS5Padding/PKCS7Padding과는 방식도 다르고 사용처도 다르다
- PKCS1Padding는 보통 RSA 알고리즘과 같이 사용되며 PKCS#1 v1.5 에 명시된 padding 방법을 사용한다.
- PKCS1Padding의 경우 block size의 제약 조건이 없다.

##### 예시
- PKCS1Padding의 경우 마지막 블록의 빈 공간을 채워넣는 규칙은 다음과 같다.
  - 마지막 블록의 첫 바이트는 0x00
  - 마지막 블록의 두번째 바이트는 0x02
  - 마지막 블록의 세번째 바이트부터는 0x00이 아닌 임의의 값이 들어간다.
- Encryption Block 구성 = 00 || Block Type || Padding || 00 || Data
- 최소 11바이트의 패딩이 추가된다. (오버헤드가 크다) 이 중 8바이트는 1~255 사이의 랜덤 값으로 채워진다.
- 이런 랜덤 특성 때문에 동일한 데이터를 암호화 해도 매번 다른 결과가 나온다.
- RSA의 특성상 보통 content전체를 암호화하는데 사용되지 않고, content를 암호화 하는데 사용한 content key(private key)를 암호화 하기 위한 수단으로 사용되기 때문에 메세지의 크기가 늘어나는 패딩 오버헤드는 크게 문제되지 않는다.

#### Crpyto Library in Java
- Java에서 제공하는 Crypto 라이브러리의 경우 Cipher.getInstance(“algorithm/mode/padding”) 형식의 스트링으로 암호화 알고리즘, 모드, 패딩방식을 결정할 수 있다. 
- 참고로 데이터의 길이가 길어서 (블럭의 갯수가 하나 이상)인 경우 ECB는 보안성이 취약하니 CBC를 꼭 사용해야 한다. (각 블럭의 데이터가 섞이지 않은 상태로 동일한 암호화를 적용하면 데이터에 패턴이 나타나게됨)

##### 예시
- “RSA/ECB/PKCS1Padding” (참고: 이 방식은 1개의 블록만 암호화 할 수 있도록 구현되어있기 때문에 실제로는 ECB라고 부를 수 없다.)
- “AES/ECB/PKCS5Padding “
- “AES/CBC/PKCS5Padding “
- “AES/ECB/PKCS7Padding “
- “AES/CBC/PKCS7Padding ”


## 인증서 발급기관 (CA)
- 인증서 발급기관 (Certificate Authority, CA)은 인증서를 발급하는 기관을 의미합니다.
- 인증서 발급기관은 인증서를 발급하는 것 외에도 인증서의 유효성을 검증하는 역할도 수행합니다.

<seealso>
<category ref="reference">
<a href="https://www.letmecompile.com/certificate-file-format-extensions-comparison/">인증서 파일 형식 및 확장자의 차이점 비교 설명 (Certificate file format & extensions)</a>
<a href="https://datatracker.ietf.org/doc/html/rfc5280">RFC 5280: Internet X.509 Public Key Infrastructure Certificate and Certificate Revocation List (CRL) Profile</a>
<a href="https://datatracker.ietf.org/doc/html/rfc2313">PKCS #1: RSA Encryption Version 1.5</a>
<a href="https://datatracker.ietf.org/doc/html/rfc2315">PKCS #7: Cryptographic Message Syntax</a>
<a href="https://datatracker.ietf.org/doc/html/rfc5208">PKCS #8: Private-Key Information Syntax Specification</a>
<a href="https://datatracker.ietf.org/doc/html/rfc7292">PKCS #12: Personal Information Exchange Syntax Standard</a>
<a href="https://www.openssl.org/docs/manmaster/man1/pkcs8.html">OpenSSL PKCS8</a>
<a href="https://www.openssl.org/docs/manmaster/man1/rsa.html">OpenSSL RSA</a>
<a href="https://crypto.stackexchange.com/questions/25899/using-ecb-as-rsa-encryption-mode-when-encrypted-messages-are-unique">using-ecb-as-rsa-encryption-mode</a>
</category>
</seealso>