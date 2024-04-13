# Nginx 튜닝 가이드

- 일반적으로 Nginx 는 기본 설정으로도 충분히 빠르게 동작하지만, 특정 상황에 따라 성능을 향상시키기 위해 설정을 변경할 수 있다.
- nginx 는 Intel Xeon CPU 환경에서 초당 400K ~ 500K 요청(클러스터링)을 처리할 수 있으며, 대부분 초당 50K ~ 80K(비클러스터링) 요청 및 30% CPU 로드에 준한다.

## Root 영역


```nginx
--- nginx.conf ---
user www-data;

worker_processes  auto;
worker_rlimit_nofile 65535;

pid /run/nginx.pid;

events {
  worker_connections  65534;
  use epoll;
  # multi_accept on;
}

```

### user
- Nginx 프로세스를 실행할 사용자를 설정한다.
- Nginx 가 Root 에서 실행되는 경우 모든 파일에 엑세스가 가능해지며, 만약 Nginx 가 모종의 이유로 공격당하거나 취약점이 발견된다면 공격자가 Root 권한을 획득할 수 있다.
- 이를 위해서 Nginx 는 Nobody 등의 특정 사용자 를 지정하는 것이 좋다.
- www-data 는 Ubuntu 에서 사용하는 사용자이며, CentOS 에서는 nginx 또는 nobody 를 사용한다.
- 권한 문제를 방지하고자 할 경우 도메인 문서 루트 디렉토리의 소유권을 www-data 로 변경해야 한다.
```Bash
sudo chown -R www-data: /var/www/xxx.com 
```

### worker_processes
- CPU 코어 수에 맞춰 설정하는 것이 좋으나, 수동으로 할 핋요 없이"auto" 로 설정하면 알아서 CPU 코어 수에 맞춰 설정해준다.
- 물론 이는 해당 서버가 Nginx 전용 서버일 경우에만 해당되며, 다른 서비스와 함께 동작하는 경우에는 적절한 값을 설정해야 한다.
- 컨테이너 환경에서는 CPU 코어 수를 직접 지정하지 않는 이상 "auto"로 설정하는 것이 좋다.

### worker_rlimit_nofile
- 실행되는 프로세스의 파일 디스크립터 수를 설정한다.
- 설정하지 않으면 기본적으로 2000인 OS 설정이 적용된다.
- 최대 제한은 일반적으로 OS에 의해 제한되며, 이 값을 무한대로 설정하는 것은 의미가 없다.

### events
- 연결 처리에 영향을 미치는 지침이 지정된 구성 파일 컨텍스트를 제공합니다.

#### worker_connections
- worker_processes 별 동시 접속 가능한 클라이언트 수를 설정한다.
- 이 값은 worker_processes * worker_connections 값이 최대 동시 접속 가능한 클라이언트 수가 된다.
- 시스템에서 사용 가능한 소켓 연결 수에 의해 제한되므로 이 값을 무한대로 설정하는 것은 의미가 없다.
- 이 값은 서버의 메모리와 CPU 성능에 따라 적절한 값을 설정해야 한다.
- ulimit -n 명령어로 확인 가능하다
```Bash
ulimit -n 
```

#### use
- Connection Processing method 를 설정한다.
  - Nginx는 non-blocking I/O 방식을 사용하므로 요청한 connection file에 read 가능한지를 확인하기 위해 Nginx 프로세스에서 사용하는 Socket 을 지속적으로 확인한다.
  - multi-thread 방식에서는 context-switching을 계속 해야 하므로 이로인한 성능 비용이 발생한다 하지만 Nginx 는 이러한 비용을 줄이기 위해 non-blocking I/O 방식을 사용한다.
  - client 가 많아져 connection 이 많아지면 이러한 비용이 증가하게 되므로 이러한 비용을 줄이기 위해 Connection Processing method 를 설정한다.

- epoll, kqueue, eventport, /dev/poll, select 중 하나를 선택할 수 있다.
- [참조](http://nginx.org/en/docs/events.html)
- epoll 은 리눅스에서 사용하는 방식으로, 리눅스에서는 epoll 을 사용하는 것이 좋다.
  - epoll 을 사용하는 것이 가장 좋은 방식이다.
  - epoll 을 사용하려면 리눅스 커널 2.6.8 이상이 필요하다.
  - epoll 을 사용하려면 Nginx 를 컴파일할 때 --with-epoll 옵션을 사용해야 한다.
  - FD 수가 많아지면 epoll 을 사용하는 것이 좋다.
- kqueue 는 FreeBSD, MacOS 에서 사용하는 방식이다.
- eventport 는 Solaris 에서 사용하는 방식이다.
- /dev/poll 은 Solaris, FreeBSD 에서 사용하는 방식이다.
- select 는 모든 플랫폼에서 사용 가능한 방식이다.
  - poll과 select는 Nginx 프로세스에 연결된 모든 connection file을 스캔하여 read 가능한지를 확인한다. 

#### multi_accept
- [참조](http://nginx.org/en/docs/ngx_core_module.html#multi_accept)
- on 으로 설정하면 한 번에 여러 클라이언트의 연결을 받아들일 수 있다.
- off 로 설정하면 한 번에 하나의 클라이언트의 연결만 받아들일 수 있다.
- on 으로 설정하면 성능이 향상될 수 있는 기회가 있으나 환경에 따라 검증되지 못했고, CPU 사용량이 증가하게 된다.
- 기본적으로 off 상태이며 이 설정에 대해 여러 의견이 있지만, 앞서 설정한 worker_processes, worker_connections 만큼 많은 연결을 요하는 경우 on 으로 설정하는 것이 좋을 수 있다.
- multi_accept 를 on 으로 설정하면, 기존 커널 버전에서는 accept() 시스템 콜을 호출할 때, 커널이 클라이언트의 연결을 받아들일 수 있는 상태가 되기 전까지 Nginx 프로세스가 블로킹되어 있었지만, 이 설정을 on 으로 하면 커널이 클라이언트의 연결을 받아들일 수 있는 상태가 되기 전까지 Nginx 프로세스가 블로킹되지 않고 다른 클라이언트의 연결을 받아들일 수 있다.
- reverse proxy 환경에서는 요청을 받아들이는 서버가 여러 대 있을 수 있으므로 multi_accept 를 on 으로 설정하는 것이 좋을 수 있다.
- 그렇지 않다면 굳이 on 할 필요가 없으며, 오히려 CPU 사용량이 증가하게 되고, 커널의 TCP 스택이 병목이 발생할 수 있다.
- use 에서 kqueue 을 사용한다면, 이 지침은 수락 대기 중인 새로운 연결의 수를 보고하기 때문에 무시된다.
- 하지만 이러한 옵션을 고려해가면서 사용하기에는 Nginx 가 충분히 Single Thread 환경에서의 Event Driven 방식으로 고성능을 발휘할 수 있기 때문에, 이러한 옵션을 사용할 필요가 없으며, 통제된 환경에서의 벤치마킹을 통해 성능 차이와 이슈등을 고려하여 지정하는 것이 좋다.
- [nginx-ru 에 속한 Igor Sysoev 의 답변](https://forum.nginx.org/read.php?21,267183,267526#msg-267526l)
  

## HTTP 영역


```nginx
--- nginx.conf ---
http {
  include /etc/nginx/http.conf;
}

--- http.conf ---
# 응답 문자셋(Content-Type)을 UTF-8 로 지정
charset utf-8;

# Nginx 버젼 노출 금지
server_tokens off;

# WebDAV 사용 금지
dav_methods off;

# 자주 접근하는 파일 대한 FD 캐시를 설정
open_file_cache max=200000 inactive=20s;
open_file_cache_valid 30s;
open_file_cache_min_uses 2;
open_file_cache_errors on;

# 리눅스 서버의 sendfile() 시스템 콜 사용
sendfile on;
sendfile_max_chunk 5m;

# Linux의 TCP_CORK 소켓 옵션을 사용할지 여부
tcp_nopush on;

# Linux의 TCP_NODELAY 소켓 옵션을 사용할지 여부
tcp_nodelay on;

# 미응답 클라이언트의 연결을 하제하고 메모리에서 해제한다
reset_timedout_connection on;

# request 의 Header, Body 를 읽는 시간 제한
client_header_timeout 10s;
client_body_timeout 60s;

# 파일 업로드 크기 제한
client_max_body_size 1G;

# 클라이언트에 응답을 전송하기 위한 타임아웃을 설정
send_timeout 2;

# 요청-응답 이후 클라이언트와 서버 사이의 연결이 유지되는 시간을 설정한다.
keepalive_timeout 30;

#클라이언트가 단일 keepalive 연결을 통해 만들 수 있는 요청 수
keepalive_requests 100000;

# proxied server 로부터 응답을 읽는 timeout 시간
proxy_read_timeout 60s;

# proxied server로 요청을 전송하는 timeout 시간
proxy_send_timeout 60s;

# 로그위치 설정
# HDD의 I/O를 높이기 위해 액세스 로그를 비활성화 하는 것도 추천된다.
access_log off;
# 심각 한 오류만 로그
error_log /var/log/nginx/www_error.log crit;
# error_log /var/log/nginx/crit-error.log crit;
# 존재하지 않는 파일에 대한 로그를 남기지 않음
log_not_found off;

# IP 차단 X
allow all;

map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

```
### charset
- https://nginx.org/en/docs/http/ngx_http_charset_module.html
- Nginx 가 사용하는 문자 인코딩을 설정한다.
- "Content-Type" 응답 헤더 필드에 지정된 문자 세트를 추가하거나 변경한다.

### server_tokens
- https://nginx.org/en/docs/http/ngx_http_core_module.html#server_tokens
- off 로 설정하여 오류 페이지와 응답 `Server` 헤더에 Nginx 버전 정보와 OS 정보를 제외시킨다. 대신 nginx 로만 표시된다.
- 보안상의 이유로 Nginx 버전 정보를 노출시키지 않는 것이 좋다.

### dav_methods
- https://nginx.org/en/docs/http/ngx_http_dav_module.html#dav_methods
- WebDAV 모듈에서 사용할 수 있는 HTTP 메서드를 설정한다.
- 외부에서 접속하여 WebDAV 를 사용하지 않는다면 설정할 필요가 없다.

### FD 캐시 (open_file_cache)
- https://nginx.org/en/docs/http/ngx_http_core_module.html#open_file_cache
- 자주 접근하는 파일 대한 FD 캐시에 대한 설정
- 성능을 향상시킬 수 있지만, 파일이 동적으로 자주 변경되는 경우에는 적합하지 않으며
- 실제 성능 향상에 대해서는 벤치마킹을 통해 확인해야 한다.
- FD (파일 디스크립터)는 다음과 같은 정보를 가진다.
  - 열린 파일 설명자, 크기 및 수정 시간
  - 디렉토리 존재에 관한 정보, 파일이 존재하는 지 아니면 권한으로 인해 읽을 수 없는지 여부

#### open_file_cache
- 자주 접근하는 파일 대한 FD 캐시의 최대 크기를 설정한다.
- max : 캐시의 최대 요소 수
- inactive : 캐시를 엑세스 하지 않은 시간(초)이 지난 후 제거 된다.

#### open_file_cache_valid
- open_file_cache 요소의 유효성을 검사해야 하는 시간을 설정한다.

#### open_file_cache_min_uses
- FD가 캐시에서 열려 있는 상태를 유지하는 데 필요한 open_file_cache 디렉티브의 비활성 매개 변수로 구성된 기간 동안의 최소 파일 액세스 수

#### open_file_cache_errors
- open_file_cache에 의한 파일 조회 오류의 캐싱 여부를 설정한다.

### sendfile 
- https://nginx.org/en/docs/http/ngx_http_core_module.html#sendfile
- https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/
- 리눅스 서버의 sendfile() 시스템 콜을 사용할지 여부를 설정한다.
- sendfile() 은 기본적으로 read() + write() 보다 빠르다.
- 커널에서 최적화된 알고리즘을 통해 파일 전송 속도가 빨라지며 전송에 대한 메모리 사용이 감소되어 고성능 웹서버 구축에 매우 중요한 옵션이다.
- 기본적으로 NGINX는 파일 전송 자체를 처리하고 파일을 전송하기 전에 버퍼에 복사한다. sendfile directive를 활성화하면 데이터를 버퍼에 복사하는 단계가 없어지고 커널 단계에서 한 파일 디스크립터에서 다른 파일 디스크립터로 데이터를 직접 복사할 수 있다

#### sendfile_max_chunk
- sendfile() 시스템 콜을 사용할 때 한 번에 전송할 수 있는 최대 데이터 양을 설정한다.
- 하나의 빠른 연결이 워커 프로세스를 완전히 차지하는 것을 방지하기 위해 sendfile_max_chunk directive를 사용하여 단일 sendfile() 호출에서 전송되는 데이터의 양을 1MB로 제한할 수 있다

### tcp_nopush
- https://nginx.org/en/docs/http/ngx_http_core_module.html#tcp_nopush
- Linux의 TCP_CORK 소켓 옵션을 사용할지 여부를 설정한다.
- sendfile을 사용하는 경우에만 옵션이 활성화 된다.
- sendfile을 통해 Data chunk 를 로드한 후 HTTP 응답 헤더를 하나의 패킷으로 병합한다
- 이후 응답 헤더와 파일의 시작을 하나의 패킷으로 전송하게 되어 네트워크 대역폭을 절약할 수 있다.
- 하지만, 이 옵션을 사용하면 데이터가 버퍼링되어 전송되기 때문에 실시간 데이터 전송 (스트리밍) 에는 적합하지 않을 수 있다. 벤치마킹이 필요한 부분.

### tcp_nodelay
- https://nginx.org/en/docs/http/ngx_http_core_module.html#tcp_nodelay
- 연결이 keep-alive 상태로 전환될 때 TCP_NODELAY 소켓 옵션을 사용할지 여부를 설정한다.
- SSL 연결, 버퍼링되지 않은 프록시 및 WebSocket 프록시에서도 활성화된다.
- 본래 느린 네트워크에서 작은 패킷의 전송 딜레이 문제를 해결하기 위해 설계된 Nagle의 알고리즘을 재정의하는 것을 허용하는 것이며
- 여러 개의 작은 패킷을 더 큰 패킷으로 통합하여 200ms 지연된 상태로 패킷을 전송한다. 요즘에는 큰 정적 파일을 서비스할 때 패킷 크기에 상관없이 데이터를 즉시 보낼 수 있기 때문에, ssh, 온라인 게임, VoIP 등의 실시간 데이터 전송에는 적합하지 않다.
- 이 옵션을 사용하면 데이터가 버퍼링되지 않고 전송되기 때문에 실시간 데이터 전송 (스트리밍) 에 적합하다.

### reset_timedout_connection
- https://nginx.org/en/docs/http/ngx_http_core_module.html#reset_timedout_connection
- keepalive_timeout 이 지난 후 클라이언트가 응답하지 않을 때 연결을 닫을지 여부를 설정한다.
- 또한 기본적으로는 연결과 관련된 메타정보가 메모리에 남아있게 되는데 이를 해제하여 메모리를 확보할 수 있다.
- default : off

### client_header_timeout
- 클라이언트 요청 헤더를 읽기 위한 타임아웃을 정의한다. 이 시간 내에 클라이언트가 전체 헤더를 전송하지 않으면 408(Request Time-out) 오류와 함께 연결을 닫는다
- client_body_timeout 설정과 함께 DDos 의 L7 공격중 하나인 [Slow Post DDos 공격](https://www.netscout.com/what-is-ddos/slow-post-attacks)을 방지할 수 있다.
- default : 60s

### client_body_timeout
- 클라이언트 요청 본문을 읽기 위한 타임아웃(timeout)을 정의한다.  
- 클라이언트가 이 시간 내에 아무것도 전송하지 않으면, 요청은 408(Request Time-out) 오류와 함께 연결을 닫는다.
- DDos 의 L7 공격중 하나인 [Slow Post DDos 공격](https://www.netscout.com/what-is-ddos/slow-post-attacks)을 방지할 수 있다.
- 하지만 실제 파일 업로드 크기가 큰 경우에는 이 값을 적절하게 조정해야 한다.
- default : 60s

### client_max_body_size
- 클라이언트로부터 전송받을 수 있는 최대 요청 바디 크기를 설정한다.
- 이 값을 초과하는 요청이 전송되면 413(Request Entity Too Large) 오류를 반환한다.

### send_timeout
- 클라이언트에 응답을 전송하기 위한 타임아웃을 설정. 이 시간 내에 클라이언트 측에 응답이 전송되지 않으면 연결이 종료된다.
- DDOS 공격은 대부분 전송에만 치중되고 응답은 거의 처리하지 않으므로 요청만 보내고 응답을 받지 않는 경우가 많다. 이런 공격을 대비하여 작은 값으로 설정할 수 있으나, 실제 서비스에서는 적절한 값을 설정해야 한다.
- default : 60

### what is keepalive
- 클라이언트의 연결 요청이 끝난 후에도 연결을 유지하는 것을 keepalive 라고 한다.
- nginx 가 reverse proxy 로 사용되는 경우, upstream 서버와의 연결을 유지하기 위해 keepalive 를 사용할 수 있다.
- nginx 는 요청이 들어오면 클라이언트와 reverse proxy 사이 2번의 3-way-handshake 를 만들어야 하기 때문에 성능 저하가 발생할 수 있다.
- 그에 더에 연결 종료를 위한 4-way handshaking 이 자주 발생한다면 대규모 트래픽을 관리하는 입장에서 timewait 시간동안 제거되지 않는 socket 이 발생하므로 local port 가 부족해지는 문제가 발생할 수 있다.
- keepalive 를 유지하는 것은 리소스 비용을 감수하고서라도 클라이언트간 통신이 매우 잦을 때 사용하는 것이 졸지만, Nginx 프로세스 입장에서는 연결중인 Connection 을 통한 요청이 있을 때까지 기다려야 하는 문제가 생긴다.
- 단일 클라이언트 보다 다수의 클라이언트를 상대로 하는 유동 트래픽이 많을 경우에는 keepalive 가 높으면 타 클라이언트가 연결을 맺을 수 없는 문제가 발생할 수 있다.

#### keepalive_timeout 
- 요청-응답 이후 클라이언트와 서버 사이의 연결이 유지되는 시간을 설정한다.
- 여러차례의 요청을 보내는 경우에는 keepalive_timeout 을 높게 설정하여 세션을 유지함으로서 TCP 3-way handshake을 줄이고 timewait 소켓 생성을 줄일 수 있다.
- timewait 소켓 상태는 리눅스 커널에서 TCP 연결을 끊은 후에도 일정 시간 동안 유지되는 상태로, 이러한 상태가 많아지면 서버의 성능에 영향을 줄 수 있다.
- keepalive_timeout 을 높게 설정하면 성능이 향상될 수 있지만, 클라이언트와 서버 사이의 연결이 계속 유지되므로 서버의 리소스를 많이 사용하게 된다.
- `keepalive` 를 설정하여 worker 프로세스에 대해 열려있는 upstream 서버에 대한 keepalive 연결 수를 지정할 수 있다.
- default : 75

#### keepalive_requests
- 클라이언트가 단일 keepalive 연결을 통해 만들 수 있는 요청 수
- 기본값은 100, 높은 값을 지정하여 단일 클라이언트에서 많은 수의 요청을 보내는 과부하 테스트하는 데 사용할 수 있다.
- default : 100

### proxy_read_timeout
- proxied server 로부터 응답을 읽는 timeout 시간
- 전체 응답 전송 timeout 시간이 아니라 두개의 연속적인 읽기 작업 사이의 timeout 시간을 의미한다
- 지정한 시간안에 proxied server가 아무것도 전송하지 않으면 connection을 닫는다.
- default : 60s

### proxy_send_timeout
- proxied server로 요청을 전송하는 timeout 시간
- 전체 응답 전송 timeout 시간이 아니라 두개의 연속적인 쓰기 작업 사이의 timeout 시간을 의미한다
- 지정한 시간안에 proxied server가 아무것도 수신하지 않으면 connection을 닫는다.
- default : 60s

## upstream 영역
```NGINX
upstream backend  {
  ip_hash;
  keepalive 100;
  server backend.xxx.com:8080;
}
```
### ip_hash
- 클라이언트의 IP 주소를 해싱하여 동일한 클라이언트는 항상 동일한 서버로 연결되도록 한다.
- 이를 통해 세션 유지를 위한 로드밸런싱을 할 수 있다.
- 이 옵션을 사용하면 세션 유지를 위한 로드밸런싱을 할 수 있으나, 특정 클라이언트가 계속해서 같은 서버로 연결되기 때문에 특정 서버에 부하가 집중될 수 있다.
- 따라서, 특정 서버에 부하가 집중되는 것을 방지하기 위해 서버의 수를 늘리거나, 다른 로드밸런싱 방식을 사용하는 것이 좋다.
- [참조](https://nginx.org/en/docs/http/ngx_http_upstream_module.html#ip_hash)

### keepalive
- upstream 서버와의 keepalive 연결 수를 지정한다.

<seealso>
<category ref="reference">
<a href="https://gist.github.com/denji/8359866/">NGINX Tuning For Best Performance</a>
<a href="https://nginxstore.com/blog/nginx/nginx-성능-튜닝-가이드-nginx-plus-포함/">NGINX 성능 튜닝 가이드 (NGINX Plus 포함)</a>
<a href="https://nginxstore.com/blog/nginx/가장-많이-실수하는-nginx-설정-에러-10가지/">가장 많이 실수하는 NGINX 설정 에러 10가지</a>
<a href="https://haon.blog/infra/nginx/core-concept/">Nginx 의 동작원리와 등장배경, 역사에 대해 알아보자!</a>
<a href="https://haon.blog/infra/nginx/keep-alive/">Nginx 의 keep-alive 를 조정하여 성능을 개선해보자!</a>
</category>
</seealso>