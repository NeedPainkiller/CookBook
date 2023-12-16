# SSH

## ssh 설치 및 초기 설정 {id="ssh_1"}

<procedure xmlns="">
    <step>
        <p>ssh 설치</p>
        <code-block lang="shell">
            sudo apt update -y
            sudo apt list --upgradable
            sudo apt upgrade -y
            sudo apt install -y openssh-server
        </code-block>
    </step>
    <step>
        <p>.ssh 디렉터리 생성 & 권한 업데이트</p>
        <code-block lang="shell">
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
        </code-block>
    </step>
    <step>
        <p>ssh 포트 변경</p>
        <code-block lang="bash">
            # sshd 설정 변경
            sudo vi /etc/ssh/sshd_config
            ---
            # sshd 서비스 재시작
            sudo service sshd restart
            # or
            sudo service ssh restart
            # or
            sudo service ssh --full-restart
            ---
            # 포트 확인
            netstat -tnlp
            ---
            # 포트 전환
            sudo ufw deny 22
            sudo ufw allow 10022
        </code-block>
    </step>
    <step>
        <p>ssh 서비스 자동 시작</p>
        <code-block lang="bash">
            sudo systemctl enable ssh
            # or
            sudo systemctl enable ssh.service
            # or
            sudo update-rc.d ssh defaults
            sudo systemctl enable ssh.socket
        </code-block>
    </step>
</procedure>

### /etc/ssh/sshd_config 파일 설정 {id="ssh_1_1"} {collapsible="true"}

```bash
# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

Port 10022
#AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
#PermitRootLogin prohibit-password
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication yes
#PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
KbdInteractiveAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the KbdInteractiveAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via KbdInteractiveAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and KbdInteractiveAuthentication to 'no'.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem       sftp    /usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#       X11Forwarding no
#       AllowTcpForwarding no
#       PermitTTY no
#       ForceCommand cvs server
```

## ssh 키 생성 {id="ssh_2"}

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# 패스워드 지정 권장
```

- RSA 대신 Ed25519 암호 알고리즘을 권장
- 이후 .ssh 의 ```id_ed25519``` 개인 키와 ```id_ed25519.pub``` 공개 키 생성됨
- 개인 키, 공개 키 백업 필수
- ```id_ed25519.pub``` 공개 키의 파일 내용을 복사하여 Github 등의 ssh 인증이 필요한 서비스에 등록하여 사용

#### Ed25519 암호 알고리즘을 사용하는 이유 {collapsible="true"}

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

<seealso>
    <category ref="reference">
        <a href="https://jackcokebb.tistory.com/18">WSL 외부 접속 설정하기 - ssh, 포트포워딩</a>
    </category>
</seealso>