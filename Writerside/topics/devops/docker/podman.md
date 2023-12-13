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

## Alias 설정 {id="podman_3"}

- podman 은 기본적으로 docker 와 명령어가 호환 가능하다

```Bash
alias docker=podman
```

## podman 명령어 {id="podman_4"}

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
podman  ps
# 모든 Container 목록
podman  ps -a

# 실행 중인 Container 중지
podman  stop [컨테이너_ID_또는_이름]
# Container 재시작
podman  restart [컨테이너_ID_또는_이름]
# Container 삭제
podman  rm [컨테이너_ID_또는_이름]

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

## Pod {id="podman_5"}

- 함께 실행되며 동일한 리소스를 공유하는 컨테이너 그룹
- 쿠버네티스 Pod와 유사하지만, 쿠버네티스와는 별개의 개념이다
- 각 포드는 하나의 인프라 컨테이너와 다수의 일반적인 컨테이너로 구성된다
    - 인프라 컨테이너는 포드를 실행하고 사용자 네임스페이스를 유지 관리하여 컨테이너를 호스트로부터 분리한다
    - 일반 컨테이너는 프로세스를 추적하고 빈 컨테이너를 찾을 수 있도록 모니터를 가지고 있다
- Podman은 컨테이너, Pod, 컨테이너 이미지 및 볼륨을 위한 API를 제공하는 간단한 커맨드라인 인터페이스(CLI)와 libpod 라이브러리를 통해 pod를 관리한다
- Podman의 CLI는 컨테이너 런타임과 형식을 위한 업계 표준을 준수하도록 설계된 Open Container Initiative(OCI) 컨테이너를 생성하고 지원

## Buildah, Skopeo {id="podman_6"}

- Podman은 Docker와 달리 build, push 명령어를 제공하지 않는다, 대신에 buildah, skopeo 를 사용한다.
- buildah 는 Dockerfile 을 사용하여 이미지를 빌드하고, skopeo 는 이미지를 push, pull 한다.

<seealso>
  <category ref="reference">
    <a href="https://www.redhat.com/ko/topics/containers/what-is-podman">Podman 이란? - Red Hat</a>
    <a href="https://hbase.tistory.com/435">Podman 설치 및 사용법 - Docker desktop의 대체재</a>
  </category>
</seealso>