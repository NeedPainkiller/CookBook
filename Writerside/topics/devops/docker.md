# Docker
## Docker 설치 {id="docker_1"}
<tabs>
    <tab title="Docker">
        <code-block lang="bash">
            sudo mkdir -m 0755 -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo \
            "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo usermod -aG docker ${USER}
        </code-block>
    </tab>
    <tab title="Docker Compose">
        <code-block lang="bash">
            # Docker 설치 후 수행 할 것
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            docker-compose --version
        </code-block>
    </tab>
</tabs>

## Docker 명령어 {id="docker_2"}
```bash
# Docker Image 다운로드 - docker pull 명령어는 Docker 이미지를 다운로드합니다.
docker pull 이미지명:태그
# Docker Image 목록
docker images
# Docker Image 삭제
docker rmi 이미지명:태그

# Docker Image 기반으로 컨테이너를 실행
docker run 옵션 이미지명:태그

# 현재 실행 중인 Docker Container 목록
docker ps
# 모든 Docker Container 목록
docker ps -a

# 실행 중인 Docker Container 중지
docker stop 컨테이너_ID_또는_이름
# Docker Container 재시작
docker restart 컨테이너_ID_또는_이름
# Docker Container 삭제
docker rm 컨테이너_ID_또는_이름


# Docker Network 목록
docker network ls
# Docker Network 상세 정보
docker network inspect 네트워크_ID_또는_이름

# Docker Volume 목록
docker volume ls
# Docker Volume 상세 정보
docker volume inspect 볼륨_ID_또는_이름





```
## Docker Compose 명령어 {id="docker_3"}
```bash

# 실행
docker-compose up

# 백그라운드에서 실행
docker-compose up -d

# 백그라운드에서 서비스 빌드 및 실행, 이미 실행 중이면 강제로 재생성
docker-compose up -d --force-recreate

# 서비스 중지
docker-compose stop

# 서비스 다운
docker-compose down

# 서비스 삭제
docker-compose rm --force

# 실행중인 서비스 확인하기
docker-compose ps

# 서비스 로그 확인하기
docker-compose logs

# 서비스 로그 지속적으로 확인하기
docker-compose logs -f

# 서비스 로그 지정해서 확인하기
docker-compose logs <서비스이름> <서비스이름> ...
```

## 안전한 Docker 이미지 만들기  {id="docker_4"}

- 애플리케이션을 Docker 이미지로 만들고 배포하다보면 무거운 이미지를 베이스 이미지로 사용해 한 번 다운로드 받는 데 시간이 오래 걸리거나 민감한 데이터를 포함해 보안상 문제 생길 수 있음
- Docker 이미지를 더 가볍고 안전하게 만드는 방법
- 이미지 크기 줄이기
    - Docker 이미지가 가벼워질수록 애플리케이션 빌드, 배포 속도가 빨라짐
    - 이러면 더 자주, 많이 배포할 수 있어 개발자 생산성 높아짐
    - 방법
        - 멀티 스테이징 기법: 스테이지를 여러 개 만들고, 각각 따로 빌드해 가장 가벼운 이미지에          결과 통합하는 방식
        - RUN 명령 최대한 적게 쓰는 방법: RUN 명령은 개별 이미지를 만듦. 이를 최소한으로            만들기 위해 RUN 명령 한 번에 최대한 많은 스크립트 실행함
    - .dockerignore로 불필요한 소스 코드 없애기
        - README.md나 테스트 코드는 실제 애플리케이션을 빌드할 때 불필요함
        - API 인증 토큰 같이 민감한 정보가 포함된 .env 파일, .pem 프라이빗 키 파일, Git 커밋 이력이 포함된 .git 디렉터리는 Docker 이미지에 포함되면 안됨
        - 이런 파일을 Docker 이미지에 포함시키지 않도록 .dockerignore 파일 만듦
- 안전한 이미지 만들기
    - Docker 이미지가 루트 권한 있으면 해킹 당할 때 위험할 수 있음
    - 방법
        - 정확한 이미지 버전 쓰기: 버전을 쓰지 않으면 latest 버전을 자동으로 가져와 상황에 따라 실행되는 게 달라질 수 있음
        - /etc에 쓰기 권한 없애기: /etc는 시스템 설정 파일과 스크립트가 담긴 디렉터리. 애플리케이션은 보통 수정할 일이 없어 쓰기 권한을 없애는 것이 좋음
        - 모든 실행 파일 지우기: Go의 경우 실행 파일 하나만 있으면 실행할 수 있어 잠재적 위험이 있는 다른 실행 파일을 모두 지움
        - 일반 유저로 전환하기: 루트 계정은 시스템의 모든 걸 수정하고 제어할 수 있음. 최소한 권한만 있는 유저 생성해 해당 유저로만 애플리케이션이 실행되도록 함
- 가벼운 Docker 이미지는 CI/CD 파이프라인과 애자일 방법론이 만날 때 시너지 보임
- 안전한 Docker 이미지로 비즈니스 보호하고, 위험 사전 예방할 수 있음
### 출처
- [2차 출처-Geek News](https://news.hada.io/topic?id=11613)
- [1차 출처-Docker 이미지 안전하게 만들기](https://insight.infograb.net/blog/2022/12/22/docker-security/)

## Docker Compose 사용 예시  {id="docker_5"}

### redis-stat
```bash
docker run --name redis-stat --link rpa-portal-redis:redis -p 63790:63790 -d insready/redis-stat --server redis -a redis


docker run --name redis-stat -p 63790:63790 -d insready/redis-stat --server 127.0.0.1:6300 127.0.0.1:6301 127.0.0.1:6302 127.0.0.1:6400 127.0.0.1:6401 127.0.0.1:6402
```
http://localhost:63790/


### docker 클러스터 설정 예시
```bash
# 1번 redis-cli 접속
docker exec -it redis-master-node1 bash

# 클러스터 세팅
redis-cli --cluster create redis-master-node1:6379 redis-master-node2:6379 redis-master-node3:6379

# master-slave 연결
redis-cli --cluster add-node redis-slave-node1:6379 redis-master-node1:6379 --cluster-slave
redis-cli --cluster add-node redis-slave-node2:6379 redis-master-node2:6379 --cluster-slave
redis-cli --cluster add-node redis-slave-node3:6379 redis-master-node3:6379 --cluster-slave

exit
```
