# PostgreSQL Properties

- postgresql.conf 파일을 수정하여 데이터베이스 서버의 동작을 제어할 수 있다.

## 사전 지식
### WAL (Write-ahead logging / 로그 선행 기입)
- DB 의 수정사항을 물리적인 저장장치에 저장하기 이전에 미리 적재해 두는 로그
- DISK IO, NETWORK IO 로 인한 OverHead 가 발생하므로 물리적인 기록 이전에 선행하는 작업이다
- 트랜잭션이 시작하면 로그에 우선 기록한 뒤 트리거 또는 요청에 의해 flush 하여 DataBlock 으로 write

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

### Vacuum
- PostgreSQL 의 `MVCC` 처리 방식에서 `dead tuple` 이 발생한다.
- `dead tuple` 을 정리하기 위한 `GC` 같은 존재가 `vacuum` 이다.

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


### Docker 예시
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