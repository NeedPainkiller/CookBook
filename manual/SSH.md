# SSH 설정 생성 가이드라인
## .ssh 생성 및 기본 파일 생성
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
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```
