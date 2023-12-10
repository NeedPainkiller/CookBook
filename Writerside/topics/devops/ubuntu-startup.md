# Linux (Ubuntu 22.04+)

## 버젼 확인 {id="ubuntu22.04_1"}

```bash
uname -mrs

grep . /etc/*-release
cat /etc/os-release

lsb_release -a
```

### ubuntu 20.04 > 22.04 업그레이드 {collapsible="true"}

<procedure>
    <step>
        <p>현재 버젼 확인</p>
        <code-block lang="bash">
            uname -mrs
            grep . /etc/*-release
            cat /etc/os-release
            lsb_release -a
        </code-block>
    </step>
    <step>
        <p>릴리즈 타겟 확인</p>
        <code-block lang="bash">
        less /etc/update-manager/release-upgrades
        # Prompt=lts 로 지정되어 있어야 함
        </code-block>
    </step>
    <step>
        <p>업데이트 전 보류중인 패키지 확인</p>
        <code-block lang="bash">
        sudo apt-mark showhold
        # 보류 중인 패키지가 있는 경우 해제 처리
        sudo apt-mark unhold [패키지명]
        </code-block>
    </step>
    <step>
        <p>소프트웨어 패키지 최신 업데이트</p>
        <code-block lang="bash">
            # Refresh the apt repo
            sudo apt update -y
            # Apply all upgrades
            sudo apt upgrade -y
        </code-block>
    </step>
    <step>
        <p>가장 최신 배포 버전을 사용할 수 있는지 확인</p>
        <code-block lang="bash">
            sudo apt dist-upgrade
            # 불필요 패키지 제거
            sudo apt autoremove
        </code-block>
    </step>
    <step>
        <p>(원격) SSH TCP 포트 열기</p>
        <p>서버 재부팅 후 SSH 연결 불가능 이슈 대비</p>
        <code-block lang="bash">
            sudo ufw allow 22/tcp comment 'Open port ssh tcp port 1022 as failsafe option for upgrades'
            sudo ufw status
        </code-block>
    </step>
    <step>
        <p>update-manager-core 설치</p>
        <code-block lang="bash">
            sudo apt install update-manager-core
        </code-block>
    </step>
    <step>
        <p>업그레이드 진행</p>
        <code-block lang="bash">
        sudo do-release-upgrade
        #업데이트가 불가능한 경우 개발 릴리즈로 업그레이드 가능
        sudo do-release-upgrade -d
        </code-block>
    </step>
    <step>
        <p>업그레이드 후 버젼 확인</p>
        <code-block lang="bash">
            uname -mrs
            grep . /etc/*-release
            cat /etc/os-release
            lsb_release -a
        </code-block>
    </step>
</procedure>

## 패키지 업데이트 및 필수 패키지 설치 {id="ubuntu22.04_2"}

<procedure>
    <step>
        <p>패키지 저장소 업데이트 및 업그레이드</p>
        <code-block lang="bash">
             # Refresh the apt repo
            sudo apt update -y
            # Apply all upgrades
            sudo apt list --upgradable
            sudo apt upgrade -y
        </code-block>
    </step>
    <step>
        <p>필수 패키지 설치</p>
        <code-block lang="bash"> 
            sudo apt install -y openssh-server curl wget net-tools tree language-pack-ko make gcc pkg-config ca-certificates gnupg ufw gnome-terminal lsb-release apt-transport-https ufw gnome-terminal lsb-release apt-transport-https
        </code-block>
    </step>
</procedure>

## timezone 변경 {id="ubuntu22.04_3"}

<procedure>
    <step>
        <p>date & timezone 확인</p>
        <code-block lang="bash">
            date
            timedatectl
        </code-block>
    </step>
    <step>
        <p>timezone 변경</p>
        <code-block lang="bash">
            sudo timedatectl list-timezones | grep seoul
            sudo timedatectl set-timezone Asia/Seoul
            # or
            sudo ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime && echo Asia/Seoul > /etc/timezone
        </code-block>
    </step>
</procedure>

## IP 설정 변경 {id="ubuntu22.04_4"}

<procedure>
    <step>
        <p>네트워크 어댑터 확인</p>
        <sub>이더넷 또는 무선랜의 인터페이스 명 확인 (ex:ens120)</sub>
        <code-block lang="bash">
            ifconfig 
            ls /sys/class/net
            ip link
            ip addr
            ip route
            # netplan 비활성화 된 경우
            sudo netplan generate
        </code-block>
    </step>
    <step>
        <p>설정 파일 열기</p>
        <code-block lang="bash">
            # 이더넷일 경우 (파일명 다를 수 있음)
            sudo vi /etc/netplan/01-network-manager-ens120.yaml
            # 무선랜일 경우
            sudo vi /etc/netplan/01-network-manager-wifi.yaml
            # or
            sudo vi /etc/netplan/01-netcfg.yaml
        </code-block>
    </step>
    <step>
        <p>설정 파일 수정</p>
        <sub>환경에 따라 적절히 수정할 것</sub>
        <code-block lang="yaml">
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
                    addresses: [ 1.1.1.1, 8.8.8.8 ]
                  routes:
                    - to: default
                      via: 192.168.0.1
            ###
        </code-block>
    </step>
    <step>
        <p>설정 파일 적용</p>
        <code-block lang="bash">
            sudo netplan apply 
        </code-block>
    </step>
    <step>
        <p>IP 확인</p>
        <code-block lang="bash">
            ip addr
            ip route
            nslookup google.com
        </code-block>
    </step>
    <step>
        <p>서버 시작시 네트워크 연결 대기 비활성화</p>
        <code-block lang="bash">
            ## Network connection을 기다라지 않기 위해 아래와 같이 systemd-networkd-wait-online.service 서비스를 비활성화한다.
            systemctl disable systemd-networkd-wait-online.service
            ## 다른 서비스에 의해서 systemd-networkd-wait-online.service 서비스가 활성화되는 것을 막기 위해 아래와 같이 systemd-networkd-wait-online.service 서비스를 masking한다.
            systemctl mask systemd-networkd-wait-online.service
        </code-block>
</step>
</procedure>

## SSH 포트 변경 {id="ubuntu22.04_5"}
<tabs>
    <tab title="Debian (ufw)">
        <p>ubuntu 20.04 이후 권장</p>
        <code-block lang="bash">
            # sshd 설정 변경
            sudo vi /etc/ssh/sshd_config
            # sshd 서비스 재시작
            sudo service sshd restart
            # or
            sudo service ssh restart
            # 포트 확인
            netstat -tnlp
            # 포트 전환
            sudo ufw deny 22
            sudo ufw allow 10022
        </code-block>
    </tab>
    <tab title="Debian (iptables, firewalld)">
        <p>iptables, firewalld 사용 시</p>
        <code-block lang="bash">
            # sshd 설정 변경
            vi /etc/ssh/sshd_config
            # selinux off
            setenforce 0
            # sshd 서비스 재시작
            systemctl restart sshd.service
            # selinux on
            setenforce 1
            # iptables 설정 추가 및 서비스 재시작
            iptables -A INPUT -p tcp --dport 10022 -j ACCEPT
            service iptables restart
            # firewalld 설정 추가 및 서비스 재시작
            firewall-cmd --permanent --zone=public --add-port=10022/tcp
            firewall-cmd --reload
        </code-block>
    </tab>
    <tab title="RedHat / CentOS">
        <p>iptables, firewalld 사용 시</p>
        <code-block lang="bash">
            vi /etc/ssh/sshd_config
            # selinux off
            setenforce 0
            # sshd 서비스 재시작
            systemctl restart sshd.service
            # selinux on
            setenforce 1
            # firewalld 설정 추가 및 서비스 재시작
            firewall-cmd --permanent --zone=public --add-port=10022/tcp
            firewall-cmd --reload
        </code-block>
    </tab>
</tabs>

## .ssh 디렉터리 및 파일 권한 {id="ubuntu22.04_6"}

```bash
# .ssh 디렉터리 생성
mkdir ~/.ssh
# .ssh 필수 파일 생성
touch ~/.ssh
touch ~/.ssh/id_rsa
touch ~/.ssh/id_rsa.pub  
touch ~/.ssh/authorized_keys
touch ~/.ssh/known_hosts
# .ssh 디렉터리 및 파일 권한 설정
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub  
chmod 644 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/known_hosts
```

## nobody 계정생성 {id="ubuntu22.04_7"}

```bash
sudo adduser nobody
```

## su 권한 제한 {id="ubuntu22.04_8"}

<procedure>
    <step>
        <p>sudo 권한 계정 확인 및 su 전환 보안<sub>(sudo 권한 계정이 없는 경우 생략)</sub></p>
        <code-block lang="bash">
            sudo visudo
        </code-block>        
        <p>su 시 패스워드 강제 요구 <code>Defaults        rootpw</code> 구문 추가</p>
    </step>
    <step>
        <p>wheel 그룹 생성</p>
        <p>option 1 : /etc/group 직접 수정</p>
        <code-block lang="bash">
            sudo vi /etc/group
        </code-block>
        <p><code>wheel:x:10:root,[사용자ID],[사용자ID]</code> 구문 추가
        <sup>사용자ID는 여러명 지정 가능</sup>
        </p>
        <p>option 2 :  명령어로 직접 지정</p>
        <code-block lang="bash">
            ## wheel 그룹 추가 
            groupadd wheel
            ## 그룹 내 사용자 등록
            gpasswd -a 사용자ID wheel
            ## 그룹 내 사용자 삭제
            gpasswd -d 사용자ID wheel
            ## 그룹 확인
            groups 사용자ID
        </code-block>
    </step>
    <step>
        <p>wheel 그룹 한정 su 허용</p>
        <code-block lang="bash">
            vi /etc/pam.d/su
        </code-block>        
        <p><code>auth sufficient pam_wheel.so trust use_uid</code> 주석 해제 또는 구문 추가</p>
    </step>
    <step>
        <p>[/bin/su] 명령어 그룹 및 권한 변경</p>
        <code-block lang="bash">
            chown root:wheel /bin/su
            chmod 4750 /bin/su
        </code-block>
    </step>
    <step>
        <p>로컬에서 root 비밀번호 재설정</p>
        <code-block lang="bash">
            passwd
        </code-block>
    </step>
</procedure>

## 재부팅 {id="ubuntu22.04_9"}
```bash
sudo reboot now
```

#### iptables 설정 (deprecated)

```bash
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10022 -j REDIRECT --to-port 22
 
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

```

<seealso>
    <category ref="external">
        <a href="https://www.ssh.com/academy/ssh/permissions">SSH Permissions</a>
    </category>
</seealso>