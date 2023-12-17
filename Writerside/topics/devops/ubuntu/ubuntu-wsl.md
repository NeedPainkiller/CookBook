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
- CMD 에서 shell:startup 을 입력하면 윈도우 부팅 시 자동 실행되는 폴더로 이동한다
-  wsl-startup.bat 스크립트를 작성하여 저장한다
```Bash
wsl -d [인스턴스 명]
```

#### WSL 환경에서 SSH 접속 {id="wsl_3_4"}
- WSL 내 OpenSSH 설치
```Bash
sudo apt update -y
sudo apt install ssh -y
```
- WSL 은 기본으로 systemd 를 지원하지 않기 때문에 위의 "ssh 서비스 자동 시작" 이 적용되지 않는다.
- WSL 에서 systemd 를 사용하기 위해서는 systemd 환경으로 부팅하도록 설정을 바꾸어야 한다

```Bash
# /etc/wsl.conf
[boot]
systemd=true
```
- WSL 을 재시작한다
```Bash
# 종료 
wsl -t [인스턴스 명]
# 시작 
wsl -d [인스턴스 명]  
```

### WSL 포트포워딩 {id="ssh_3_5"}
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

<seealso>
    <category ref="official">
        <a href="https://docs.microsoft.com/ko-kr/windows/wsl/install-win10#step-4---download-the-linux-kernel-update-package">WSL을 사용하여 Windows에 Linux를 설치하는 방법</a>
    </category>
    <category ref="reference">
        <a href="https://www.lainyzine.com/ko/article/how-to-install-wsl2-and-use-linux-on-windows-10/">[Windows] WSL 설치 및 사용법</a>
        <a href="https://www.lainyzine.com/ko/article/how-to-run-ssh-server-on-wsl/">WSL 리눅스에서 SSH 서버 자동 실행하는 법</a>
        <a href="https://www.lainyzine.com/ko/article/fix-wsl2-ip-by-virtual-switch/">WSL에서 IP 고정하는 방법(가상 스위치)</a>
        <a href="https://www.lainyzine.com/ko/article/how-to-use-nvidia-gpu-cuda-on-wsl-linux/">WSL에서 NVIDIA GPU 사용하는 방법</a>
    </category>
</seealso>