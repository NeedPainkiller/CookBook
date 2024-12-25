# PostgreSQL Properties

- postgresql.conf 파일을 수정하여 데이터베이스 서버의 동작을 제어할 수 있다.

## 사전 지식
### WAL (Write-ahead logging / 로그 선행 기입)
- DB 의 수정사항을 물리적인 저장장치에 저장하기 이전에 미리 적재해 두는 로그
- `Shared Memory` 에 상주하는 `WAL Buffer` 에 우선 저장 후, 특정 시점에 `WAL Writer`에 의해 `WAL 파일` 에 로그형태로 저장된다.
- DISK IO, NETWORK IO 로 인한 OverHead 가 발생하므로 물리적인 기록 이전에 선행하는 작업이다
- 트랜잭션이 시작하면 로그에 우선 기록한 뒤 트리거 또는 요청에 의해 flush 하여 DataBlock 으로 write

### Shared Buffer
- DISK I/O를 최소화하기 위해 레지스터 처럼 주로 사용하는 `block` 을 `Shared Memory`에 상주할 수 있도록 하는 버퍼

### bg_writer
- 주기적으로 `Shared Buffer` 의 버퍼를 물리적 DISK 의 데이터 파일 (`base`) 에 기록하는 프로세서

### Checkpoint
- 모든 `PostgreSQL` 의 데이터 파일이 WAL 에서 물리적으로 DISK Write 되는 시점을 의미한다.

### Vacuum
- PostgreSQL 의 `MVCC` 처리 방식에서 `dead tuple` 이 발생한다.
- `dead tuple` 을 정리하기 위한 `GC` 같은 존재가 `vacuum` 이다.

### MVCC (Multi-Version Concurrency Control)
- `MVCC`는 `Transaction ID` 를 기반으로 DBMS 에서의 동시성을 보장한다
- 다수의 트랜잭션이 수행되는 런타임에서 각 트랜잭션에게 쿼리 수행시점을 전달하여 읽기 일관성을 유지한다.
- `Read/Write` 간 충돌 & `Lock` 을 방지하여 동시성을 높인다.
- PostgreSQL 의 `MVCC는` ORACLE, MySQL 과 동작방식이 달라 그 특징을 이해해야 한다.
  - ORACLE, MySQL 의 `MVCC` 는 `UNDO segment(Rollback segment)` 를 기반으로한다
  - Oracle : 타 트랜잭션에 의해 변경된 블록이 확인 될 경우, 원본 블록으로 부터 `CR Copy` 를 만들어, 해당 복사본 블록에 `UNDO segment` 를 걸어, 쿼리의 시작시점으로 restore 한 뒤 읽는다.
  - MySQL : 트랜잭션 내 변경된 정보가 `UNDO segment` 에 선 저장되고, 그 이후 변경 내용들을 Linked List 처럼 포인터 형태로 연결하는 모습을 보인다. 신규 트랜잭션이 수행될 경우, 해당 포인터를 기준으로 리스트를 역조회 하여 트랜잭션 ID 를 비교, 자신이 읽을 수 있는 시점의 Data 를 확인한다.
- PostgreSQL 의 경우 insert/update 시점의 트랜잭션 ID 를 갖는 `xmin` 메타데이터 필드와 delete/update 시점의  `Transaction ID` 를 같는 `xmax` 메타데이터 필드를 가진다
  - 각 `tuple (record)` 별로 `xmin`, `xmax` 을 가지며 각 필드가 가진 `Transaction ID` 를 검토하여 조회한다
  - update된 데이터의 저장이 완료되면 update 이전의 원본 `tuple` 을 가리키던 포인터를 새로 update된 `tuple` 을 가리키도록 업데이트 함
  - 간략하게 insert/update/delete 때마다 각 `tuple` 의 버젼정보와 로그가 기록되고 있다고 보면 된다
  - [작동방식 설명](https://techblog.woowahan.com/9478/)
- `xmin`, `xmax` 은 FSM(FreeSpaceMap) 에 저장된다.

#### Dead Tuple
- update 이전의 원본 `tuple` 은 update 후 포인터가 새로 지정되면서 유기된다.
- 아무도 참조하지 않는 해당 `tuple` 을 `dead tuple` 이라고 하며, JVM 환경에서의 미 참조 오브젝트에 빗댈 수 있다.
- `dead tuple` 또한 `page` 에 포함되어, 쿼리에 영향을 주게되고, 단일 `page` 는 **8kb** 가 기본이기 때문에, `dead tuple` 이 늘어날 수록 `live tuple` 의 조회가능 크기가 줄어들어 DISK IO 가 필수적으로 발생하게된다.
- 해당 `dead tuple` 이 차지하고 있는 `FSM` 메모리 점유를 정리하기 위해 `vacuum` 이 필요하다.

#### Vacuum Full
- `vacuum` 또한 `vacuum full` 과 일반 `vacuum` 이 있는데, `dead tuple` 이 발생하면서 생긴 물리적인 디스크 용량에 의해 쿼리 검색이 느려지며, `vacuum full` 은 여기서 물리디스크의 할당된 크기까지 초기화하여 회수할 수 있다.
  - `vacuum` 은 특정 case 가 아닌 경우 할당된 물리적 디스크를 반납하지 않기에, 테이블 사이즈는 유지되나, `FSM` 에 할당된 위치는 반납한다. 
  - `vacumm full` 은 조회 Lock 까지 적용하여 수행해야 하는 문제가 있어 운영 환경에서는 진행하기 어려우며, 해당 테이블을 전체 COPY 후 Log Table 의 변경사항을 업데이트하고 원본 테이블로 swap 하는 방식이기 때문에, 추가적인 물리 디스크 용량을 필요로 한다.

#### Transaction ID Wraparound
- `xmin`, `xmax` 에 저장되는 `Transaction ID` 는 최대 `4byte` 값을 가지며, 약 42억(2^32 - 1) 까지의 id 가 발급된다.
- `Transaction ID` 는 순차적으로 발급되기 때문에 `Transaction ID` 가 42억 값을 넘어가는 순간부터 다시 처음으로 회송되어 1부터 발급 받게 된다.
- 이 순간 `Transaction ID` 는 과거/미래간 `Transaction` 의 데이터 보장을 위해 과거는 n보다 작은 값, 미래는 n보다 큰 값으로 유추하는데
- `Transaction ID` 가 1로 회송되는 순간 그 이전의 "과거" 데이터가 "미래"의 변경 건으로 전환되어 버리기에 과거 데이터가 모두 유실된다.

#### Anti Wraparound Vacuum
- `Transaction ID Wraparound` 를 방지하기 위해 PostgreSQL 의 `MVCC` 는 `table`, `tuple` 에 `age` 를 생성한다
- `age` 는 insert 시 **1** 부터 시작하여 해당 테이블에 대한 `Transaction` 이 아니더라도 DB 내에 `Transaction` 이 발생할 때 마다 모든 오브젝트의 `age` 가 1 증가한다.
- `age` 가 특점 임계값을 초과하는 시점부터 `Transaction ID Wraparound` 를 방지하기 위한 `Anti Wraparound Vacuum` 의 처리 대상이 된다.
- `Anti Wraparound Vacuum` 이 수행되면 `age` 는 `freeze` 되어 `frozen XID = 2` 라는 특수한 `Transaction ID` 로 변환된다.
- 각 `table age` 와 `tuple age` 는 `Anti Wraparound Vacuum` 에 의헤 age 가 재조정되어 감소하게 된다. (`freezing`)
  - `tuple age` : `Anti Wraparound Vacuum` 수행 시 `tuple` 대상 채로 `freeze` 되어 `vacuum_freeze_min_age`(def : 50,000,000)  보다 높은경우 대상에 포함된다.
  - `table age` : `freeze` 대상에 포함되지는 않으나, `table age` 테이블에 속한 `tuple` 중 가장 높은 `tuple age` 로 설정되며, `table age` 를 참조함으로서 테이블이 `freeze` 대상이 되는지 짐작 할 수 있다.
    - `vacuum_freeze_table_age`, `autoacuum_freeze_table_max_age` 값을 기준으로 `table age` 를 검사하여 `Anti Wraparound Vacuum` 를 수행한다.
  
#### Vacumm 의 수행 기준
  - `dead tuple` 의 개수의 누적치가 임계치에 도달했을 때 수행 
  - `tuple age` or `table age` 가 누적되어 임계치에 도달했을 때 수행

##### Dead Tuple 의 누적 임계치 초과
```js
vacuum threshold = autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor * [number of Tuple]
```
```PostgreSQL
testdb=# select name,setting from pg_settings where name in ('autovacuum_vacuum_scale_factor', 'autovacuum_vacuum_threshold');
              name              | setting
--------------------------------+---------  
autovacuum_vacuum_scale_factor | 0.2  
autovacuum_vacuum_threshold    | 50
```
- `autovacuum_vacuum_scale_factor` : 테이블의 전체 `Tuple` 개수 중 설정한 비율만큼의 데이터가 변경되면 해당 테이블에 대해 `AutoVacuum`. (def : 0.2)
- `autovacuum_vacuum_threshold` : 의미는 `autovacuum_vacuum_scale_factor와` 동일하지만, 비율이 아니라 테이블 내 변경된 `Tuple` 개수로 판단. (def : 50)
- > 테이블 내 `dead tuple` 누적치가 테이블의 모든 행 중 20% + 50개를 초과하는 경우. `AutoVacuum` 수행

##### Tuple Age / Table Age 의 누적되어 임계치 초과
```PostgreSQL
testdb=# select name,setting from pg_settings where name like '%freeze%';
                name                 |  setting
-------------------------------------+-----------
 autovacuum_freeze_max_age           | 200000000
 vacuum_freeze_min_age               | 50000000
 vacuum_freeze_table_age             | 150000000
```

- `autovacuum_freeze_max_age`: 해당 값을 초과하는 `table age`에 대해 `Anti Wraparound AutoVacuum` 을 수행, `AutoVacuum을` off해도 강제로 수행
- `vacuum_freeze_min_age`: 해당 값을 초과하는 `age` 의 테이블 에 대해 `vacuum` 작업 시 `Transaction ID` 의 `freeze` 작업의 대상으로 한다. `Anti Wraparound AutoVacuum` 수행 이후 `table age`는 최대 `vacuum_freeze_min_age` 값으로 설정됨
- `vacuum_freeze_table_age`: 해당 값을 초과하는 `age` 의 테이블에 대해 `vacuum` 호출될 때 `frozen` 작업도 같이 수행함
  - 다수의 테이블들이 `autovacuum_freeze_max_age` 에 걸려서 동시에 `Anti Wraparound AutoVacuum` 이 수행되기 전에, 그전에 `vacuum` 이 호출된 테이블이 `Anti Wraparound AutoVacuum` 으로 돌도록 분산하는 효과

### pg_dump 시 빠른 데이터 복구 또는 재설정
- dump 를 통해 입력 작업 시 빠른 DISK IO 를 확보하는 것이 제일 중요하다

#### fsync
- 설정 : off
- `PostgreSQL` 의 데이터 파일 (`global`, `base` Directory) 과 트랜잭션 로그조각 파일 (`pg_xlog` Directory) 은 DISK R/W 작업이 필수적으로 일어난다.
- 위 두 위치에서의 물리적인 디스크 쓰기가 많아지며 dump 작업 시 DB 전체를 재생성하는 경우에 고려하도록 하자
- 'on' 일 경우에 `fsync()` 시스템 콜을 사용하게 되며, 변경분을 DISK 에 직접 Write 하며, OS 또는 HW 이슈 발생시 일관성을 유지하도록 한다.
- 'off' 일 경우에는 OS 에게 DISK Write 책임이 넘어가게 되면서, 성능상 우위는 확보되나 DISK 에 정상 기입되었는지 확인하기 어려워 OS 및 HW 이슈에 대응하기 힘들다
- 그 외 read-only 데이터베이스에 복제하거나 fail-over 에 사용하지 않는 경우에 사용할 것

#### synchronous_commit 
- 설정 : off
- `commit` 된 `Transaction` 은 `pg_xlog` 트랜잭션 로그조각 파일에 기록되어야 한다. (테이블이 `unlogged` 일 경우 예외)
- `pg_xlog` 에 저장 (DISK) 되기 전에 `WAL 버퍼`에 기록되는데, 이 처리과정에서 어느 시점을 기준으로 기록을 확인할 지 정하는 것이다.
- 'on' : `WAL 버퍼` > `pg_xlog` 에 저장, 즉 DISK 에 저장되었을 경우 리턴한다
- 'off' : `WAL 버퍼` 에 저장되는 시점에 바로 리턴한다. 이후 DISK 저장시 까지는 일부 delay 가 존재한다.
  - 이 경우 안정성을 보장하기 어려워 DISK 에 저장되지 않은 `commit` 은 DB/OS 시스템 장애시 복구하지 못하고 손실된다.
- 'remote_write' : HA 구성 시 remote 인스턴스의 DISK 단계까지 저장되었을 경우 리턴
  - remote 인스턴스의 OS 시스템 장애 시 복구 어려울 수 있음
- 'local' : HA 구성 시 master 인스턴스의 DISK 에 저장 시 리턴

#### full_page_writes 
- 설정 : off
- `PostgreSQL` 은 기본적으로(`full_page_writes` = 'on')  `Checkpoint` 후 해당 데이터 page 의 첫 변경시 해당 페이지의 모든 정보를 트랜잭션 로그에 기록한다.
- 'off' 로 설정한 경우 데이터 page 가 손상되지 않았음을 전제로 진행된다. 위 `fsync` 와 `synchronous_commit` 이 'off' 상태인 경우 같이 'off' 설정 한다.

#### checkpoint_segments 
- `checkpoint_segments` * 16mb 만큼의 트랜잭션 로그조각 파일을 저장 할 수 있다.
- DISK 여유가 있는 한 `checkpoint_segments` * 15 개 가량의 트랜잭션 로그 조각 파일이 생성된다
- 대용량 자료 입력에서는 신규 트랜잭션 로그 조각 파일을 만들어 내지 않도록, 로그 조각 파일을 재활용 할 수 있게 유도해야한다.
- OS 가 허용 하는 한 최대로 지정함이 좋다
- `txid_crruent()`, `pg_switch_xlog()` 함수를 미리 호출하여 사전에 트랜잭션 로그 조각 파일을 우선 확보하는 방법도 추천한다.

#### maintenance_work_mem 
- 대용량 자료 입력시 INDEX 작업을 후속으로 진행하게 되는데, 이 때 사용할 수 있는 메모리를 OS 가 허용하는 최대로 설정함이 좋다.

#### wal_level 
- 설정 : minimal
- 디스크 I/O 최소화

#### archive_mode  
- 설정 : off
- 디스크 I/O 최소화
- https://rastalion.dev/415/

#### autovacuum
- 설정 : off
- 입력 작업 도중 불필요한 `vacumm` 작업을 방지.
- 이후 다시 활성화 할 것


## Properties
- shared_buffers: 데이터베이스 서버가 공유 메모리 버퍼에 사용하는 메모리 양
  - 권장: 256MB (사용 가능한 메모리에 따라 달라짐)
  - 선택: 유효한 메모리 크기 (e.g., 128MB, 512MB, 1GB)
- wal_level: WAL (Write-Ahead Log) 에 기록되는 정보 수준을 설정합니다   
  - 권장: replica (복제 설정의 경우)
  - 선택: minimal, replica, logical
- archive_mode: WAL 아카이브를 활성화합니다.
  - 권장: on
  - 선택: on, off
- archive_command: 완료된 WAL 파일 세그먼트를 보관하는 데 사용할 쉘 명령을 지정합니다.  
  - 권장: cp %p /path/to/archive/%f (필요에 따라 경로 조정)
  - 선택: Any valid shell command
- effective_cache_size: 운영 체제 및 데이터베이스 자체에서 디스크 캐싱에 사용할 수 있는 메모리의 추정치입니다.
  - 권장: 512MB (사용 가능한 메모리에 따라 달라집니다)
  - 선택: 유효한 메모리 크기 (e.g., 256MB, 1GB, 2GB)
- min_wal_size: 메모리 상에서 적재할 수 있는 WAL 최소 크기입니다.
  - 권장: 80MB
  - 선택: 유효한 메모리 크기 (e.g., 40MB, 100MB)
- max_wal_size: 메모리 상에서 적재할 수 있는 WAL 최대 크기입니다.
  - 권장: 1GB
  - 선택: 유효한 메모리 크기 (e.g., 500MB, 2GB)
- logging_collector: 로그 파일에 대한 로그 메시지 수집을 활성화합니다.
  - 권장: on
  - 선택: on, off
- log_line_prefix: 각 로그 라인에 접두사가 붙은 정보를 제어합니다.  
  - 권장: %t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h
  - 선택: 유효한 형식 문자열
- autovacuum_max_workers: 최대 자동 autovacuum 수를 설정합니다.
  - 권장: 3
  - 선택: 정수 형 값 (e.g., 1, 5, 10)
- timezone: 타임스탬프를 표시하고 해석할 시간대를 설정합니다.
  - 권장: UTC
  - 선택: 유효한 Timezone 값 (e.g., UTC, America/New_York)
- log_timezone: 로그 메시지의 타임스탬프에 사용되는 시간대를 설정합니다.
  - 권장: UTC
  - 선택: 유효한 Timezone 값 (e.g., UTC, America/New_York)



### Docker

#### Environment
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

#### docker-compose.yml
```YAML
version: '3.8'
services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    command: |
      postgres -c shared_buffers=256MB \
               -c wal_level=replica \
               -c archive_mode=on \
               -c archive_command='cp %p /path/to/archive/%f' \
               -c effective_cache_size=512MB \
               -c min_wal_size=80MB \
               -c max_wal_size=1GB \
               -c logging_collector=on \
               -c log_line_prefix='%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h' \
               -c autovacuum_max_workers=3 \
               -c timezone=UTC \
               -c log_timezone=UTC
    volumes:
      - ./path/to/archive:/path/to/archive
    ports:
      - "5432:5432"
```


https://techblog.woowahan.com/9478/
http://minsql.com/postgres/PostgreSQL-synchronous_commit-%EA%B0%9C%EB%85%90%EB%8F%84/
