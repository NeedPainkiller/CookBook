# PostgreSQL HA 구성

## Base Knowledge
### Connection Pool

#### PgBouncer
- **주요 기능**: 커넥션 풀링
- **설치 및 설정**: 간단하고 가벼움
- **성능**: 매우 가벼운 메모리 사용량과 빠른 성능
- **기능 제한**: 단순한 커넥션 풀링 기능만 제공, 로드 밸런싱 및 고가용성 기능 없음
- **사용 사례**: 단순한 커넥션 풀링이 필요한 경우

#### pgpool
- **주요 기능**: 커넥션 풀링, 로드 밸런싱, 고가용성, 쿼리 캐싱, 리플리케이션 관리
- **설치 및 설정**: 복잡하고 다양한 설정 가능
- **성능**: 다양한 기능을 제공하지만, 그만큼 메모리 사용량이 많고 설정이 복잡할 수 있음
- **기능 제한**: 다양한 기능을 제공하지만, 설정이 복잡하고 성능 튜닝이 필요할 수 있음
- **사용 사례**: 고가용성, 로드 밸런싱, 리플리케이션 관리 등 다양한 기능이 필요한 경우


### Replication Manager

#### repmgr
- **주요 기능**: 리플리케이션 관리, 자동 페일오버, 클러스터 관리
- **설치 및 설정**: PostgreSQL 확장으로 설치, 설정이 비교적 간단함
- **성능**: 리플리케이션 및 페일오버 관리에 최적화
- **기능 제한**: 커넥션 풀링 및 로드 밸런싱 기능 없음
- **사용 사례**: 리플리케이션 관리 및 고가용성이 필요한 경우

## Replication (Master-Slave)

- Master - Slave 에서는 각 데이터 세트의 내용은 동일하게 유지된다.
- 각 데이터 세트는 물리적으로 독립적이다.
- ORACLE 의 RAC (Real Application Cluster)) 와는 구성이 다르다 (RAC 는 각 Instance 가 독립적으로 동작하며, 데이터를 물리적인 공간으로 공유한다)
  - Slave 가 직접 Master 의 Host 에 접근할 수 있어야 한다.


#### Streaming Replication
- Master 에서 Slave 로 데이터를 전송하는 방식
- WAL (Write Ahead Log) 를 포함한 모든 클러스터 데이터를 바이너리 수준에서 복제한다.

#### Logical Replication
- 테이블 단위로 데이터를 복제한다.
- 버젼/테이블/컬럼 단위로 복제 가능하다.
- 더 많은 유연성을 제공한다.

### Docker
```yaml
version: '3.8'
x-postgres-common:
        &postgres-common
  image: postgres:14-alpine
  user: postgres
  restart: always
  healthcheck:
    test: 'pg_isready -U user --dbname=postgres'
    interval: 10s
    timeout: 5s
    retries: 5

services:
  postgres_primary:
    <<: *postgres-common
    ports:
      - 5432:5432
    environment:
      POSTGRES_USER: user
      POSTGRES_DB: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_HOST_AUTH_METHOD: "scram-sha-256\nhost replication all 0.0.0.0/0 md5"
      POSTGRES_INITDB_ARGS: "--auth-host=scram-sha-256"
    command: |
      postgres 
      -c wal_level=replica 
      -c hot_standby=on 
      -c max_wal_senders=10 
      -c max_replication_slots=10 
      -c hot_standby_feedback=on
    volumes:
      - ./00_init.sql:/docker-entrypoint-initdb.d/00_init.sql

  postgres_replica:
    <<: *postgres-common
    ports:
      - 5433:5432
    environment:
      PGUSER: replicator
      PGPASSWORD: replicator_password
    command: |
      bash -c "
      until pg_basebackup --pgdata=/var/lib/postgresql/data -R --slot=replication_slot --host=postgres_primary --port=5432
      do
      echo 'Waiting for primary to connect...'
      sleep 1s
      done
      echo 'Backup done, starting replica...'
      chmod 0700 /var/lib/postgresql/data
      postgres
      "
    depends_on:
      - postgres_primary
```


## Clustering (3+ Node Cluster)

### on premise

```bash
# Primary 서버에서 postgresql.conf 설정
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on

# Primary 서버에서 pg_hba.conf 설정
host replication all 0.0.0.0/0 md5

# Primary 서버에서 데이터베이스 초기화
initdb -D /var/lib/postgresql/data
pg_ctl -D /var/lib/postgresql/data start

# Replica 서버에서 pg_basebackup 실행
pg_basebackup -h primary_server_ip -D /var/lib/postgresql/data -U replication_user -P -R

# 각 서버에서 repmgr.conf 설정
node_id=1
node_name=node1
conninfo='host=node1_ip user=repmgr dbname=repmgr'
data_directory='/var/lib/postgresql/data'

# Primary 서버에서 repmgr 클러스터 초기화
repmgr primary register

# Replica 서버에서 repmgr 클러스터에 등록
repmgr standby clone -h primary_server_ip -U replication_user -d repmgr
repmgr standby register

# repmgrd 데몬 시작
repmgrd -f /etc/repmgr.conf
```

### Docker
```YML
version: '3.8'

x-postgres-common:
    &postgres-common
  image: docker.io/bitnami/postgresql-repmgr:11
  user: postgres
  #  restart: always
  networks:
    - postgresql-network
  environment:
    - POSTGRESQL_POSTGRES_PASSWORD=adminpassword
    - POSTGRESQL_USERNAME=postgresuser
    - POSTGRESQL_PASSWORD=postgrespasswrd
    - POSTGRESQL_DATABASE=testdb
    - POSTGRESQL_NUM_SYNCHRONOUS_REPLICAS=1
    - REPMGR_PASSWORD=repmgrpassword
  healthcheck:
    test: 'pg_isready -U user --dbname=testdb'
    interval: 10s
    timeout: 5s
    retries: 5

x-pgpool-common:
    &pgpool-common
  image: docker.io/bitnami/pgpool:4
  #  restart: always
  networks:
    - postgresql-network
  environment:
    - PGPOOL_SR_CHECK_USER=postgresuser
    - PGPOOL_SR_CHECK_PASSWORD=postgrespasswrd
    - PGPOOL_ENABLE_LDAP=no
    - PGPOOL_POSTGRES_USERNAME=postgresuser
    - PGPOOL_POSTGRES_PASSWORD=postgrespasswrd
    - PGPOOL_ADMIN_USERNAME=postgresadmin
    - PGPOOL_ADMIN_PASSWORD=postgresadminpassword
    - PGPOOL_ENABLE_LOAD_BALANCING=yes
    - PGPOOL_ENABLE_WATCHDOG=yes
    - PGPOOL_WD_HEARTBEAT_PORT=9694
    - PGPOOL_WD_HEARTBEAT_DESTINATION_PORT=9694
    - PGPOOL_WD_HEARTBEAT_DESTINATION=pgpool-1,pgpool-2,pgpool-3
    - PGPOOL_WD_IPC_SOCKET_DIR=/tmp
    - PGPOOL_WD_DELEGATE_IP=192.168.0.100
  healthcheck:
    test: [ "CMD", "/opt/bitnami/scripts/pgpool/healthcheck.sh" ]
    interval: 10s
    timeout: 5s
    retries: 5



services:
  pg-1:
    <<: *postgres-common
    ports:
      - 15432:5432
    volumes:
      - pg_1_data:/bitnami/postgresql
    environment:
      - REPMGR_PRIMARY_HOST=pg-1
      - REPMGR_PARTNER_NODES=pg-1,pg-2,pg-3
      - REPMGR_NODE_NAME=pg-1
      - REPMGR_NODE_NETWORK_NAME=pg-1
      -
  pg-2:
    <<: *postgres-common
    ports:
      - 15433:5432
    volumes:
      - pg_2_data:/bitnami/postgresql
    environment:
      - REPMGR_PRIMARY_HOST=pg-1
      - REPMGR_PARTNER_NODES=pg-1,pg-2,pg-3
      - REPMGR_NODE_NAME=pg-2
      - REPMGR_NODE_NETWORK_NAME=pg-2
  pg-3:
    <<: *postgres-common
    ports:
      - 15434:5432
    volumes:
      - pg_3_data:/bitnami/postgresql
    environment:
      - REPMGR_PRIMARY_HOST=pg-1
      - REPMGR_PARTNER_NODES=pg-1,pg-2,pg-3
      - REPMGR_NODE_NAME=pg-3
      - REPMGR_NODE_NETWORK_NAME=pg-3

  pgpool-1:
    <<: *pgpool-common
    ports:
      - 25432:5432
    environment:
      - PGPOOL_BACKEND_NODES=0:pg-1:15432,1:pg-2:15433,2:pg-3:15434
      - PGPOOL_WD_HOSTNAME=pgpool-1
      - PGPOOL_WD_PORT=9000

  pgpool-2:
    <<: *pgpool-common
    ports:
      - 25433:5432
    environment:
      - PGPOOL_BACKEND_NODES=0:pg-1:15432,1:pg-2:15433,2:pg-3:15434
      - PGPOOL_WD_HOSTNAME=pgpool-2
      - PGPOOL_WD_PORT=9000

  pgpool-3:
    <<: *pgpool-common
    ports:
      - 25434:5432
    environment:
      - PGPOOL_BACKEND_NODES=0:pg-1:15432,1:pg-2:15433,2:pg-3:15434
      - PGPOOL_WD_HOSTNAME=pgpool-3
      - PGPOOL_WD_PORT=9000


  pgadmin:
    image: dpage/pgadmin4
    restart: always
    container_name: pgadmin4
    ports:
      - 5050:80
    environment:
      PGADMIN_DEFAULT_EMAIL: pgadmin4@pgadmin.org
      PGADMIN_DEFAULT_PASSWORD: password
    volumes:
      - ./data/pgadmin/:/var/lib/pgadmin


networks:
  postgresql-network:
    driver: host

volumes:
  pg_1_data:
    driver: local
  pg_2_data:
    driver: local
  pg_3_data:
    driver: local 
```


## Properties
- shared_buffers: 데이터베이스 서버가 공유 메모리 버퍼에 사용하는 메모리 양
  Recommended Value: 256MB (사용 가능한 메모리에 따라 달라짐)
- wal_level: Sets the level of information written to the WAL (Write-Ahead Log).  
  Recommended Value: replica (for replication setups)
- archive_mode: Enables WAL archiving.  
  Recommended Value: on (if you need to archive WAL files)
- archive_command: Specifies the shell command to use to archive a completed WAL file segment.  
  Recommended Value: cp %p /path/to/archive/%f (adjust the path as needed)
- effective_cache_size: An estimate of the memory available for disk caching by the operating system and within the database itself.  
  Recommended Value: 512MB (사용 가능한 메모리에 따라 달라집)
- min_wal_size: Minimum size to shrink the WAL to.  
  Recommended Value: 80MB
- max_wal_size: Maximum size to let the WAL grow to.  
  Recommended Value: 1GB
- logging_collector: Enables the collection of log messages to a log file.  
  Recommended Value: on
- log_line_prefix: Controls the information prefixed to each log line.  
  Recommended Value: %t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h
- autovacuum_max_workers: Sets the maximum number of autovacuum processes.  
  Recommended Value: 3
- timezone: Sets the time zone for displaying and interpreting time stamps.  
  Recommended Value: UTC
- log_timezone: Sets the time zone used for timestamps in log messages.  
  Recommended Value: UTC

