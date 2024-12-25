# PostgreSQL HA 구성

## Base Knowledge
### Connection Pool

#### PgBouncer
- **주요 기능**: 커넥션 풀링
- **설치 및 설정**: 간단하고 가벼움
- **성능**: 매우 가벼운 메모리 사용량과 빠른 성능
- **기능 제한**: 단순한 커넥션 풀링 기능만 제공, 로드 밸런싱 및 고가용성 기능 없음
- **사용 사례**: 단순한 커넥션 풀링이 필요한 경우

#### pgpool-II
- **주요 기능**: 커넥션 풀링(재사용), 로드 밸런싱, 고가용성, 쿼리 캐싱, 리플리케이션 관리, 읽기 쿼리를 Replica로 분산 (Query Routing, 부하 분산)
- **설치 및 설정**: 복잡하고 다양한 설정 가능
- **성능**: 다양한 기능을 제공하지만, 그만큼 메모리 사용량이 많고 설정이 복잡할 수 있음
- **기능 제한**: 다양한 기능을 제공하지만, 설정이 복잡하고 성능 튜닝이 필요할 수 있음
- **사용 사례**: 고가용성, 로드 밸런싱, 리플리케이션 관리 등 다양한 기능이 필요한 경우


### Replication Manager

#### repmgr
- **주요 기능**: 리플리케이션(복제) 관리, 자동 페일오버, 클러스터 관리
- **설치 및 설정**: PostgreSQL 확장으로 설치, 설정이 비교적 간단함
- **성능**: 리플리케이션 및 페일오버 관리에 최적화
- **기능 제한**: 클라이언트 커넥션 풀링 및 로드 밸런싱 기능 없음, Failover 후 클라이언트 연결 관리가 필요함
- **사용 사례**: 리플리케이션 관리 및 고가용성이 필요한 경우
- PGpool-II 와 함께 사용하여 커넥션 풀링 및 로드 밸런싱 기능을 추가할 수 있음
- repmgr 과 Pgpool-II 을 기반으로 고가용성(HA), 로드 밸런싱, 장애 조치, 연결 관리 등 다양한 기능을 제공할 수 있음


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


### Docker
#### Environment Variables (PostgreSQL)

| Name                                | Description                                                      | 설명                                                         | Default Value                              |
|-------------------------------------|------------------------------------------------------------------|-------------------------------------------------------------|--------------------------------------------|
| POSTGRESQL_VOLUME_DIR               | Persistence base directory                                       | 지속성 기본 디렉토리                                         | /bitnami/postgresql                        |
| POSTGRESQL_DATA_DIR                 | PostgreSQL data directory                                        | PostgreSQL 데이터 디렉토리                                    | ${POSTGRESQL_VOLUME_DIR}/data              |
| POSTGRESQL_EXTRA_FLAGS              | Extra flags for PostgreSQL initialization                        | PostgreSQL 초기화를 위한 추가 플래그                           | nil                                        |
| POSTGRESQL_INIT_MAX_TIMEOUT         | Maximum initialization waiting timeout                           | 최대 초기화 대기 시간                                          | 60                                         |
| POSTGRESQL_PGCTLTIMEOUT             | Maximum waiting timeout for pg_ctl commands                      | pg_ctl 명령어의 최대 대기 시간                                 | 60                                         |
| POSTGRESQL_SHUTDOWN_MODE            | Default mode for pg_ctl stop command                             | pg_ctl 중지 명령의 기본 모드                                   | fast                                       |
| POSTGRESQL_CLUSTER_APP_NAME         | Replication cluster default application name                     | 복제 클러스터 기본 애플리케이션 이름                           | walreceiver                                |
| POSTGRESQL_DATABASE                 | Default PostgreSQL database                                      | 기본 PostgreSQL 데이터베이스                                   | postgres                                   |
| POSTGRESQL_INITDB_ARGS              | Optional args for PostgreSQL initdb operation                    | PostgreSQL initdb 작업을 위한 선택적 인수                       | nil                                        |
| ALLOW_EMPTY_PASSWORD                | Allow password-less access                                       | 비밀번호 없는 접근 허용                                        | no                                         |
| POSTGRESQL_INITDB_WAL_DIR           | Optional init db wal directory                                   | 선택적 init db wal 디렉토리                                    | nil                                        |
| POSTGRESQL_MASTER_HOST              | PostgreSQL master host (used by slaves)                          | PostgreSQL 마스터 호스트 (슬레이브에서 사용)                    | nil                                        |
| POSTGRESQL_MASTER_PORT_NUMBER       | PostgreSQL master host port (used by slaves)                     | PostgreSQL 마스터 호스트 포트 (슬레이브에서 사용)               | 5432                                       |
| POSTGRESQL_NUM_SYNCHRONOUS_REPLICAS | Number of PostgreSQL replicas that should use synchronous replication | 동기 복제를 사용하는 PostgreSQL 복제본 수                       | 0                                          |
| POSTGRESQL_SYNCHRONOUS_REPLICAS_MODE| PostgreSQL synchronous replication mode (values: empty, FIRST, ANY) | PostgreSQL 동기 복제 모드 (값: empty, FIRST, ANY)              | nil                                        |
| POSTGRESQL_PORT_NUMBER              | PostgreSQL port number                                           | PostgreSQL 포트 번호                                           | 5432                                       |
| POSTGRESQL_ALLOW_REMOTE_CONNECTIONS | Modify pg_hba settings so users can access from the outside      | 사용자가 외부에서 접근할 수 있도록 pg_hba 설정 수정              | yes                                        |
| POSTGRESQL_REPLICATION_MODE         | PostgreSQL replication mode (values: master, slave)              | PostgreSQL 복제 모드 (값: master, slave)                       | master                                     |
| POSTGRESQL_REPLICATION_USER         | PostgreSQL replication user                                      | PostgreSQL 복제 사용자                                         | nil                                        |
| POSTGRESQL_REPLICATION_USE_PASSFILE | Use PGPASSFILE instead of PGPASSWORD                             | PGPASSWORD 대신 PGPASSFILE 사용                                | no                                         |
| POSTGRESQL_REPLICATION_PASSFILE_PATH| Path to store passfile                                           | 패스파일을 저장할 경로                                         | ${POSTGRESQL_CONF_DIR}/.pgpass             |
| POSTGRESQL_SYNCHRONOUS_COMMIT_MODE  | Enable synchronous replication in slaves (number defined by POSTGRESQL_NUM_SYNCHRONOUS_REPLICAS) | 슬레이브에서 동기 복제를 활성화 (POSTGRESQL_NUM_SYNCHRONOUS_REPLICAS로 정의된 수) | on                                         |
| POSTGRESQL_FSYNC                    | Enable fsync in write ahead logs                                 | 선행 기록 로그에서 fsync 활성화                                | on                                         |
| POSTGRESQL_USERNAME                 | PostgreSQL default username                                      | PostgreSQL 기본 사용자 이름                                    | postgres                                   |
| POSTGRESQL_ENABLE_LDAP              | Enable LDAP for PostgreSQL authentication                        | PostgreSQL 인증을 위한 LDAP 활성화                              | no                                         |
| POSTGRESQL_LDAP_URL                 | PostgreSQL LDAP server url (requires POSTGRESQL_ENABLE_LDAP=yes) | PostgreSQL LDAP 서버 URL (POSTGRESQL_ENABLE_LDAP=yes 필요)      | nil                                        |
| POSTGRESQL_LDAP_PREFIX              | PostgreSQL LDAP prefix (requires POSTGRESQL_ENABLE_LDAP=yes)     | PostgreSQL LDAP 접두사 (POSTGRESQL_ENABLE_LDAP=yes 필요)        | nil                                        |
| POSTGRESQL_LDAP_SUFFIX              | PostgreSQL LDAP suffix (requires POSTGRESQL_ENABLE_LDAP=yes)     | PostgreSQL LDAP 접미사 (POSTGRESQL_ENABLE_LDAP=yes 필요)        | nil                                        |
| POSTGRESQL_LDAP_SERVER              | PostgreSQL LDAP server (requires POSTGRESQL_ENABLE_LDAP=yes)     | PostgreSQL LDAP 서버 (POSTGRESQL_ENABLE_LDAP=yes 필요)          | nil                                        |
| POSTGRESQL_LDAP_PORT                | PostgreSQL LDAP port (requires POSTGRESQL_ENABLE_LDAP=yes)       | PostgreSQL LDAP 포트 (POSTGRESQL_ENABLE_LDAP=yes 필요)          | nil                                        |
| POSTGRESQL_LDAP_SCHEME              | PostgreSQL LDAP scheme (requires POSTGRESQL_ENABLE_LDAP=yes)     | PostgreSQL LDAP 스킴 (POSTGRESQL_ENABLE_LDAP=yes 필요)          | nil                                        |
| POSTGRESQL_LDAP_TLS                 | PostgreSQL LDAP tls setting (requires POSTGRESQL_ENABLE_LDAP=yes)| PostgreSQL LDAP tls 설정 (POSTGRESQL_ENABLE_LDAP=yes 필요)      | nil                                        |
| POSTGRESQL_LDAP_BASE_DN             | PostgreSQL LDAP base DN settings (requires POSTGRESQL_ENABLE_LDAP=yes) | PostgreSQL LDAP 기본 DN 설정 (POSTGRESQL_ENABLE_LDAP=yes 필요)  | nil                                        |
| POSTGRESQL_LDAP_BIND_DN             | PostgreSQL LDAP bind DN settings (requires POSTGRESQL_ENABLE_LDAP=yes) | PostgreSQL LDAP 바인드 DN 설정 (POSTGRESQL_ENABLE_LDAP=yes 필요) | nil                                        |
| POSTGRESQL_LDAP_BIND_PASSWORD       | PostgreSQL LDAP bind password (requires POSTGRESQL_ENABLE_LDAP=yes) | PostgreSQL LDAP 바인드 비밀번호 (POSTGRESQL_ENABLE_LDAP=yes 필요) | nil                                        |
| POSTGRESQL_LDAP_SEARCH_ATTR         | PostgreSQL LDAP search attribute (requires POSTGRESQL_ENABLE_LDAP=yes) | PostgreSQL LDAP 검색 속성 (POSTGRESQL_ENABLE_LDAP=yes 필요)     | nil                                        |
| POSTGRESQL_LDAP_SEARCH_FILTER       | PostgreSQL LDAP search filter (requires POSTGRESQL_ENABLE_LDAP=yes) | PostgreSQL LDAP 검색 필터 (POSTGRESQL_ENABLE_LDAP=yes 필요)     | nil                                        |
| POSTGRESQL_INITSCRIPTS_USERNAME     | Username for the psql scripts included in /docker-entrypoint.initdb | /docker-entrypoint.initdb에 포함된 psql 스크립트의 사용자 이름  | $POSTGRESQL_USERNAME                       |
| POSTGRESQL_PASSWORD                 | Password for the PostgreSQL created user                         | 생성된 PostgreSQL 사용자의 비밀번호                             | nil                                        |
| POSTGRESQL_POSTGRES_PASSWORD        | Password for the PostgreSQL postgres user                        | PostgreSQL postgres 사용자의 비밀번호                            | nil                                        |
| POSTGRESQL_REPLICATION_PASSWORD     | Password for the PostgreSQL replication user                     | PostgreSQL 복제 사용자의 비밀번호                                | nil                                        |
| POSTGRESQL_INITSCRIPTS_PASSWORD     | Password for the PostgreSQL init scripts user                    | PostgreSQL 초기화 스크립트 사용자의 비밀번호                     | $POSTGRESQL_PASSWORD                       |
| POSTGRESQL_ENABLE_TLS               | Whether to enable TLS for traffic or not                         | 트래픽에 대해 TLS를 활성화할지 여부                              | no                                         |
| POSTGRESQL_TLS_CERT_FILE            | File containing the certificate for the TLS traffic              | TLS 트래픽에 대한 인증서가 포함된 파일                           | nil                                        |
| POSTGRESQL_TLS_KEY_FILE             | File containing the key for certificate                          | 인증서 키가 포함된 파일                                         | nil                                        |
| POSTGRESQL_TLS_CA_FILE              | File containing the CA of the certificate                        | 인증서의 CA가 포함된 파일                                       | nil                                        |
| POSTGRESQL_TLS_CRL_FILE             | File containing a Certificate Revocation List                    | 인증서 폐기 목록이 포함된 파일                                   | nil                                        |
| POSTGRESQL_TLS_PREFER_SERVER_CIPHERS| Whether to use the server TLS cipher preferences rather than the client | 클라이언트보다 서버 TLS 암호 선호를 사용할지 여부                | yes                                        |
| POSTGRESQL_SHARED_PRELOAD_LIBRARIES | List of libraries to preload at PostgreSQL initialization        | PostgreSQL 초기화 시 미리 로드할 라이브러리 목록                 | pgaudit                                    |
| POSTGRESQL_PGAUDIT_LOG              | Comma-separated list of actions to log with pgaudit              | pgaudit로 로그할 작업의 쉼표로 구분된 목록                       | nil                                        |
| POSTGRESQL_PGAUDIT_LOG_CATALOG      | Enable pgaudit log catalog (pgaudit.log_catalog setting)         | pgaudit 로그 카탈로그 활성화 (pgaudit.log_catalog 설정)          | nil                                        |
| POSTGRESQL_PGAUDIT_LOG_PARAMETER    | Enable pgaudit log parameter (pgaudit.log_parameter setting)     | pgaudit 로그 매개변수 활성화 (pgaudit.log_parameter 설정)        | nil                                        |
| POSTGRESQL_LOG_CONNECTIONS          | Add a log entry per user connection                              | 사용자 연결당 로그 항목 추가                                     | nil                                        |
| POSTGRESQL_LOG_DISCONNECTIONS       | Add a log entry per user disconnection                           | 사용자 연결 해제당 로그 항목 추가                                | nil                                        |
| POSTGRESQL_LOG_HOSTNAME             | Log the client host name when accessing                          | 접근 시 클라이언트 호스트 이름을 로그                             | nil                                        |
| POSTGRESQL_CLIENT_MIN_MESSAGES      | Set log level of errors to send to the client                    | 클라이언트에 보낼 오류의 로그 수준 설정                           | error                                      |
| POSTGRESQL_LOG_LINE_PREFIX          | Set the format of the log lines                                  | 로그 라인의 형식 설정                                            | nil                                        |
| POSTGRESQL_LOG_TIMEZONE             | Set the log timezone                                             | 로그 시간대 설정                                                 | nil                                        |
| POSTGRESQL_TIMEZONE                 | Set the timezone                                                 | 시간대 설정                                                      | nil                                        |
| POSTGRESQL_MAX_CONNECTIONS          | Set the maximum amount of connections                            | 최대 연결 수 설정                                                | nil                                        |
| POSTGRESQL_TCP_KEEPALIVES_IDLE      | Set the TCP keepalive idle time                                  | TCP keepalive 유휴 시간 설정                                      | nil                                        |
| POSTGRESQL_TCP_KEEPALIVES_INTERVAL  | Set the TCP keepalive interval time                              | TCP keepalive 간격 시간 설정                                      | nil                                        |
| POSTGRESQL_TCP_KEEPALIVES_COUNT     | Set the TCP keepalive count                                      | TCP keepalive 횟수 설정                                           | nil                                        |
| POSTGRESQL_STATEMENT_TIMEOUT        | Set the SQL statement timeout                                    | SQL 문 타임아웃 설정                                              | nil                                        |
| POSTGRESQL_PGHBA_REMOVE_FILTERS     | Comma-separated list of strings for removing pg_hba.conf lines (example: md5, local) | pg_hba.conf 라인을 제거하기 위한 쉼표로 구분된 문자열 목록 (예: md5, local) | nil                                        |
| POSTGRESQL_USERNAME_CONNECTION_LIMIT| Set the user connection limit                                    | 사용자 연결 제한 설정                                             | nil                                        |
| POSTGRESQL_POSTGRES_CONNECTION_LIMIT| Set the postgres user connection limit                           | postgres 사용자 연결 제한 설정                                    | nil                                        |
| POSTGRESQL_WAL_LEVEL                | Set the write-ahead log level                                    | 선행 기록 로그 수준 설정                                          | replica                                    |
| POSTGRESQL_DEFAULT_TOAST_COMPRESSION| Set the postgres default compression                             | postgres 기본 압축 설정                                           | nil                                        |
| POSTGRESQL_PASSWORD_ENCRYPTION      | Set the passwords encryption method                              | 비밀번호 암호화 방법 설정                                         | nil                                        |
| POSTGRESQL_DEFAULT_TRANSACTION_ISOLATION | Set transaction isolation                                    | 트랜잭션 격리 설정                                                | nil                                        |
| POSTGRESQL_AUTOCTL_CONF_DIR         | Path to the configuration dir for the pg_autoctl command         | pg_autoctl 명령어의 구성 디렉토리 경로                            | ${POSTGRESQL_AUTOCTL_VOLUME_DIR}/.config   |
| POSTGRESQL_AUTOCTL_MODE             | pgAutoFailover node type, valid values [monitor, postgres]       | pgAutoFailover 노드 유형, 유효한 값 [monitor, postgres]           | postgres                                   |
| POSTGRESQL_AUTOCTL_MONITOR_HOST     | Hostname for the monitor component                               | 모니터 구성 요소의 호스트 이름                                    | monitor                                    |
| POSTGRESQL_AUTOCTL_HOSTNAME         | Hostname by which postgres is reachable                          | postgres에 접근 가능한 호스트 이름                                | $(hostname --fqdn)                         |
| REPMGR_DATA_DIR                     | Replication Manager data directory                               | 복제 관리자 데이터 디렉토리                                       | ${REPMGR_VOLUME_DIR}/repmgr/data           |
| REPMGR_NODE_ID                      | Replication Manager node identifier                              | 복제 관리자 노드 식별자                                           | nil                                        |
| REPMGR_NODE_ID_START_SEED           | Replication Manager node identifier start seed                   | 복제 관리자 노드 식별자 시작 시드                                  | 1000                                       |
| REPMGR_NODE_NAME                    | Replication Manager node name                                    | 복제 관리자 노드 이름                                             | $(hostname)                                |
| REPMGR_NODE_NETWORK_NAME            | Replication Manager node network name                            | 복제 관리자 노드 네트워크 이름                                     | nil                                        |
| REPMGR_NODE_PRIORITY                | Replication Manager node priority                                | 복제 관리자 노드 우선 순위                                         | 100                                        |
| REPMGR_NODE_LOCATION                | Replication Manager node location                                | 복제 관리자 노드 위치                                             | default                                    |
| REPMGR_NODE_TYPE                    | Replication Manager node type                                    | 복제 관리자 노드 유형                                             | data                                       |
| REPMGR_PORT_NUMBER                  | Replication Manager port number                                  | 복제 관리자 포트 번호                                              | 5432                                       |
| REPMGR_LOG_LEVEL                    | Replication Manager logging level                                | 복제 관리자 로깅 수준                                              | NOTICE                                     |
| REPMGR_USE_PGREWIND                 | (Experimental) Use pg_rewind to synchronize from primary node    | (실험적) 기본 노드에서 동기화하기 위해 pg_rewind 사용               | no                                         |
| REPMGR_START_OPTIONS                | Options to add when starting the node                            | 노드를 시작할 때 추가할 옵션                                       | nil                                        |
| REPMGR_CONNECT_TIMEOUT              | Replication Manager node connection timeout (in seconds)         | 복제 관리자 노드 연결 시간 초과 (초)                                | 5                                          |
| REPMGR_RECONNECT_ATTEMPTS           | Number of attempts to connect to the cluster before failing      | 실패하기 전에 클러스터에 연결 시도 횟수                              | 3                                          |
| REPMGR_RECONNECT_INTERVAL           | Replication Manager node reconnect interval (in seconds)         | 복제 관리자 노드 재연결 간격 (초)                                   | 5                                          |
| REPMGR_PARTNER_NODES                | List of other Replication Manager nodes in the cluster           | 클러스터의 다른 복제 관리자 노드 목록                                | nil                                        |
| REPMGR_PRIMARY_HOST                 | Replication Manager cluster primary node                         | 복제 관리자 클러스터 기본 노드                                      | nil                                        |
| REPMGR_PRIMARY_PORT                 | Replication Manager cluster primary node port                    | 복제 관리자 클러스터 기본 노드 포트                                  | 5432                                       |
| REPMGR_USE_REPLICATION_SLOTS        | Replication Manager replication slots                            | 복제 관리자 복제 슬롯                                               | 1                                          |
| REPMGR_MASTER_RESPONSE_TIMEOUT      | Time (in seconds) to wait for the master to reply                | 마스터의 응답을 기다리는 시간 (초)                                   | 20                                         |
| REPMGR_PRIMARY_VISIBILITY_CONSENSUS | Replication Manager flag to enable consult each other to build a quorum | 복제 관리자가 쿼럼을 구성하기 위해 서로 상의하도록 하는 플래그        | false                                      |
| REPMGR_MONITORING_HISTORY           | Replication Manager flag to enable monitoring history            | 모니터링 기록을 활성화하는 복제 관리자 플래그                         | no                                         |
| REPMGR_MONITOR_INTERVAL_SECS        | Replication Manager interval at which to write monitoring data   | 모니터링 데이터를 기록하는 복제 관리자 간격 (초)                      | 2                                          |
| REPMGR_DEGRADED_MONITORING_TIMEOUT  | Replication Manager degraded monitoring timeout                  | 복제 관리자 저하된 모니터링 시간 초과                                 | 5                                          |
| REPMGR_UPGRADE_EXTENSION            | Replication Manager upgrade extension                            | 복제 관리자 업그레이드 확장                                          | no                                         |
| REPMGR_FENCE_OLD_PRIMARY            | Replication Manager fence old primary                            | 복제 관리자 이전 기본 노드 차단                                       | no                                         |
| REPMGR_FAILOVER                     | Replicatication failover mode                                    | 복제 장애 조치 모드                                                  | automatic                                  |
| REPMGR_CHILD_NODES_CHECK_INTERVAL   | Replication Manager time interval to check nodes                 | 노드를 확인하는 복제 관리자 시간 간격                                 | 5                                          |
| REPMGR_CHILD_NODES_CONNECTED_MIN_COUNT | Replication Manager minimal connected nodes                    | 최소 연결된 노드 수를 지정하는 복제 관리자                             | 1                                          |
| REPMGR_CHILD_NODES_DISCONNECT_TIMEOUT | Replication Manager disconnected nodes timeout                  | 연결이 끊긴 노드의 복제 관리자 시간 초과                               | 30                                         |
| REPMGR_SWITCH_ROLE                  | Flag to switch current node role                                 | 현재 노드 역할을 전환하는 플래그                                      | no                                         |
| REPMGR_CURRENT_PRIMARY_HOST         | Current primary host                                             | 현재 기본 호스트                                                     | nil                                        |
| REPMGR_USERNAME                     | Replication manager username                                     | 복제 관리자 사용자 이름                                               | repmgr                                     |
| REPMGR_DATABASE                     | Replication manager database                                     | 복제 관리자 데이터베이스                                               | repmgr                                     |
| REPMGR_PGHBA_TRUST_ALL              | Add trust all in Replication Manager pg_hba.conf                 | 복제 관리자 pg_hba.conf에 모두 신뢰 추가                                | no                                         |
| REPMGR_PASSWORD                     | Replication manager password                                     | 복제 관리자 비밀번호                                                  | nil                                        |
| REPMGR_USE_PASSFILE                 | Use PGPASSFILE instead of PGPASSWORD                             | PGPASSWORD 대신 PGPASSFILE 사용                                       | nil                                        |
| REPMGR_PASSFILE_PATH                | Path to store passfile                                           | 패스파일을 저장할 경로                                                | $REPMGR_CONF_DIR/.pgpass                   |
| PGCONNECT_TIMEOUT                   | PostgreSQL connection timeout                                    | PostgreSQL 연결 시간 초과                                    | 10                                         |

#### Environment Variables (PGPool)
| Name                                | Description                                                      | 설명                                                         | Default Value                              |
|-------------------------------------|------------------------------------------------------------------|-------------------------------------------------------------|--------------------------------------------|
| PGPOOL_PASSWORD_FILE                | Path to a file that contains the password for the custom user set in the PGPOOL_USERNAME environment variable. This will override the value specified in PGPOOL_PASSWORD. No defaults. | PGPOOL_USERNAME 환경 변수에 설정된 사용자에 대한 비밀번호가 포함된 파일의 경로입니다. 이 값은 PGPOOL_PASSWORD에 지정된 값을 덮어씁니다. 기본값 없음. | nil                                        |
| PGPOOL_SR_CHECK_PERIOD              | Specifies the time interval in seconds to check the streaming replication delay. Defaults to 30. | 스트리밍 복제 지연을 확인하는 시간 간격(초)을 지정합니다. 기본값은 30입니다. | 30                                         |
| PGPOOL_SR_CHECK_USER                | Username to use to perform streaming checks. This is the user that is used to check that streaming replication is working. Typically, this is the user owner of the 'repmgr' database. No defaults. | 스트리밍 검사를 수행하는 데 사용할 사용자 이름입니다. 일반적으로 'repmgr' 데이터베이스의 소유자입니다. 기본값 없음. | nil                                        |
| PGPOOL_SR_CHECK_PASSWORD            | Password to use to perform streaming checks. No defaults. | 스트리밍 검사를 수행하는 데 사용할 비밀번호입니다. 기본값 없음. | nil                                        |
| PGPOOL_SR_CHECK_PASSWORD_FILE       | Path to a file that contains the password to use to perform streaming checks. This will override the value specified in PGPOOL_SR_CHECK_PASSWORD. No defaults. | 스트리밍 검사를 수행하는 데 사용할 비밀번호가 포함된 파일의 경로입니다. 이 값은 PGPOOL_SR_CHECK_PASSWORD에 지정된 값을 덮어씁니다. 기본값 없음. | nil                                        |
| PGPOOL_SR_CHECK_DATABASE            | Database to use to perform streaming checks. Defaults to postgres. | 스트리밍 검사를 수행하는 데 사용할 데이터베이스입니다. 기본값은 postgres입니다. | postgres                                   |
| PGPOOL_BACKEND_NODES                | Comma separated list of backend nodes in the cluster. No defaults. | 클러스터의 백엔드 노드 목록을 쉼표로 구분합니다. 기본값 없음. | nil                                        |
| PGPOOL_ENABLE_LDAP                  | Whether to enable LDAP authentication. Defaults to no. | LDAP 인증을 활성화할지 여부를 지정합니다. 기본값은 no입니다. | no                                         |
| PGPOOL_DISABLE_LOAD_BALANCE_ON_WRITE| Specify load balance behavior after write queries appear ('off', 'transaction', 'trans_transaction', 'always'). Defaults to 'transaction'. | 쓰기 쿼리가 나타난 후 로드 밸런스 동작을 지정합니다 ('off', 'transaction', 'trans_transaction', 'always'). 기본값은 'transaction'입니다. | transaction                                |
| PGPOOL_ENABLE_LOAD_BALANCING        | Whether to enable Load-Balancing mode. Defaults to yes. | 로드 밸런싱 모드를 활성화할지 여부를 지정합니다. 기본값은 yes입니다. | yes                                        |
| PGPOOL_ENABLE_STATEMENT_LOAD_BALANCING | Whether to decide the load balancing node for each read query. Defaults to no. | 각 읽기 쿼리에 대해 로드 밸런싱 노드를 결정할지 여부를 지정합니다. 기본값은 no입니다. | no                                         |
| PGPOOL_ENABLE_POOL_HBA              | Whether to use the pool_hba.conf authentication. Defaults to yes. | pool_hba.conf 인증을 사용할지 여부를 지정합니다. 기본값은 yes입니다. | yes                                        |
| PGPOOL_ENABLE_POOL_PASSWD           | Whether to use a password file specified by PGPOOL_PASSWD_FILE for authentication. Defaults to yes. | 인증을 위해 PGPOOL_PASSWD_FILE에 지정된 비밀번호 파일을 사용할지 여부를 지정합니다. 기본값은 yes입니다. | yes                                        |
| PGPOOL_PASSWD_FILE                  | The password file for authentication. Defaults to pool_passwd. | 인증을 위한 비밀번호 파일입니다. 기본값은 pool_passwd입니다. | pool_passwd                                |
| PGPOOL_NUM_INIT_CHILDREN            | The number of preforked Pgpool-II server processes. It is also the concurrent connections limit to Pgpool-II from clients. Defaults to 32. | 미리 포크된 Pgpool-II 서버 프로세스의 수입니다. 또한 클라이언트에서 Pgpool-II로의 동시 연결 제한입니다. 기본값은 32입니다. | 32                                         |
| PGPOOL_RESERVED_CONNECTIONS         | When this parameter is set to 1 or greater, incoming connections from clients are not accepted with error message "Sorry, too many clients already", rather than blocked if the number of current connections from clients is more than (num_init_children - reserved_connections). Defaults to 0. | 이 매개변수가 1 이상으로 설정되면 클라이언트의 현재 연결 수가 (num_init_children - reserved_connections)보다 많을 경우 "Sorry, too many clients already"라는 오류 메시지와 함께 클라이언트의 연결이 차단되지 않고 거부됩니다. 기본값은 0입니다. | 0                                          |
| PGPOOL_MAX_POOL                     | The maximum number of cached connections in each child process. Defaults to 15. | 각 자식 프로세스에서 캐시된 연결의 최대 수입니다. 기본값은 15입니다. | 15                                         |
| PGPOOL_CHILD_MAX_CONNECTIONS        | Specifies the lifetime of a Pgpool-II child process in terms of the number of client connections it can receive. Pgpool-II will terminate the child process after it has served child_max_connections client connections and will immediately spawn a new child process to take its place. Defaults to 0 which turns off the feature. | 클라이언트 연결 수 측면에서 Pgpool-II 자식 프로세스의 수명을 지정합니다. Pgpool-II는 child_max_connections 클라이언트 연결을 처리한 후 자식 프로세스를 종료하고 즉시 새 자식 프로세스를 생성하여 이를 대체합니다. 기본값은 0으로 기능이 꺼집니다. | 0                                          |
| PGPOOL_CHILD_LIFE_TIME              | The time in seconds to terminate a Pgpool-II child process if it remains idle. Defaults to 300. | Pgpool-II 자식 프로세스가 유휴 상태로 유지될 경우 종료되는 시간(초)입니다. 기본값은 300입니다. | 300                                        |
| PGPOOL_CLIENT_IDLE_LIMIT            | The time in seconds to disconnect a client if it remains idle since the last query. Defaults to 0 which turns off the feature. | 마지막 쿼리 이후 유휴 상태로 유지될 경우 클라이언트를 연결 해제하는 시간(초)입니다. 기본값은 0으로 기능이 꺼집니다. | 0                                          |
| PGPOOL_CONNECTION_LIFE_TIME         | The time in seconds to terminate the cached connections to the PostgreSQL backend. Defaults to 0 which turns off the feature. | PostgreSQL 백엔드에 대한 캐시된 연결을 종료하는 시간(초)입니다. 기본값은 0으로 기능이 꺼집니다. | 0                                          |
| PGPOOL_ENABLE_LOG_PER_NODE_STATEMENT | Log every SQL statement for each DB node separately. Defaults to no. | 각 DB 노드에 대해 별도로 모든 SQL 문을 로그합니다. 기본값은 no입니다. | no                                         |
| PGPOOL_ENABLE_LOG_CONNECTIONS       | Log all client connections. Defaults to no. | 모든 클라이언트 연결을 로그합니다. 기본값은 no입니다. | no                                         |
| PGPOOL_ENABLE_LOG_HOSTNAME          | Log the client hostname instead of IP address. Defaults to no. | IP 주소 대신 클라이언트 호스트 이름을 로그합니다. 기본값은 no입니다. | no                                         |
| PGPOOL_LOG_LINE_PREFIX              | Define the format of the log entry lines. Find in the official Pgpool documentation the string parameters. No defaults. | 로그 항목 라인의 형식을 정의합니다. 공식 Pgpool 문서에서 문자열 매개변수를 찾을 수 있습니다. 기본값 없음. | nil                                        |
| PGPOOL_CLIENT_MIN_MESSAGES          | Set the minimum message levels are sent to the client. Find in the official Pgpool documentation the supported values. Defaults to notice. | 클라이언트에 전송되는 최소 메시지 수준을 설정합니다. 공식 Pgpool 문서에서 지원되는 값을 찾을 수 있습니다. 기본값은 notice입니다. | notice                                     |
| PGPOOL_POSTGRES_USERNAME            | Postgres administrator user name, this will be use to allow postgres admin authentication through Pgpool. | Postgres 관리자 사용자 이름으로, 이를 통해 Pgpool을 통한 postgres 관리자 인증이 가능합니다. | nil                                        |
| PGPOOL_POSTGRES_PASSWORD            | Password for the user set in PGPOOL_POSTGRES_USERNAME environment variable. No defaults. | PGPOOL_POSTGRES_USERNAME 환경 변수에 설정된 사용자의 비밀번호입니다. 기본값 없음. | nil                                        |
| PGPOOL_ADMIN_USERNAME               | Username for the pgpool administrator. No defaults. | pgpool 관리자의 사용자 이름입니다. 기본값 없음. | nil                                        |
| PGPOOL_ADMIN_PASSWORD               | Password for the user set in PGPOOL_ADMIN_USERNAME environment variable. No defaults. | PGPOOL_ADMIN_USERNAME 환경 변수에 설정된 사용자의 비밀번호입니다. 기본값 없음. | nil                                        |
| PGPOOL_HEALTH_CHECK_USER            | Specifies the PostgreSQL user name to perform health check. Defaults to value set in PGPOOL_SR_CHECK_USER. | 상태 검사를 수행할 PostgreSQL 사용자 이름을 지정합니다. 기본값은 PGPOOL_SR_CHECK_USER에 설정된 값입니다. | PGPOOL_SR_CHECK_USER에 설정된 값           |
| PGPOOL_HEALTH_CHECK_PASSWORD        | Specifies the PostgreSQL user password to perform health check. Defaults to value set in PGPOOL_SR_CHECK_PASSWORD. | 상태 검사를 수행할 PostgreSQL 사용자 비밀번호를 지정합니다. 기본값은 PGPOOL_SR_CHECK_PASSWORD에 설정된 값입니다. | PGPOOL_SR_CHECK_PASSWORD에 설정된 값       |
| PGPOOL_HEALTH_CHECK_PERIOD          | Specifies the interval between the health checks in seconds. Defaults to 30. | 상태 검사 간격(초)을 지정합니다. 기본값은 30입니다. | 30                                         |
| PGPOOL_HEALTH_CHECK_TIMEOUT         | Specifies the timeout in seconds to give up connecting to the backend PostgreSQL if the TCP connect does not succeed within this time. Defaults to 10. | 이 시간 내에 TCP 연결이 성공하지 않으면 백엔드 PostgreSQL 연결을 포기하는 시간(초)을 지정합니다. 기본값은 10입니다. | 10                                         |
| PGPOOL_HEALTH_CHECK_MAX_RETRIES     | Specifies the maximum number of retries to do before giving up and initiating failover when health check fails. Defaults to 5. | 상태 검사 실패 시 포기하고 장애 조치를 시작하기 전에 최대 재시도 횟수를 지정합니다. 기본값은 5입니다. | 5                                          |
| PGPOOL_HEALTH_CHECK_RETRY_DELAY     | Specifies the amount of time in seconds to sleep between failed health check retries. Defaults to 5. | 상태 검사 재시도 실패 시 대기할 시간(초)을 지정합니다. 기본값은 5입니다. | 5                                          |
| PGPOOL_CONNECT_TIMEOUT              | Specifies the amount of time in milliseconds before giving up connecting to backend using connect() system call. Default is 10000. | connect() 시스템 호출을 사용하여 백엔드에 연결을 포기하기 전의 시간(밀리초)을 지정합니다. 기본값은 10000입니다. | 10000                                      |
| PGPOOL_HEALTH_CHECK_PSQL_TIMEOUT    | Specifies the maximum amount of time in seconds function pgpool_healthcheck() waits for result of show pool_nodes command. It is set to PGCONNECT_TIMEOUT of respective psql execution. Default is 15. | pgpool_healthcheck() 함수가 show pool_nodes 명령의 결과를 기다리는 최대 시간(초)을 지정합니다. 이는 해당 psql 실행의 PGCONNECT_TIMEOUT으로 설정됩니다. 기본값은 15입니다. | 15                                         |
| PGPOOL_USER_CONF_FILE               | Configuration file to be added to the generated config file. This allow to override configuration set by the initializacion process. No defaults. | 생성된 구성 파일에 추가할 구성 파일입니다. 이를 통해 초기화 프로세스에서 설정된 구성을 덮어쓸 수 있습니다. 기본값 없음. | nil                                        |
| PGPOOL_USER_HBA_FILE                | Configuration file to be added to the generated hba file. This allow to override configuration set by the initialization process. No defaults. | 생성된 hba 파일에 추가할 구성 파일입니다. 이를 통해 초기화 프로세스에서 설정된 구성을 덮어쓸 수 있습니다. 기본값 없음. | nil                                        |
| PGPOOL_POSTGRES_CUSTOM_USERS        | List of comma or semicolon separated list of postgres usernames. This will create entries in pgpool_passwd. No defaults. | 쉼표 또는 세미콜론으로 구분된 postgres 사용자 이름 목록입니다. 이는 pgpool_passwd에 항목을 생성합니다. 기본값 없음. | nil                                        |
| PGPOOL_POSTGRES_CUSTOM_PASSWORDS    | List of comma or semicolon separated list for postgresql user passwords. These are the corresponding passwords for the users in PGPOOL_POSTGRES_CUSTOM_USERS. No defaults. | 쉼표 또는 세미콜론으로 구분된 postgresql 사용자 비밀번호 목록입니다. 이는 PGPOOL_POSTGRES_CUSTOM_USERS의 사용자에 대한 해당 비밀번호입니다. 기본값 없음. | nil                                        |
| PGPOOL_AUTO_FAILBACK                | Enables pgpool [auto_failback](https://www.pgpool.net/docs/latest/en/html/runtime-config-failover.html). Default to no. | pgpool [auto_failback](https://www.pgpool.net/docs/latest/en/html/runtime-config-failover.html)을 활성화합니다. 기본값은 no입니다. | no                                         |
| PGPOOL_BACKEND_APPLICATION_NAMES    | Comma separated list of backend nodes application_name. No defaults. | 백엔드 노드의 application_name 목록을 쉼표로 구분합니다. 기본값 없음. | nil                                        |
| PGPOOL_AUTHENTICATION_METHOD        | Specifies the authentication method('md5', 'scram-sha-256'). Defaults to scram-sha-256. | 인증 방법('md5', 'scram-sha-256')을 지정합니다. 기본값은 scram-sha-256입니다. | scram-sha-256                              |
| PGPOOL_AES_KEY                      | Specifies the AES encryption key used for 'scram-sha-256' passwords. Defaults to random string. | 'scram-sha-256' 비밀번호에 사용되는 AES 암호화 키를 지정합니다. 기본값은 무작위 문자열입니다. | 무작위 문자열                               |
| POSTGRESQL_POSTGRES_PASSWORD        | Password for postgres user. No defaults. | postgres 사용자의 비밀번호입니다. 기본값 없음. | nil                                        |
| POSTGRESQL_POSTGRES_PASSWORD_FILE   | Path to a file that contains the postgres user password. This will override the value specified in POSTGRESQL_POSTGRES_PASSWORD. No defaults. | postgres 사용자 비밀번호가 포함된 파일의 경로입니다. 이 값은 POSTGRESQL_POSTGRES_PASSWORD에 지정된 값을 덮어씁니다. 기본값 없음. | nil                                        |
| POSTGRESQL_USERNAME                 | Custom user to access the database. No defaults. | 데이터베이스에 액세스하기 위한 사용자 정의 사용자입니다. 기본값 없음. | nil                                        |
| POSTGRESQL_DATABASE                 | Custom database to be created on first run. No defaults. | 처음 실행 시 생성할 사용자 정의 데이터베이스입니다. 기본값 없음. | nil                                        |
| POSTGRESQL_PASSWORD                 | Password for the custom user set in the POSTGRESQL_USERNAME environment variable. No defaults. | POSTGRESQL_USERNAME 환경 변수에 설정된 사용자 정의 사용자의 비밀번호입니다. 기본값 없음. | nil                                        |
| POSTGRESQL_PASSWORD_FILE            | Path to a file that contains the password for the custom user set in the POSTGRESQL_USERNAME environment variable. This will override the value specified in POSTGRESQL_PASSWORD. No defaults. | POSTGRESQL_USERNAME 환경 변수에 설정된 사용자 정의 사용자의 비밀번호가 포함된 파일의 경로입니다. 이 값은 POSTGRESQL_PASSWORD에 지정된 값을 덮어씁니다. 기본값 없음. | nil                                        |
| REPMGR_USERNAME                     | Username for repmgr user. Defaults to repmgr. | repmgr 사용자의 사용자 이름입니다. 기본값은 repmgr입니다. | repmgr                                     |
| REPMGR_PASSWORD_FILE                | Path to a file that contains the repmgr user password. This will override the value specified in REPMGR_PASSWORD. No defaults. | repmgr 사용자 비밀번호가 포함된 파일의 경로입니다. 이 값은 REPMGR_PASSWORD에 지정된 값을 덮어씁니다. 기본값 없음. | nil                                        |
| REPMGR_PASSWORD                     | Password for repmgr user. No defaults. | repmgr 사용자의 비밀번호입니다. 기본값 없음. | nil                                        |
| REPMGR_PRIMARY_HOST                 | Hostname of the initial primary node. No defaults. | 초기 기본 노드의 호스트 이름입니다. 기본값 없음. | nil                                        |
| REPMGR_PARTNER_NODES                | Comma separated list of partner nodes in the cluster. No defaults. | 클러스터의 파트너 노드 목록을 쉼표로 구분합니다. 기본값 없음. | nil                                        |
| REPMGR_NODE_NAME                    | Node name. No defaults. | 노드 이름입니다. 기본값 없음. | nil                                        |
| REPMGR_NODE_NETWORK_NAME            | Node hostname. No defaults. | 노드 호스트 이름입니다. 기본값 없음. | nil                                        |
| POSTGRESQL_CLUSTER_APP_NAME         | Node application_name. In the case you are enabling auto_failback, each node needs a different name. Defaults to walreceiver. | 노드 application_name입니다. auto_failback을 활성화하는 경우 각 노드에는 다른 이름이 필요합니다. 기본값은 walreceiver입니다. | walreceiver                                |


#### Docker Compose
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

