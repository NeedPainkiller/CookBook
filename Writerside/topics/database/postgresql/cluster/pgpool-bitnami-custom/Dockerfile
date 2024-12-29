# 베이스 이미지로 Ubuntu를 사용
FROM debian:bookworm-slim

# 필요한 패키지 설치
RUN apt-get update && \
    apt-get install -y pgpool2 curl wget net-tools ethtool arping iptables iproute2 iputils-ping && \
    apt-get update && apt-get upgrade -y


RUN ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime && echo Asia/Seoul > /etc/timezone


COPY escalation.sh /tmp/escalation.sh
RUN chmod +x /tmp/escalation.sh
# pgpool 설정 파일 복사
#COPY pgpool.conf /etc/pgpool2/pgpool.conf
#COPY pcp.conf /etc/pgpool2/pcp.conf
#COPY pool_hba.conf /etc/pgpool2/pool_hba.conf

# 환경 변수 설정
ENV PGPOOL_CONFIG_DIR=/etc/pgpool2
ENV PGPOOL_LOG_DIR=/var/log/pgpool2

# 포트 노출
EXPOSE 9999 9898 9694

# pgpool-II 시작 스크립트
CMD ["pgpool", "-n", "-f", "/etc/pgpool2/pgpool.conf"]