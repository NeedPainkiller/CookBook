# Podman

## 개요 {id="podman_1"}

- Docker 와 호환되는 모듈식 컨테이너 엔진
- Podman 은 Pod Manager tool 이라는 의미로 OCI (Open Container Initiative) 컨테이너를 개발하고 관리하고 실행하도록 도와주는 컨테이너 엔진
- RHEL 8과 CentOS 8부터는 Docker 대신 Podman을 기본 제공한다

### Docker 와의 차이점 {id="podman_1_1"}

- 특징
    - rootless 모드로 실행 가능하다.
    - daemon 프로세스가 없다.
    - Pod 단위로 컨테이너를 관리한다.
- Docker 는 Docker CLI 를 통해 Docker Daemon (containerd) 을 제어한다. Docker 데몬은 Registry 에서 이미지를 다운로드 받아서 컨테이너를 생성하고 관리한다.
    - Docker 데몬이 기본적으로 root 권한으로 실행되기 때문에 Docker 데몬에 취약점이 발견되면 시스템에 치명적인 영향을 줄 수 있다.
    - Docker 데몬이 죽으면 컨테이너를 관리할 수 없게 되고 이는 컨테이너의 장애로 이어질 수 있다. 시스템의 SPoF(Single Point of Failure)가 되는 것이다

<img src="docker-cli-ecosystem.png" alt="Docker 의 컨테이너 관리 방식"/>
- Podman은 데몬을 사용하지 않으며 리눅스 Kernel의 기능을 사용하여 컨테이너를 관리한다.
    - 리눅스 Kernel 과의 연동을 위해 runC라는 OCI 컨테이너 런타임을 fork/exec으로 생성한다 (Go 언어 기반)
    - Podman은 rootless 모드로 실행되기 때문에 root 권한이 없어도 컨테이너를 관리할 수 있다.
    - Podman은 security-enhanced linux(SELinux) 레이블이 있는 각 컨테이너를 실행하여 관리자가 컨테이너 프로세스에 제공되는 리소스와 기능을 제어할 수 있도록 권한을 부여할 수 있다
    - Podman은 Docker와 달리 Pod 단위로 컨테이너를 관리한다. Pod는 하나 이상의 컨테이너를 포함하는 단위이다. Podman은 Pod를 사용하여 컨테이너를 관리한다.
    - Podman은 Docker와 달리 데몬(containerd)이 없기 때문에 컨테이너를 관리하는 데몬이 죽어도 컨테이너는 정상적으로 동작한다.
    - 데몬을 사용하지 않으므로 보안을 강화하고 유휴 리소스 사용을 줄일 수 있다.
    - 대신에 Podman 은 systemd 를 통해 서비스를 생성, 관리한다
<img src="podman-ecosystem.png" alt="Podman 의 컨테이너 관리 방식"/>
- Docker build 를 Podman 은 buildah 로 대체하고, Docker push 는 skopeo 로 대체한다. (물론 Docker 와 호환된다)
- [Docker-Desktop 의 유료화 정책](https://www.docker.com/blog/updating-product-subscriptions/)에 대응해 제시된 대안 (250인 이상 사업장 유료화)
    - Docker CLI, Docker Engine 등 기본 구성 요소는 오프소스로 관리되기 때문에 Linux 에서 구동 가능한 Docker Engine 을 Mac/Windows 에서 구동 가능하게 만든
      Docker-Desktop 이 유료화 된 것

- 유저스페이스의 체크포인트/복원(CRIU) 기능을 사용하여 컨테이너에 체크포인트/복원 기능을 적요하여 기존 런타임을 그대로 시작할 수 있다.
    - CRIU는 실행 중인 컨테이너를 중지하고 메모리 콘텐츠 및 상태를 디스크에 저장하여 컨테이너화된 워크로드를 더 빠르게 재시작할 수 있도록 한다. 

## 설치 {id="podman_2"}

## Podman {id="podman_2_1"}
<tabs>
    <tab title="RHEL/CentOS/Oracle/Amazon">
        <code-block lang="bash">
            sudo yum install podman -y
        </code-block>
    </tab>
    <tab title="Ubuntu">
        <code-block lang="bash">
            sudo apt-get install runc -y
            sudo apt-get install podman -y
        </code-block>
    </tab>
    <tab title="MacOS">
        <code-block lang="bash">
            brew install podman
            podman machine init
            podman machine start
            # podman-desktop 설치
            brew install podman-desktop
        </code-block>
    </tab>
</tabs>

- 버젼 확인
```Bash
podman -v
```

## Podman Compose {id="podman_2_2"}
<tabs>
    <tab title="RHEL/CentOS/Oracle/Amazon">
        <code-block lang="bash">
            sudo yum install python3-pip -y
            # or
            sudo -H pip3 install --upgrade pip
            sudo pip3 install podman-compose
        </code-block>
    </tab>
    <tab title="Ubuntu">
        <code-block lang="bash">
            sudo apt install python3-pip -y
            # or
            sudo -H pip3 install --upgrade pip
            sudo pip3 install podman-compose
        </code-block>
    </tab>
    <tab title="MacOS">
        <code-block lang="bash">
            brew install python3-pip
        </code-block>
    </tab>
</tabs>

- 버젼 확인
```Bash
podman-compose version
```

- Docker Compose 설치
  - https://github.com/docker/compose/releases 의 릴리즈 정보 참고 할 것
<tabs>
    <tab title="RHEL/CentOS/Oracle/Amazon">
        <code-block lang="bash">
            sudo yum install podman-docker -y
        </code-block>
    </tab>
    <tab title="Ubuntu">
        <code-block lang="bash">
            sudo apt install podman-docker -y
        </code-block>
    </tab>
    <tab title="MacOS">
        <code-block lang="bash">
            brew install podman-docker
        </code-block>
    </tab>
</tabs>

```Bash
# 위 설치 후 수행 할 것
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

### Podman Socket {id="podman_2_3"}
- Unix 소켓을 만들어 Docker 작성 기능을 작동하려면 Podman 소켓을 활성화해야 한다
- Docker Compose / Podman Compose 간 호환성을 위해 필요하다

```Bash
sudo systemctl enable --now podman.socket
sudo systemctl status podman.socket
```
## Alias 설정 {id="podman_3"}

- podman 은 기본적으로 docker 와 명령어가 호환 가능하다

```Bash
alias docker=podman
```
## 주의 사항 {id="podman_4"}
- podman 은 기본 이미지 저장소를 RedHat 의 quay.io 로 설정한다 
- docker.io 이미지 저장소를 사용하려면 이미지 주소 앞에 "docker.io" 를 붙여야 한다
- [ISSUE : 이름 또는 ID 앱이 있는 컨테이너를 찾을 수 없습니다](https://github.com/containers/podman-compose/issues/248#issuecomment-1312567169)
```Bash
  redis:
    restart: always
    image: docker.io/redis
```

### Docker 에서 마이그레이션 시 이슈 {id="podman_4_1"}
#### CNI (Container Network Interface) 버젼 오류
```Bash
podman network ls
```
<sub>결과</sub>

```Bash
WARN[0000] Error validating CNI config file /home/orca/.config/cni/net.d/my-ecosystem_default.conflist: [plugin bridge does not support config version "1.0.0" plugin portmap does not support config version "1.0.0" plugin firewall does not support config version "1.0.0" plugin tuning does not support config version "1.0.0"]
NETWORK ID    NAME                  VERSION     PLUGINS
2f259bab93aa  podman                0.4.0       bridge,portmap,firewall,tuning
6dba0e056a86  my-ecosystem_default  1.0.0       bridge,portmap,firewall,tuning,dnsname
```
- podman 기본 네트워크는 CNI 버젼 0.4.0 이다, 하지만 컨테이너를 올릴 때 추가되는 네트워크는 CNI 버젼 1.0.0 이다

- Compose 를 통해 컨테이너를 실행하면 아래 에러가 발생한다.
```Bash
WARN[0000] Error validating CNI config file /home/orca/.config/cni/net.d/my-ecosystem_default.conflist: [plugin bridge does not support config version "1.0.0" plugin portmap does not support config version "1.0.0" plugin firewall does not support config version "1.0.0" plugin tuning does not support config version "1.0.0"]
WARN[0000] Error validating CNI config file /home/orca/.config/cni/net.d/my-ecosystem_default.conflist: [plugin bridge does not support config version "1.0.0" plugin portmap does not support config version "1.0.0" plugin firewall does not support config version "1.0.0" plugin tuning does not support config version "1.0.0"]
ERRO[0000] error loading cached network config: network "my-ecosystem_default" not found in CNI cache
WARN[0000] falling back to loading from existing plugins on disk
WARN[0000] Error validating CNI config file /home/orca/.config/cni/net.d/my-ecosystem_default.conflist: [plugin bridge does not support config version "1.0.0" plugin portmap does not support config version "1.0.0" plugin firewall does not support config version "1.0.0" plugin tuning does not support config version "1.0.0"]
ERRO[0000] Error tearing down partially created network namespace for container 5da6ae5d4a74eace95963032c366da67aa0830e84677650bfed9bbe620933f6c: CNI network "my-ecosystem_default" not found
Error: unable to start container 5da6ae5d4a74eace95963032c366da67aa0830e84677650bfed9bbe620933f6c: error configuring network namespace for container 5da6ae5d4a74eace95963032c366da67aa0830e84677650bfed9bbe620933f6c: CNI network "my-ecosystem_default" not found
exit code: 125
```
- CNI 버젼이 1.0.0 이면 이를 지원하지 않는다는 에러가 발생한다
- ~/.config/cni/net.d/my-ecosystem_default.conflist 파일을 열어보면 버젼이 1.0.0 으로 되어있다
```json
{
   "args": {
      "podman_labels": {
         "com.docker.compose.project": "my-ecosystem",
         "io.podman.compose.project": "my-ecosystem"
      }
   },
   "cniVersion": "1.0.0",
   "name": "my-ecosystem_default",
   "plugins": [
      {
         "type": "bridge",
         "bridge": "cni-podman1",
         "isGateway": true,
         "ipMasq": true,
         "hairpinMode": true,
         "ipam": {
            "type": "host-local",
            "routes": [
               {
                  "dst": "0.0.0.0/0"
               }
            ],
            "ranges": [
               [
                  {
                     "subnet": "10.89.0.0/24",
                     "gateway": "10.89.0.1"
                  }
               ]
            ]
         }
      },
      {
         "type": "portmap",
         "capabilities": {
            "portMappings": true
         }
      },
      {
         "type": "firewall",
         "backend": ""
      },
      {
         "type": "tuning"
      },
      {
         "type": "dnsname",
         "domainName": "dns.podman",
         "capabilities": {
            "aliases": true
         }
      }
   ]
}
```                        
- "cniVersion": "1.0.0" 을 "cniVersion": "0.4.0" 으로 변경하면 에러가 발생하지 않는다.
- [참조](https://www.reddit.com/r/podman/comments/14f6frv/podman_automatically_sets_cniversion_100_instead/)

#### 공유 마운트 문제
- Docker 에서 Podman 으로 마이그레이션 시 공유 마운트가 정상적으로 동작하지 않는 경우가 발생할 수 있다
```Bash
WARN[0000] "/" is not a shared mount, this could cause issues or missing mounts with rootless containers
```
- Podman 은 기본적으로 rootless 모드로 실행되기 때문에 root 권한이 없어도 컨테이너를 관리할 수 있다.
- Podman 은 컨테이너를 실행할 때 컨테이너의 루트 디렉토리를 호스트의 루트 디렉토리와 공유하지 않는다.
- 이를 위해 마운트 설정이 필요한데, 이가 누락되었을 경우 발생한다
- [참조](https://github.com/containers/buildah/issues/3726)
```Bash
findmnt -o PROPAGATION /
# or 
sudo mount --make-rshared /
```

#### Permision Denied 이슈
- podman 사용시 아래와 같은 root 권한 문제가 발생
```Bash
$ podman-compose up
podman-compose version: 1.0.6
['podman', '--version', '']
using podman version: 3.4.4
** excluding:  set()
['podman', 'ps', '--filter', 'label=io.podman.compose.project=my-ecosystem', '-a', '--format', '{{ index .Labels "io.podman.compose.config-hash"}}']
Error: error creating tmpdir: mkdir /run/user/1000: permission denied
```
- systemd 가 비활성화 된 환경에서 (WSL) 등 사용자 세션을 유지하지 않는 환경에서 발생한다
- podman 의 사용자 세션은 /run/user/UID 디렉토리에 의존하는데 이 세션을 읽는데 문제가 발생하는 것이다
[참고](https://github.com/containers/podman/issues/9002)
```Bash
loginctl enable-linger my_ci_user
```


### Rootless 에서의 80,443 포트 사용 
```Bash
sudo sh -c "echo 0 > /proc/sys/net/ipv4/ip_unprivileged_port_start"
```
[참고](https://github.com/containers/podman/issues/3212#issuecomment-523311734)

### Rootless 에서의 지속 가능한 컨테이너 실행
- 일반 유저로 로그인 한 계정 에서  podman 을 rootless 모드에서 컨테이너를 실행하면 로그아웃시 컨테이너 도 같이 종료된다.
- RedHat 에서는 systemd 를 통해 서비스를 생성, 관리하는것을 권장하고 있다
  - [참고](https://access.redhat.com/documentation/ko-kr/red_hat_enterprise_linux/8/html/building_running_and_managing_containers/assembly_porting-containers-to-systemd-using-podman_building-running-and-managing-containers)
  ```Bash
  podman generate systemd --new --name [서비스명] [컨테이너_ID]
  ```
  - 하지만 이는 각각의 컨테이너마다 서비스를 생성해야 하기 때문에 번거롭다

- 만약 장비를 재부팅시 컨테이너가 자동으로 실행되지 않아도 무관하다면 아래 명령어를 사용한다
  - linger 륀 활성화하면 로그아웃시에도 사용자의 프로세스가 종료되지 않는다
  ```Bash
  sudo loginctl enable-linger [UID]
  ```
  - [참고](https://www.freedesktop.org/software/systemd/man/latest/loginctl.html)

### /run/docker.sock 사용
- Docker 와 호환성을 위해 /run/docker.sock 을 사용하는 경우
```Bash
sudo ln -s /run/podman/podman.sock /run/docker.sock
```
또는
- 현재 사용자의 podman.sock 을 사용하는 것이 좋다
```yaml
# 예시
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    networks:
      - podman-bridge
    expose:
      - 9443
    volumes:
      - /run/user/1002/podman/podman.sock:/var/run/docker.sock
      - ./portainer:/data
      - ./cert/ssl.pem:/certs/ssl.pem:ro
      - ./cert/ssl.key:/certs/ssl.key:ro
    command:
      --ssl
      --sslcert /certs/ssl.pem
      --sslkey /certs/ssl.key
```



## podman 명령어 {id="podman_5"}

```bash
# Image 다운로드 
## pull 명령어는 컨테이너 이미지를 다운로드한다
podman  pull [이미지명]:[태그]
# Image 목록
podman  images
# Image 삭제
podman  rmi [이미지명]:[태그]

# Image 빌드 (Dockerfile 필요)
podman build -t [태그명] .

# Image 기반으로 컨테이너를 실행
podman  run [옵션] [이미지명]:[태그]

# checkporint & restore
## 컨테이너의 현재 상황을 checkpoint 해서 디스크로 저장해뒀다가 restore해서 다시 올릴 수도 있다.
podman container checkpoint --leave-running --export=/tmp/backup.tar [컨테이너_ID_또는_이름]
podman stop [컨테이너_ID_또는_이름]
podman rm [컨테이너_ID_또는_이름]
podman container restore --import=/tmp/backup.tar

# 현재 실행 중인 Container 목록
podman ps
# 모든 Container 목록
podman ps -a

# 실행 중인 Container 중지
podman stop [컨테이너_ID_또는_이름]
# Container 재시작
podman restart [컨테이너_ID_또는_이름]
# Container 삭제
podman rm [컨테이너_ID_또는_이름]

# Pod 생성
podman pod create --name [Pod_이름]

# Pod 조회
podman pod ls
podman ps -a --pod

# Pod에 컨테이너 추가
podman run -dt --pod [Pod_이름] [컨테이너_ID]

# Pod 시작/중지/삭제
podman pod start [컨테이너_ID]
podman pod stop [컨테이너_ID]
podman pod rm [컨테이너_ID]

# Network 목록
podman network ls
# Network 상세 정보
podman network inspect [네트워크_ID_또는_이름]

# Volume 목록
podman volume ls
# Volume 상세 정보
podman volume inspect [볼륨_ID_또는_이름]

# generate systemd service file
podman generate systemd [컨테이너_ID]
#  kubernetes yaml 파일도 생성 가능
podman generate kube [컨테이너_ID]

```

## Pod {id="podman_6"}

- 함께 실행되며 동일한 리소스를 공유하는 컨테이너 그룹
- 쿠버네티스 Pod와 유사하지만, 쿠버네티스와는 별개의 개념이다
- 각 포드는 하나의 인프라 컨테이너와 다수의 일반적인 컨테이너로 구성된다
    - 인프라 컨테이너는 포드를 실행하고 사용자 네임스페이스를 유지 관리하여 컨테이너를 호스트로부터 분리한다
    - 일반 컨테이너는 프로세스를 추적하고 빈 컨테이너를 찾을 수 있도록 모니터를 가지고 있다
- Podman은 컨테이너, Pod, 컨테이너 이미지 및 볼륨을 위한 API를 제공하는 간단한 커맨드라인 인터페이스(CLI)와 libpod 라이브러리를 통해 pod를 관리한다
- Podman의 CLI는 컨테이너 런타임과 형식을 위한 업계 표준을 준수하도록 설계된 Open Container Initiative(OCI) 컨테이너를 생성하고 지원

## Buildah, Skopeo {id="podman_7"}

- Podman은 Docker와 달리 build, push 명령어를 제공하지 않는다, 대신에 buildah, skopeo 를 사용한다.
- buildah 는 Dockerfile 을 사용하여 이미지를 빌드하고, skopeo 는 이미지를 push, pull 한다.

<seealso>
  <category ref="official">
    <a href="https://www.redhat.com/ko/topics/containers/what-is-podman">Podman 이란? - Red Hat</a>
    <a href="https://docs.oracle.com/ko/learn/podman-compose/#prerequisites">Podman으로 파일 작성 사용 - Oracle</a>
  </category>
  <category ref="reference">
    <a href="https://hbase.tistory.com/435">Podman 설치 및 사용법 - Docker desktop의 대체재</a>
    <a href="https://velog.io/@composite/Podman-Compose-설치-방법">Podman Compose 설치 방법</a>
  </category>
</seealso>