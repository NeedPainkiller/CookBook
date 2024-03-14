# Fail2Ban


## SSH 접근 시도 확인하기
```Bash
sudo last -10 -f /var/log/btmp
```

## Fail2Ban 설치 및 서비스 활성화 {id="fail2ban_1"}

<procedure xmlns="">
    <step>
        <p>fail2ban 설치</p>
        <tabs>
            <tab title="RHEL/CentOS/Oracle/Amazon">
                <code-block lang="bash">
                    # EPEL (Extra Packages for Enterprise Linux yum) 추가 저장소 설치
                    sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                    # fail2ban  설치
                    sudo yum --enablerepo epel install fail2ban
                </code-block>
            </tab>
            <tab title="Ubuntu">
                <code-block lang="bash">
                    sudo apt install fail2ban
                </code-block>
            </tab>
        </tabs>
    </step>
    <step>
        <p>버젼 확인</p>
        <code-block lang="shell">
            fail2ban-client --version
            sudo fail2ban-client status
        </code-block>
    </step>
    <step>
        <p>서비스 활성화</p>
        <code-block lang="shell">
            sudo systemctl enable fail2ban
            sudo systemctl restart fail2ban
        </code-block>
    </step>
</procedure>

## 초기 설정 {id="fail2ban_2"}

- 기본 설정은 /etc/fail2ban/jail.conf 파일에 있으나, 이 파일은 수정하지 않는 것이 좋음
- 개인 설정 으로 /etc/fail2ban/jail.local 파일을 생성하여 설정을 변경하는 것이 좋음
<code-block lang="shell">
[DEFAULT]
# ignoreip: 로그인 실패를 무시할 IP 주소
ignoreip = 127.0.0.1/8 192.168.0.0/24
# bantime: 로그인 실패시 차단 시간
bantime  = -1
# findtime: 로그인 실패로 인식할 시간
findtime  = 1d
# maxretry: 로그인 실패 횟수
maxretry = 10
# backend: 사용할 backend
backend = systemd
# action: 차단시 실행할 액션
#action = %(action_mw)s # 메일을 전송하고 whois 로 IP 정보를 조회한 결과를 첨부
#action = %(action_mwl)s # 메일을 전송하고 whois 로 IP 정보를 조회한 결과와 관련된 로그를 첨부
# loglevel: 로그 레벨
loglevel = INFO
# banaction: 차단시 실행할 액션
banaction = iptables-multiport
[sshd]
enabled = true
port = ssh,10022
filter = sshd
logpath = /var/log/fail2ban-ssh.log
</code-block>
- 서비스 재시작
<code-block lang="shell">
sudo systemctl restart fail2ban
sudo systemctl status fail2ban
</code-block>

## 명령어 {id="fail2ban_3"}
- 차단된 IP 확인
```Bash
sudo fail2ban-client status sshd
```
- IP 차단 해제
```Bash
sudo fail2ban-client set sshd unbanip [IP]
```
- IP 차단 추가
```Bash
sudo fail2ban-client set sshd banip [IP]
```
- 로그 확인
```Bash
sudo tail -f /var/log/fail2ban-ssh.log
```

### /etc/fail2ban/jail.local 파일 생성 {id="fail2ban_2_1"}

<seealso>
    <category ref="reference">
        <a href="https://jackcokebb.tistory.com/18">WSL 외부 접속 설정하기 - ssh, 포트포워딩</a>
    </category>
</seealso>