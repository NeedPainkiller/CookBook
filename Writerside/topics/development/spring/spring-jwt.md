# JWT / JWK

## Session 기반 인증의 특징

- 전통적인 Session 기반의 인증은 백엔드, 웹 어플리케이션 서버 측에서 세션 상태를 관리하고 유지시켜 주어야 하고, 또한 stateless 하지 않는 방식이기 때문에 서버의 확장성이 떨어지고, 서버의 부하가
  증가하게 된다.
- 브라우저에서 세션을 저장하는 쿠키는 도메인 공유가 허용되지 않기 때문에 여러 도메인을 사용하는 서비스의 경우에는 세션을 공유할 수 없다. (물론 쿠키 설정을 변경하면 가능하지만 보안상의 이슈가 발생할 수 있다.)
- 하지만 이는 문제점이라고 볼 수도 있고 장점이라고 볼 수도 있다. 세션을 서버에서 관리하기 때문에 서버에서 세션을 삭제하면 로그아웃이 되는 것이고, 서버에서 세션을 관리하기 때문에 세션을 삭제하면 다른 기기에서도
  로그아웃이 되는 것이다.
- 이는 보안적인 측면에서는 좋은 방법이지만, 사용자의 편의성을 생각한다면 좋은 방법이라고 볼 수 없다.
- 뭐든지 웹 보안은 trade-off가 존재한다. 보안을 강화하면 사용자의 편의성이 떨어지고, 사용자의 편의성을 높이면 보안이 떨어지는 것이다.

## JWT (JSON Web Token)

- JWT는 세션을 서버에서 관리하지 않고, 클라이언트 측에서 관리하고, 서버는 단지 JWT의 유효성만 검증하면 되기 때문에 서버의 확장성이 높아지고, 서버의 부하가 줄어들게 된다.
- Http 요청 시 마다 Header 등에 인증 토큰을 포함시켜 요청을 보내기 때문에, 쿠키를 사용하지 않기 때문에 도메인 공유의 문제가 발생하지 않는다.
- 하지만 JWT는 인증 상태를 서버에서 관리하지 않기 때문에, 서버측에서 로그아웃 기능을 위해서는 세션과 같은 방식으로 JWT를 관리해야 한다. (데이터베이스)
- 클라이언트 단에서 JWT 를 폐기하는 방법으로 로그아웃을 할 수는 있으나, 토큰 자체는 유효하기 때문에, 만약에 토큰이 탈취된다면, 탈취된 토큰을 사용하여 인증이 가능하다.
- 이는 보안적인 측면에서는 좋지 않은 방법이지만, 사용자의 편의성을 생각한다면 좋은 방법이라고 볼 수 있다.
- 또한 토큰 기반의 인증에서는 서명 또는 대칭 키 암호화를 사용하여 악의적인 의도를 가진 공격자가 토큰을 변조하는 것을 방지할 수 있다.

### 표준

- [RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519), 2015년 5월 23일에 공개되었다.
- JWT는 header, payload, signature 를 .(dot)으로 구분하여 합쳐진 문자열이다.
- 각각 header, payload, signature 는 Base64로 인코딩 되어있다.
- header
    - 토큰의 타입과 해시 알고리즘으로 구성되어 있다.
    - signature 생성시 사용되는 알고리즘을 명시(ex: RS256, HS256)
    - key rotation 을 위한 kid 라는 키를 포함할 수 있다.
    ```json
    {
      "alg": "RS256",
      "typ": "JWT"
    }
    ```
- payload
    - 클레임(claim)이라고 불리는 JSON 형태의 name/value 쌍으로 이루어진 데이터 필드를 포함하고 있다.
    - 클레임은 등록된 클레임, 공개 클레임, 비공개 클레임으로 구분된다.
        - 등록된 클레임은 [RFC 7519 에서 정의된 바](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1)에 따르면 일부 필수 요소가 있고, 선택적
          요소가 있다
      ```Bash
        {
            "iss": "https://example.com", #  발급자
            "sub": "1234567890",  #  제목
            "aud": "client_id", #  대상자
            "exp": 1311281970, #  만료 시간 (필수)
            "nbf": 1311280970, #  활성 날짜 (해당 시점이 지나기 전까지는 토큰 처리를 하지 않는다)
            "iat": 1311280970, #  발급된 날짜 (필수)
            "jti": "789789789" #  JWT 고유 식별자
        }
        ```
    - 공개 클레임은 사용자가 사용할 수 있는 [기본 제공 클레임](https://www.iana.org/assignments/jwt/jwt.xhtml)으로 새로 만드는 공개 클레임은 충돌이 방지되기 위해서
      클레임 이름을 URI 형식으로 짓는다.
    - 비공개 클레임은 사용자가 만든 클레임으로, 서버와 클라이언트가 협의하에 사용한다.
    ```json
    {
      "name": "John Doe",
      "admin": true
    }
    ```
- signature
    - Base64로 인코딩한 각각 의 header 와 payload 문자열을 header 에서 지정한 알고리즘으로 secret key 를 사용하여 해싱한 문자열이다.
    - 서버에서는 secret key 를 알고 있기 때문에, 클라이언트에서 보낸 JWT 의 header 와 payload 를 서버에서 다시 한번 해싱하여 signature 와 비교하여 토큰의 변조 여부를 확인할
      수 있다.
    - 서명 알고리즘은 크게 두가지를 사용한다
    - HS256 (HMAC with SHA-256)
        - HMACSHA256, HMACSHA384, HMACSHA512 등이 있다.
        - HMAC 은 대칭키(secret key)를 사용하여 JWT 의 header 와 payload 를 해싱(SHA256)한다.
        - JWT 를 발급한 서버측 또는 대칭키를 공유하는 장비에서만 signature 를 검증할 수 있다.

    - RS256 (RSA Signature with SHA-256)
        - RS256, RS384, RS512 등이 있다.
        - RSA 는 비대칭키 암호화 방식이다.
        - 서버는 공개키와 개인키를 가지고 있다.
        - secret key 대신 private key 를 사용하여 JWT 의 header 와 payload 를 해싱(SHA256)한다.
        - 서버는 공개키를 클라이언트에게 제공, 클라이언트는 공개키를 사용하여 JWT 의 header 와 payload 를 암호화하여 서버에 전송한다.
        - 서버는 개인키를 사용하여 JWT 의 header 와 payload 를 복호화하여 signature 와 비교하여 토큰의 변조 여부를 확인할 수 있다.
        - JWT 를 발급한 서버측과 공개키를 공유하는 장비에서도 signature 를 검증할 수 있다.
        - 공개키는 JWK (JSON WEB KEY) 에 정의된 규약에 따라 제공된다
        - 비대칭키 암호화는 각각의 공개키/개인키가 암호화한 데이터를 서로 복호화할 수 있다는 특징이 있다.
            - 공개키로 암호화한 데이터는 개인키로 복호화할 수 있다. (데이터 암호화)
            - 개인키로 암호화한 데이터는 공개키로 복호화할 수 있다. (전자서명)

## JWK (JSON Web Key)

- [RFC 7517](https://datatracker.ietf.org/doc/html/rfc7517), 2015년 5월 23일에 공개되었다.
- JWK 는 암호화 키를 JSON 형태로 표현한 것이다.
- AWS Cognito 에서는 JWK 를 사용하여 JWT 를 검증한다.
- secret key 를 사용하지 않는 RSA 암호화 방식을 사용하기 때문에 공개키를 클라이언트에게 제공할 수단이 필요하다
    - AWS Cognito 서비스를 예를 들면 JWT 발급자(AWS)는 공개키를 JWK 로 제공하되 HTTPS 를 사용하여 URL로 제공한다.
    - 클라이언트는 제공받은 JWT 를 서버에 전송한다.
    - 서버는 HTTPS 를 사용하여 URL 에 접근하여 공개키를 얻는다.
    - 공개키를 사용하여 JWT 를 검증하고, 클레임을 추출하여 인증한다
    - 이 case 의 경우 JWT 발급자는 AWS 이며 클라이언트와 서버는 공개키를 이용하여 JWT 를 검증한다.
- JWK 는 다음과 같은 요소로 구성된다.
    - kty : key type (RSA, EC, oct) - 필수
    - use : key usage, 공개키의 사용 용도 (sig(signature), enc(encryption)) - 선택
    - kid : key id
    - alg : algorithm - 선택
    - n : modulus
    - e : exponent
    - x : x coordinate
    - y : y coordinate
    - crv : curve
    - x5u : x.509 URL
    - x5c : x.509 certificate chain
    - x5t : x.509 certificate SHA-1 thumbprint
    - x5t#S256 : x.509 certificate SHA-256 thumbprint
    - key_ops : key operations
    - ext : boolean

<seealso>
    <category ref="reference">
        <a href="https://www.letmecompile.com/api-auth-jwt-jwk-explained/">API 서버 인증을 위한 JWT와 JWK 이해하기</a>
        <a href="https://docs.aws.amazon.com/ko_kr/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-verifying-a-jwt.html">Amazon Cognito - JSON 웹 토큰 확인</a>
        <a href="https://auth0.com/blog/navigating-rs256-and-jwks/">Auth0 - RS256 및 JWKS 탐색</a>
    </category>
</seealso>
