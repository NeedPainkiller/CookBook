# crontab

## 설치 {id="ubuntu_crontab_1"}
```Bash
sudo apt install cron -y
```

## 커맨드 {id="ubuntu_crontab_2"}

```bash
crontab -l # 예약된 작업리스트
crontab -e # 예약된 작업 수정
crontab -r # 예약된 작업 삭제
crontab -u [사용자명] # 루트관리자는 해당 사용자 crontab 파일을 보거나 삭제, 편집 가능
```

```Bash
view /var/log/syslog # cron 로그 확인
```



