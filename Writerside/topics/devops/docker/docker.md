# Docker
## 설치 {id="docker_1"}
```Bash
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker ${USER}
```

## 명령어 {id="docker_2"}
```bash
# Docker Image 다운로드 - docker pull 명령어는 Docker 이미지를 다운로드합니다.
docker pull [이미지명]:[태그]
# Docker Image 목록
docker images
# Docker Image 삭제
docker rmi [이미지명]:[태그]

# Docker Image 기반으로 컨테이너를 실행
docker run 옵션 [이미지명]:[태그]

# 현재 실행 중인 Docker Container 목록
docker ps
# 모든 Docker Container 목록
docker ps -a

# 실행 중인 Docker Container 중지
docker stop [컨테이너_ID_또는_이름]
# Docker Container 재시작
docker restart [컨테이너_ID_또는_이름]
# Docker Container 삭제
docker rm [컨테이너_ID_또는_이름]


# Docker Volume 목록
docker volume ls
# Docker Volume 상세 정보
docker volume inspect [볼륨_ID_또는_이름]
```

## 네트워크
- Docker 컨테이너(container)는 격리된 환경에서 실행되기 때문에 기본적으로 다른 컨테이너와의 통신이 불가능하다.
- 여러 개의 컨테이너를 하나의 Docker 네트워크(network)에 연결시키면 서로 통신이 가능하다
```Bash
# Docker Network 목록
docker network ls
# Docker Network 생성
docker network create [네트워크_ID_또는_이름]
# Docker Network 삭제
docker network rm [네트워크_ID_또는_이름]
# Docker Network 중 불필요 (컨테이너가 없는 경우) 한 네트워크 삭제
docker network prune

# Docker Network 상세 정보
docker network inspect [네트워크_ID_또는_이름]
# Docker Network에 연결된 컨테이너 목록
docker network inspect [네트워크_ID_또는_이름] --format='{{range .Containers}}{{.Name}} {{end}}'
# Docker Network에 연결된 컨테이너의 IP 주소 확인
docker network inspect [네트워크_ID_또는_이름] --format='{{range .Containers}}{{.Name}} {{.IPv4Address}} {{end}}'

# Docker Network에 컨테이너 연결
docker network connect [네트워크_ID_또는_이름] [컨테이너_ID_또는_이름]
# or
docker run -itd --name [컨테이너_이름] --network [네트워크_ID_또는_이름] [이미지명]:[태그]
# Docker Network에서 컨테이너 연결 해제
docker network disconnect [네트워크_ID_또는_이름] [컨테이너_ID_또는_이름]
# Docker Network에 연결된 컨테이너간 연결 테스트
docker exec [컨테이너_ID_또는_이름_1] ping [컨테이너_ID_또는_이름_2]
```

```Bash
$ docker network ls
NETWORK ID     NAME                   DRIVER    SCOPE
ed8a186f90d9   bridge                 bridge    local
fc0a2a818e65   host                   host      local
e0a537b07d96   none                   null      local
```
- bridge, host, none은 Docker 데몬(containerd)이 실행되면서 디폴트로 생성되는 네트워크이다.

| 네트워크    | 설명                                                                                          |
|---------|---------------------------------------------------------------------------------------------|
| bridge  | 기본 네트워크 드라이버, 독립된 네트워크를 생성해 컨테이너가 서로 통신할 수 있게 합니다. 이는 각 컨테이너에 대해 격리된 네트워크 환경을 제공.           |
| host    | 호스트의 네트워크 스택을 그대로 사용한다. 컨테이너가 호스트의 네트워크 인터페이스와 동일한 네트워크 환경을 공유, 보안상의 이유로 격리가 필요하지 않은 경우에 사용 |
| overlay | 여러 노드에 걸쳐 있는 컨테이너들이 서로 통신할 수 있도록 하는 드라이버,  Docker Swarm이나 Kubernetes와 같은 클러스터 환경에서 사용                                                  |
| macvlan |컨테이너가 독립적인 MAC 주소를 갖게 되어, 마치 별도의 물리적 장치처럼 네트워크에 연결|
| none    | 네트워크를 사용하지 않는다.                                                                             |


