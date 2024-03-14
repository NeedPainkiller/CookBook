# UFW (Uncomplicated Firewall) 설정

## 설명 {id="ufw_1"}
- Linux 커널의 패킷 필터링 시스템 [Netfilter](https://netfilter.org/) 를 사용하는 방화벽
- 기존 iptables, nftables 등이 이를 지원하였으며, 방화벽 계층의 기능을 추상화하여 사용하기 쉽게 만들었다
- UFW 는 모든 Linux 배포판에서 사용 가능하며, GUI 도구인 gufw 가 있다
- Ubuntu 배포판에는 기본적으로 비활성화되어 있으며, 활성화 후 설정을 추가해야 한다

## 명령어 {id="ufw_2"}
### 서비스 관리 {id="ufw_2_1"}
```Bash
# 상태 확인
sudo ufw status verbose 

# 활성화
sudo ufw enable

# 비활성화
sudo ufw disable

# 초기화
sudo ufw reset

# 로깅 설정 (기본값은 off)
## 로그를 활성화 할 경우 로그 파일은 /var/log/ufw.log 에 저장된다
## 연결 수에 따라 로그 용량이 증가하기 때문에 모니터링 외 상황에서는 비활성화 한다
sudo ufw logging off
sudo ufw logging on

```
### 규칙 설정 {id="ufw_2_2"}

#### UFW 기본 규칙 {id="ufw_2_2_1"}
```Bash
## 들어오는 트래픽 일괄 거부
sudo ufw default deny incoming
## 나가는 트래픽 일괄 허용
sudo ufw default allow outgoing
```
#### 응용프로그램, 서비스별 규칙 설정 {id="ufw_2_2_2"}
```Bash
#  열린 포트가 필요한 응용 프로그램 확인
sudo ufw app list
## 응용프로그램 별 포트 사용 확인
sudo ufw app info "응용프로그램 명"
## 특정 응용프로그램 허용
sudo ufw allow "응용프로그램 명"

## 서비스별 허용
sudo ufw allow [서비스명]
## 지원되는 서비스 확인
sudo cat /etc/services
```

#### 포트별 규칙 설정 {id="ufw_2_2_3"}
```Bash
# 특정 포트 허용
sudo ufw allow [포트번호]

# 특정 포트 허용 (프로토콜 지정)
sudo ufw allow [포트번호/프로토콜]

# 특정 포트 범위허용
sudo ufw allow [포트번호시작:포트번호끝/프로토콜]

# 모든 규칙 조회 (규칙 번호 포함) 
sudo ufw status numbered

# 특정 규칙 삭제
sudo ufw delete [규칙번호]
```

#### IP 주소별 규칙 설정 {id="ufw_2_2_4"}
```Bash
# 특정 IP 주소 허용
sudo ufw allow from [IP주소] proto tcp to any port [포트번호]
```
#### 연결 수 제한 {id="ufw_2_2_5"}
- 특정 IP 주소로부터 들어오는 SSH 연결이 30초에 6번을 초과하면 30초 ~ 1분간 차단 (브루트 포스 공격 방지)
```Bash
ufw limit ssh
```

### 포트 포워딩{id="ufw_2_3"}

#### 패킷전달 활성화 {id="ufw_2_3_1"}
- 포트 간 패킷을 전송을 허용하도록 설정
- 패킷 전달을 위해서는 커널 설정을 변경해야 한다
  - UFW 네트워크 변수 파일: /etc/ufw/sysctl.conf
  - 시스템 변수 파일: /etc/sysctl.conf
  - UFW 네트워크 변수 파일이 [시스템 변수 파일보다 우선순위를 가지므로](https://manpages.ubuntu.com/manpages/xenial/man8/ufw-framework.8.html) UFW 네트워크 변수 파일을 수정한다
```Bash
# 패킷 전달 활성화
sudo vi /etc/ufw/sysctl.conf
# net.ipv4.ip_forward=1 의 주석 해제 또는 추가
```

#### UFW 포트 포워딩 설정 {id="ufw_2_3_2"}

- 포트 포워딩을 위해서는 `/etc/default/ufw` 파일의 `DEFAULT_FORWARD_POLICY` 값을 `ACCEPT` 로 변경해야 한다
```Bash
# 포트 포워딩 설정
sudo vi /etc/default/ufw
# DEFAULT_FORWARD_POLICY="ACCEPT"
```

- 규칙 파일 조회
```Bash
sudo vi /etc/ufw/before.rules 
```
- nat 테이블 추가 (80 포트를 500 포트로 포워딩 설정)
```Bash
*nat
:PREROUTING ACCEPT [0:0]
-A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 500
COMMIT
```
  - 예시
  ```Bash
  -A ufw-before-forward -i enp5s0 -p tcp -d 172.20.0.10 --dport 10080 -j ACCEPT
  -A ufw-before-forward -i enp5s0 -p tcp -d 172.20.0.10 --dport 10443 -j ACCEPT
  
  COMMIT
  
  *nat
  :PREROUTING ACCEPT [0:0]
  #-A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 0.0.0.0:10080
  #-A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 0.0.0.0:10443
  
  #-A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 10080
  #-A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 10443
  
  -A PREROUTING -i enp5s0 -p tcp --dport 80 -j DNAT --to-destination 172.20.0.10:10080
  -A PREROUTING -i enp5s0 -p tcp --dport 443 -j DNAT --to-destination 172.20.0.10:10443
  
  #-A ufw-before-forward -i enp5s0 -p tcp -d 172.20.0.10 --dport 10080 -j ACCEPT
  #-A ufw-before-forward -i enp5s0 -p tcp -d 172.20.0.10 --dport 10443 -j ACCEPT
  
  -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-port 10053
  -A PREROUTING -p udp --dport 53 -j REDIRECT --to-port 10053
  -A PREROUTING -p udp --dport 67 -j REDIRECT --to-port 10067
  -A PREROUTING -p tcp --dport 853 -j REDIRECT --to-port 10853
  -A PREROUTING -p udp --dport 853 -j REDIRECT --to-port 10853
  
  # don't delete the 'COMMIT' line or these rules won't be processed
  COMMIT 
  ```
- https://serverfault.com/questions/532569/how-to-do-port-forwarding-redirecting-on-debian
```Bash
iptables -A PREROUTING -t nat -i eth3 -p tcp --dport 1234 -j DNAT --to-destination 192.168.57.25:80
iptables -A FORWARD -p tcp -d 192.168.57.25 --dport 80 -j ACCEPT
iptables -A POSTROUTING -t nat -s 192.168.57.25 -o eth3 -j MASQUERADE
```

- UFW 재시작
```Bash
sudo ufw reload
```
##### 특정  내부IP 주소로 포트 포워딩 {id="ufw_2_3_3"}- 규칙 파일 조회
```Bash
sudo vi /etc/ufw/before.rules 
```
- nat 테이블 추가 (443 포트를 192.168.56.9:500 로 포워딩 설정)
```Bash
*nat 
:PREROUTING ACCEPT [0:0]
-A PREROUTING -p tcp -i eth0 --dport 443 -j DNAT \ --to-destination 192.168.56.9:600
COMMIT
```
- UFW 재시작
```Bash
sudo ufw reload
```






