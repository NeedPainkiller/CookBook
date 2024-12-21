# PostgreSQL HA 구성


## Connection Pool

PostgreSQL 데이터베이스를 위한 커넥션 풀링 및 로드 밸런싱 도구로 PgBouncer와 pgpool 두 가지 대표적인 도구가 있다.

## PgBouncer
- **주요 기능**: 커넥션 풀링
- **설치 및 설정**: 간단하고 가벼움
- **성능**: 매우 가벼운 메모리 사용량과 빠른 성능
- **기능 제한**: 단순한 커넥션 풀링 기능만 제공, 로드 밸런싱 및 고가용성 기능 없음
- **사용 사례**: 단순한 커넥션 풀링이 필요한 경우

## pgpool
- **주요 기능**: 커넥션 풀링, 로드 밸런싱, 고가용성, 쿼리 캐싱, 리플리케이션 관리
- **설치 및 설정**: 복잡하고 다양한 설정 가능
- **성능**: 다양한 기능을 제공하지만, 그만큼 메모리 사용량이 많고 설정이 복잡할 수 있음
- **기능 제한**: 다양한 기능을 제공하지만, 설정이 복잡하고 성능 튜닝이 필요할 수 있음
- **사용 사례**: 고가용성, 로드 밸런싱, 리플리케이션 관리 등 다양한 기능이 필요한 경우

## Replication

### Master-Slave
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


## Clustering


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

