# 리눅스 최초 세팅 (Ubuntu 22.04 기준)

## 버젼 확인
```bash
grep . /etc/*-release
```

## 패키지 업데이트
```bash
sudo apt update -y
sudo apt upgrade -y

# 필수 패키지
sudo apt install -y openssh-server curl wget net-tools tree language-pack-ko make gcc pkg-config ca-certificates curl gnupg gnome-terminal lsb-release apt-transport-https lsb-release
```

## timezone 변경
```bash
ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime && echo Asia/Seoul > /etc/timezone
```

## SSH 포트 변경 (ufw)
```bash
sudo vi /etc/ssh/sshd_config 

sudo service sshd restart
# or
sudo service ssh restart
# 포트 확인
netstat -tnlp
# 포트 전환
sudo ufw deny 22
sudo ufw allow 10022
```
### redhat
```bash
vi /etc/ssh/sshd_config
# selinux off
setenforce 0

systemctl restart sshd.service

# selinux on 
setenforce 1

firewall-cmd --permanent --zone=public --add-port=10022/tcp
firewall-cmd --reload
```

### debian
```bash
vi /etc/ssh/sshd_config
# selinux off
setenforce 0

systemctl restart sshd.service

# selinux on 
setenforce 1

iptables -A INPUT -p tcp --dport 10022 -j ACCEPT
service iptables restart

firewall-cmd --permanent --zone=public --add-port=10022/tcp
firewall-cmd --reload
```

## .ssh 디렉터리 및 파일 권한
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub  
chmod 644 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/known_hosts
```


## nobody 계정생성
```bash
sudo adduser nobody

```

### su 제한
```bash
# sudo 권한 계정 확인 및 su 전환 보안
# 1. su 시 패스워드 강제 요구 `Defaults        rootpw` 구문 추가
sudo visudo

# wheel 그룹 한정 su 적용 방법
# 1. [/etc/pam.d/su] 파일 > `auth sufficient pam_wheel.so trust use_uid` 주석 해제 또는 구문 추가
vi /etc/pam.d/su

# 2. option 1 - [/etc/group] 파일 > `wheel:x:10:root,[사용자ID],[사용자ID]` 구문 추가
vi /etc/group
# 2. option 2 -  명령어로 직접 지정
## wheel 그룹 추가 
groupadd wheel
## 그룹 내 사용자 등록
gpasswd -a 사용자ID wheel
## 그룹 내 사용자 삭제
gpasswd -d 사용자ID wheel
## 그룹 확인
groups 사용자ID


# 3. [/bin/su] 명령어 그룹 및 권한 변경
chown root:wheel /bin/su
chmod 4750 /bin/su
```


# Docker 설치
```bash
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker ${USER}

sudo curl -L "https://github.com/docker/compose/releases/download/2.17.2/dockercompose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```


### windows ssh pem permision
```cmd
icacls.exe xxx.pem /reset
icacls.exe xxx.pem /grant:r %username%:(R)
icacls.exe xxx.pem /inheritance:r
```


## pyenv
```bash
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev

git clone https://github.com/pyenv/pyenv.git ~/.pyenv
​
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
source ~/.bash_profile
```
