# WSL

## WSL 2 설치 {id="wsl_1"}

### 배포판 확인 {id="wsl_1_1"}

```Bash
wsl -l -o
# or
wsl --list --online
```

### 설치 {id="wsl_1_2"}

```Bash
wsl --install
# WSL 2로 변경
wsl --set-default-version 2
```

- x64 머신용 최신 WSL2 Linux 커널 업데이트 패키지를 다운로드하고 설치해야 한다.
    - [설치파일](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)

```Bash
# 설치 후 업데이트
wsl --update
```

- 마이크로소프트 스토어에서 우분투 리눅스 설치 (Microsoft Store)
- 설치 후 wsl 인스턴스 확인

```Bash
wsl -l -v
```

## WSL 인스턴스 관리 {id="wsl_2"}

```Bash
# 전체 종료
wsl --shutdown

# 종료 
wsl -t [인스턴스 명]
# 시작 
wsl -d [인스턴스 명] 
```

## WSL 내 ROOT 직접 접속 {id="wsl_2_1"}

- 패스워드 에러 또는 sudo 에러가 발생할 경우

```Bash
wsl --user root
```

## 설치 후 작업 {id="wsl_3"}

- WSL 은 윈도위의 하위 시스템이기 때문에 윈도우 환경에 따라 다양한 설정이 필요하다
- WSL 자동 시작이나 포트포워딩등은 이를 위한 설정이나, 아래 설정이 모든 환경에서 정확하게 작동하는것은 보장하지 못한다
- 특히 systemd 를 사용하는 경우에는 WSL 의 기본 설정으로는 정상적으로 작동하지 않는다
- systemd 를 사용하기 위해 WSL 의 /etc/wsl.conf 파일을 수정하더라도 정상 작동을 보장하지 않으며
- 특히 SSHD 서비스의 자동시작이 불가능하여 [서버로서의 제 역할을 기대하기 어렵다](https://gist.github.com/dentechy/de2be62b55cfd234681921d5a8b6be11)
- 그러니까 WSL 은 개발용으로만 사용하되, 프로덕션에서의 문제를 피하기 위해 가급적이면 운영계에서 사용하지 않는것이 좋다

#### 외부 DNS 서버 지정 {id="wsl_3_1"}

- 리눅스에서는 /etc/resolv.conf 파일에 DNS 서버를 관리한다.
    - WSL 의 기본 DNS 주소는 172.19.96.1 이다
    - WSL 이 자동 생성한 파일이므로 외부 DNS 를 사용하려면 설정을 해주어야 한다
- /etc/wsl.conf 파일을 생성하고 아래 내용을 추가한다

```Bash
[network]
generateResolvConf=false
```

- WSL 을 재시작한다
- /etc/resolv.conf 파일을 생성 또는 열어서 nameserver 를 작성한다

```Bash
nameserver 1.1.1.1
```

- 다시 WSL 을 재시작한다
- WSL 의 DNS 서버가 외부 DNS 로 변경 되었음을 확인한다

```Bash
nslookup google.com
```

#### 기본 사용자 변경 {id="wsl_3_2"}

- WSL 은 기본 사용자가 root 이다

```Bash
wsl -d [인스턴스 명] whoami
```

- 사용자를 추가하고 그룹을 지정한다

```Bash
# 사용자 생성 
sudo useradd -m -s /bin/bash <USERNAME>
# 사용자 비밀번호 설정
sudo passwd <USERNAME>
# 사용자를 sudo 그룹에 추가(관리자 권한 추가)
sudo usermod -aG sudo <USERNAME>
```

- /etc/wsl.conf 파일을 생성하고 아래 내용을 추가한다

```Bash
[user]
default=<USERNAME>
```

#### 윈도우 부팅 시 WSL 자동 실행 {id="wsl_3_3"}

- WSL은 일반적인 가상머신과 달리 윈도우의 Hyper-V 아키텍처 기반으로 동작한다
- 윈도우 부팅 시 WSL 을 자동으로 실행하려면 아래와 같이 설정한다
<procedure>
  <step>
    <p>WSL 기본 인스턴스를 설정</p>
    <code-block language="bash">
      wsl --setdefault [인스턴스 명]
    </code-block>
  </step>
  <step>
    <p>윈도우 부팅 자동 실행 bat 파일 만들기</p>
    <code-block language="Console">
      @echo off
      wsl --exec dbus-launch true & bash
    </code-block>
    <p><control>shell:startup</control> 윈도우 시작 폴더에 <control>wsl-startup.bat</control> 으로 저장</p>
    <p>또는 작업 스케쥴러에 등록하여 PC 시작시 자동 실행되도록 하자</p>
  </step>
</procedure>

- 위 설정도 WSL 의 구성요소가 바뀌거나 관리자 권한 이상등으로 인해 정상 작동하지 않을 가능성이 있다.
- 되도록이면 WSL 말고 다른 가상머신을 사용하거나 Ubuntu 서버를 설치하여 사용하는것이 좋다

#### WSL 환경에서 SSH 접속 {id="wsl_3_4"}

- WSL 내 OpenSSH 설치

```Bash
sudo apt update -y
sudo apt install ssh -y
```
- WSL 내 SSH 서비스 자동 시작
  - WSL 은 기본으로 systemd 를 지원하지 않기 때문에 위의 "ssh 서비스 자동 시작" 이 적용되지 않는다.
  - WSL 에서 systemd 를 사용하기 위해서는 systemd 환경으로 부팅하도록 설정을 바꾸어야 하나, 이는 WSL 의 정상 작동을 보장하지 않는다.
  - /etc/wsl.conf 파일을 생성하고 아래 내용을 추가한다
  ```Bash
  [boot]
  command="service ssh start" 
  ```

#### WSL 포트포워딩 {id="ssh_3_5"}

- WSL 은 Windows 환경 내에서 internal 한 IP 를 가진다
- WLS 의 내부 IP 를 찾아 포워딩을 해주어야 한다.

```Bash
netsh interface portproxy add v4tov4 listenaddress=[Host IP] listenport=10022 connectaddress=[Docker IP] connectport=22
```

- 더 좋은 방법으로 아래 파워쉘 스크립트를 실행하면 WSL 의 내부 IP 를 찾아 포워딩을 해준다.
- 스케쥴러 또는 자동실행을 걸어두자

```bash
$remoteport = bash.exe -c "ifconfig eth0 | grep 'inet '"
$found = $remoteport -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

if( $found ){
  $remoteport = $matches[0];
} else{
  echo "The Script Exited, the ip address of WSL 2 cannot be found";
  exit;
}

#[Ports]
#All the ports you want to forward separated by coma
$ports=@(10022);

#[Static ip]
#You can change the addr to your ip config to listen to a specific address
$addr='0.0.0.0';
$ports_a = $ports -join ",";

#Remove Firewall Exception Rules
iex "Remove-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' ";

#adding Exception Rules for inbound and outbound Rules
iex "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Outbound -LocalPort $ports_a -Action Allow -Protocol TCP";
iex "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Inbound -LocalPort $ports_a -Action Allow -Protocol TCP";

for( $i = 0; $i -lt $ports.length; $i++ ){
  $port = $ports[$i];
  iex "netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$addr";
  iex "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$addr connectport=$port connectaddress=$remoteport";
}
Invoke-Expression "netsh interface portproxy show v4tov4";
```

- 포트 포워딩 확인

```Bash
netsh interface portproxy show v4tov4
```

- 추가로 Inbound 규칙을 윈도우 방화벽 설정에서 추가해주어야 한다

```Bash
# 방화벽 설정 추가
New-NetFireWallRule -DisplayName 'WSL Ubuntu SSH 10022 Open' -Direction Outbound -LocalPort 10022 -Action Allow -Protocol TCP
New-NetFireWallRule -DisplayName 'WSL Ubuntu SSH 10022 Open' -Direction Inbound -LocalPort 10022 -Action Allow -Protocol TCP
# 방화벽 설정 확인
Get-NetFirewallRule -DisplayName 'WSL Ubuntu SSH 10022 Open' | Get-NetFirewallPortFilter | Format-Table
```

- 포트포워딩 및 방화벽 삭제 방법은 다음과 같다

```Bash
netsh interface portproxy delete v4tov4 listenaddress=192.168.1.107 listenport=10022 
Remove-NetFirewallRule -DisplayName 'WSL Ubuntu SSH 10022 Open'
```

## 메모리 설정 {id="wsl_4"}

- WSL 은 "Vmmem" 이라는 프로세스 상에서 동작한다
- [공식 Document](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#main-wsl-settings) 의 서술에 따르면 총 메모리의 50% ~ 80% (
  특정 빌드 전 단계) 를 사용한다고 한다
- ```%USERPROFILE%``` 경로에 .wslconfig 파일을 생성하고 아래 내용을 추가한다 {ignore-vars="true"}

```Bash
[wsl2]
memory=4GB
processors=2
swap=1GB
localhostForwarding=true
```

- WSL 을 재시작한다.

```Bash
# 종료 
wsl --shutdown
# 시작 
wsl -d [인스턴스 명]  
```

## Issue {id="wsl_5"}

### WSL 미확인 종료 이슈

- [로컬 윈도우 장비에서 WSL 에 접속하고 있으면 정상적으로 작동하나, 쉘에서 나가거나 로그아웃 하는 경우, 일정 시간 뒤 WSL 이 종료되는 이슈가 있다](https://github.com/microsoft/WSL/issues/9968)
- 만약 systemd (systemctl) 을 위해 wsl.conf 파일을 수정 하였다면, 아래와 같이 systemd 를 비활성화 하여야 한다.

<code-block lang="bash">
# /etc/wsl.conf
[boot]
systemd=false
</code-block>

## WSL 에 대한 나의 견해 {id="wsl_6"}
- WSL 은 윈도우 사용자에게 있어서 Linux 시스템을 활용할 수 있도록 하는 강력한 도구이다
- 하지만 WSL 은 Linux 시스템이 아니다, 윈도우의 하위 시스템이다. 이는 모든 Linux 시스템의 기본적인 동작 방식과 다르다
- WSL 은 윈도우의 하위 시스템이기 때문에 윈도우의 하위 시스템의 제약사항을 모두 가지고 있다
- 필자는 약 WSL 1 부터 약 4년 간 WSL 을 사용해왔다, WSL 을 통해 나의 Linux 경험은 크게 향상되었고, 개발자로서 윈도우에서도 Linux 의 편리함을 누릴 수 있었다.
- 하지만 WSL 은 Linux 시스템이 아니기 때문에, WSL 을 사용하면서 겪었던 다양한 문제들을 해결하기 위해 많은 시간을 투자해야 했다.
- Docker, Kubernetes, Git, SSH, systemd, cron 등등 Linux 의 기본적인 동작 방식과 다른 부분들이 WSL 을 사용하면서 많은 개발 경험을 망가트렸다.
- 패키지 및 라이브러리 가 파일 시스템에서 충돌이 발생한다던가, 네트워크가 정상 작동하지 않는 부분 등 개발자의 시간을 뺐는건 WSL 자체의 문제만으로도 충분했다. 
- WSL 은 Deveopment/Stage/Production 환경에서 사용하기에는 적합하지 않다. Local 개발 환경에서의 사용은 추천하나, 환경상의 문제를 겪고 있다면 시간 깎지 말고 물리적인 Linux 시스템을 사용하자.
<img src="wsl_in_a_nut_shell.png" alt=""/>

<seealso>
    <category ref="official">
        <a href="https://docs.microsoft.com/ko-kr/windows/wsl/install-win10#step-4---download-the-linux-kernel-update-package">WSL을 사용하여 Windows에 Linux를 설치하는 방법</a>
        <a href="https://docs.microsoft.com/ko-kr/windows/wsl/wsl-config">WSL 구성</a>
    </category>
    <category ref="reference">
        <a href="https://www.lainyzine.com/ko/article/how-to-install-wsl2-and-use-linux-on-windows-10/">[Windows] WSL 설치 및 사용법</a>
        <a href="https://www.lainyzine.com/ko/article/how-to-run-ssh-server-on-wsl/">WSL 리눅스에서 SSH 서버 자동 실행하는 법</a>
        <a href="https://www.lainyzine.com/ko/article/fix-wsl2-ip-by-virtual-switch/">WSL에서 IP 고정하는 방법(가상 스위치)</a>
        <a href="https://www.lainyzine.com/ko/article/how-to-use-nvidia-gpu-cuda-on-wsl-linux/">WSL에서 NVIDIA GPU 사용하는 방법</a>
    </category>
</seealso>