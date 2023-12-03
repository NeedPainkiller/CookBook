# 리눅스 최초 세팅 (Ubuntu 22.04 기준)

## 버젼 확인
```bash
grep . /etc/*-release
```

## 패키지 업데이트
```bash
sudo apt update -y
sudo apt list --upgradable
sudo apt upgrade -y

# 필수 패키지
sudo apt install -y openssh-server curl wget net-tools tree language-pack-ko make gcc pkg-config ca-certificates gnupg ufw gnome-terminal lsb-release apt-transport-https 
```

## timezone 변경
```bash
# date & timezone 확인
date
timedatectl

# timezone 변경
sudo timedatectl list-timezones | grep seoul
sudo timedatectl set-timezone Asia/Seoul

# or
sudo ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime && echo Asia/Seoul > /etc/timezone
```
## IP 설정 변경
```bash
# 네트워크 어댑터 확인 > 이더넷 또는 무선랜의 인터페이스 명 확인 (ex:ens120)
ifconfig 
ls /sys/class/net
ip link
ip addr
ip route

# yaml 파일은 ensxxx 의 xxx 값을 구분할 것
sudo vi /etc/netplan/01-network-manager-all.yaml
# or
sudo vi /etc/netplan/01-netcfg.yaml

# netplan 없을 경우
sudo netplan generate
```

```yaml
###
# This is the network config written by 'subiquity'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:
      dhcp4: no
      dhcp6: no
      addresses:
        - 192.168.0.12/24
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
      routes:
        - to: default
          via: 192.168.0.1
###
```

```bash
# 설정 업데이트
sudo netplan apply 

# IP 확인
ip addr
ip route
nslookup google.com


##
## Network connection을 기다라지 않기 위해 아래와 같이 
## systemd-networkd-wait-online.service 서비스를 비활성화한다.
##
systemctl disable systemd-networkd-wait-online.service

##
## 다른 서비스에 의해서 systemd-networkd-wait-online.service 서비스가 활성화되는 것을 막기 위해
## 아래와 같이 systemd-networkd-wait-online.service 서비스를 masking한다.
##
systemctl mask systemd-networkd-wait-online.service
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

# 4. 이후 로컬에서 root 비밀번호 재설정
```

## 재부팅
```bash
sudo reboot now
```


#### iptables 설정 (deprecated)
```bash
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10022 -j REDIRECT --to-port 22
 
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

```