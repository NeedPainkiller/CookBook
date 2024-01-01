# rsync

## 커맨드 {id="ubuntu_rsync_1"}

```bash
rsync options src dest

# 주요 옵션
-a, --archive # 압축 모드. -rlptgoD와 동일
## -r, -t(타입스탬프 보존), -l (심볼릭 링크 보존), -p(permission 보존), -g(g그룹 보존), -o(소유자 보존 - root 만 가능), -D(device, special 파일 보존)
##  일반적으로 -a 옵션에 -z 옵션을 추가하면 충분
-v, --verbose # 상세한 정보 출력
-r, --recursive # 하위 디렉터리까지 재귀적으로 실행
-z # 데이터 압축
-h # human-readable, output numbers in a human-readable format

# 기타 옵션
-A, --acls # ACLs를 보존한다(-p 옵션과 함께).
-b, --backup # 백업을 만든다(--suffix 나 -backup-dir 참조).
-c, --checksum # 시간이나 크기가 아니라 체크섬으로 파일을 비교한다.
-d, --dirs # 하위 디렉터리를 포함하지 않고 전달한다.
-e, --rsh # COMMAND : 원격 셸을 지정한다.
-E, --executability # 실행 권한을 보존한다.
-g, --group # 그룹을 보존한다.
-H, --hard-links # 하드 링크를 보존한다.
-k, --copy-dirlinks # 디렉터리의 심볼릭 링크는 원본 디렉터리로 변경한다.
-K, --keep-dirlinks # 디렉터리의 심볼릭 링크는 심볼릭 그대로 취급한다.
-l, --links # 심볼릭 링크는 심볼릭 링크 형태 그대로 복사한다.
-L, --copy-links # 심볼릭 링크의 원본 파일이나 디렉터리로 변경한다.
-o, --owner # 소유자를 보존한다(슈퍼유저만 해당).
-p, --perms # 퍼미션을 보존한다.
-q, --quiet # 에러가 아닌 메시지는 출력하지 않는다.
-t, --times # 변경 시간을 보존한다.
-u, --update # 새로운 파일은 덮어쓰지 않는다.
-X, --xattrs # 확장 속성(externded attributes)을 보존한다.
--backup-dir # 지정한 디렉터리(DIR)에 백업을 만든다.
--bwlimit # 전송 대역폭을 제한한다. (KByte 기준)
--chmod # 파일이나 디렉터리 퍼미션(CHMOD)을 지정한다.
--copy-unsafe-links # “unsafe” 심볼릭 링크만 변경한다.
--delete # 서버 쪽에는 없고 클라이언트에만 있는 파일은 지운다.
--devices # 디바이스 파일을 보존한다(슈퍼유저만 해당).
--existing # 추가된 파일은 전송하지 않고 업데이트된 파일만 전송한다.
--exclude # 불필요한 파일을 제외한다.
--no-motd # 데몬 모드(MOTD)를 출력하지 않는다.
--specials #: 스페셜 파일을 보존한다.
--suffix # 디렉터리(SUFFIX) 위치에 백업한다.
-4, --ipv4 # IPv4
-6, --ipv6 # Ipv6
--version # 버전 번호를 출력한다.
(-h) --help # 사용법을 출력한다.
```


## 사용 예시 {id="ubuntu_rsync_2"}
### Local 파일을 Local 에 복제
- /home 디렉토리를 압축하여 /backup 디렉토리에 상세한 정보와 함께 백업
```Bash
rsync -av /home /backup
```

### Local 파일을 Remote에 복제
- /home/lesstif/data/ 디렉토리를 압축하여 example.com 서버의 /home/lesstif/backup/ 디렉토리에 복제
```Bash
rsync -av /home/lesstif/data/ lesstif@example.com:/home/lesstif/backup/
```

### Remote 파일을 Local에 복제
-  옵션 미지정 시 rsync에서 데이터 삭제는 진행되지 않는다. 삭제를 원한다면 delete 옵션 사용하면 된다.
- example.com 서버의 /home/lesstif/data 디렉토리를 로컬 서버의 /home/lesstif/backup/ 디렉토리에 백업
-  -delete : example.com 서버의 /home/lesstif/data 디렉토리 목록에 존재하지 않는 항목을 로컬에서 삭제
```Bash
rsync -avzr -delete lesstif@example.com:/home/lesstif/data /home/lesstif/backup/
```

### 목적지(destination) 파일이 변경 된 경우 덮어 쓰지 않음
- destination 파일이 수정된 경우 rsync 를 수행하면 기본적으로 source 파일로 덮어써 버린다.
-  이 상황을 원치않을 경우 rsync 에 -u 옵션을 추가하여 실행하면 파일이 변경 되었을 경우 덮어쓰지 않는다.
- -u, --update : 새로운 또는 수정된 파일은 덮어쓰지 않는다.
```Bash
rsync -avuz lesstif@example.com:/home/lesstif/data /home/lesstif/backup/
```

### 디렉터리 구조만 복제
-  -d, --dirs : 원본의 디렉터리 구조만 복제하고 안의 파일들은 복제하지 않는다.
```Bash
rsync -vd [lesstif@example.com](mailto:lesstif@example.com):/home/lesstif/ 
```

### 진행 내역 보기
-  --progress : 전송시 진행 내역을 볼 수 있다.
```Bash
rsync -av --progress lesstif@example.com:/home/lesstif/data /home/lesstif/backup/
```

### SSH 를 다른 포트로 사용
-  SSH 를 다른 포트(예: 10022) 를 사용하는 서버에 연결시 아래와 같이 -e 뒤에 ssh와 연결할 포트를 추가하고 실행 가능
```Bash
rsync -avz --progress -e 'ssh -p 10022' lesstif@example.com:/home/lesstif/data /home/lesstif/backup/
```

### 불필요한 파일 제외
-  USB 를 마운트해서 복사할 경우 휴지통이나 미리보기 데이타등의 불 필요한 파일은 --exclude 옵션으로 명시적으로 지정해서 제외해야 한다.
```Bash
rsync -avpz --delete --exclude="lost+found" 192.168.10.100::TEST/ /home/
```

### 대역폭 제한
- bwlimit 옵션을 사용하여 대역폭 제한 가능 (KByte 기준)
```Bash
rsync -avpz --delete --exclude-from=/tmp/rsync-exclude.txt --bwlimit=10240 192.168.10.100::TEST/ /home/
```

<seealso>
    <category ref="reference">
        <a href="https://velog.io/@inhwa1025/Linux-rsync란-rsync-사용법-rsync로-데이터-백업하기">[Linux] rsync란? rsync 사용법 / rsync로 데이터 백업하기</a>
        <a href="https://www.lesstif.com/lpt/scp-ssh-rsync-key-12943452.html">scp, ssh, rsync 를 key 비밀 번호/암호 입력창 없이 사용하기</a>
    </category>
</seealso>

