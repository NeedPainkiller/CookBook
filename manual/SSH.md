# SSH 설정 생성 가이드라인
## .ssh 및 기본 파일 생성, 권한 업데이트
```bash
mkdir ~/.ssh

touch ~/.ssh
touch ~/.ssh/id_rsa
touch ~/.ssh/id_rsa.pub  
touch ~/.ssh/authorized_keys
touch ~/.ssh/known_hosts

chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub  
chmod 644 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/known_hosts
```
## ssh 키 생성
- RSA 대신 Ed25519 암호 알고리즘을 권장함
    - SHA-512 및 Curve25519를 사용한 EdDSA 서명 체계
    - 빠른 단일 서명 확인 (Fast single-signature verification)
    - 매우 빠른 배치 검증 (Even faster batch verification)
    - 빠른 키 생성(Fast key generation)
    - 높은 보안 수준(High security level)
    - 완전 방지 세션 키(Foolproof session keys)
    - 충돌 탄력성(Collision resilience)
    - 비밀 배열 인덱스가 없음(No secret array indices)
    - 비밀 지점 조건이 없음(No secret branch conditions)
    - 작은 서명(Small signatures)
    - 작은 키(Small keys)
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# 패스워드 지정 권장
```

- 이후 .ssh 의 ```id_ed25519``` 개인키와 ```id_ed25519.pub``` 공개키를 발급 받을수 있음
- 백업 필수
- ```id_ed25519.pub``` 공개키를 Github 등의 저장소에 등록하여 사용하면 된다