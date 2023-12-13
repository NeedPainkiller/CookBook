# Docker Compose
## 설치 {id="docker-compose_1"}
```Bash
# Docker 설치 후 수행 할 것
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```
## 명령어 {id="docker-compose_2"}
```bash

# 실행
docker compose up
docker-compose up

# 백그라운드에서 실행
docker compose up -d
docker-compose up -d

# 백그라운드에서 서비스 빌드 및 실행, 이미 실행 중이면 강제로 재생성
docker compose up -d --force-recreate
docker-compose up -d --force-recreate

# 서비스 중지
docker compose stop
docker-compose stop

# 서비스 다운
docker compose down
docker-compose down

# 서비스 삭제
docker compose rm --force
docker-compose rm --force

# 실행중인 서비스 확인하기
docker compose ps
docker-compose ps

# 서비스 로그 확인하기
docker compose logs
docker-compose logs

# 서비스 로그 지속적으로 확인하기
docker compose logs -f
docker-compose logs -f

# 서비스 로그 지정해서 확인하기
docker compose logs <서비스이름> <서비스이름> ...
```

### 사용 예시  {id="docker_3_1"}

### redis-stat
```bash
docker run --name redis-stat --link rpa-portal-redis:redis -p 63790:63790 -d insready/redis-stat --server redis -a redis


docker run --name redis-stat -p 63790:63790 -d insready/redis-stat --server 127.0.0.1:6300 127.0.0.1:6301 127.0.0.1:6302 127.0.0.1:6400 127.0.0.1:6401 127.0.0.1:6402
```
http://localhost:63790/


### Docker Compose 클러스터 설정 예시
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
