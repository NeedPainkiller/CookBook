# PGP 생성 가이드라인
## PGP 생성
- 클레오파트라 설치
    - https://gpg4win.org/download.html

- 클레오파트라에서 PGP 키 생성
- (선택) PGP 키 만료 기한을 무제한으로 지정

## PGP 백업
- 클레오파트라에서 PGP 키를 선택하고 각각 "내보내기" 와 "비밀 키 백업" 으로 PGP 키 백업
- 각 2개의 파일은 개인 저장소에 저장할 것

## 환경변수 지정
- ```GNUPGHOME``` 환경변수를 지정해야함
- ```C:\Users\<username>\AppData\Roaming\gnupg``` 경로로 지정


# Github 연동 방법
## GPG 키 등록
- Github > Settings > SSH and GPG Keys
- GPG keys 의 New GPG Key 추가
- 위의 PGP 내보내기에서 만든 파일 (xxx_public.asc) 내용 복사하여 등록

## 로컬 장비 Git 에 GPG 키 적용
- Github 에 등록한 GPG 키의 "Key ID" 를 복사

```powershell
# Windows
git config --global gpg.program "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
git config --global user.email kam6512@gmail.com
git config --global user.name "YoungWon Kang"
git config --global user.signingkey {Key ID}
git config --global commit.gpgsign true
git config --global -l
```

```bash
# WSL
sudo apt update
sudo apt-get install gnupg
git config --global gpg.program gpg2
gpg2 --list-keys --keyid-format LONG
gpg --edit-key {Key ID}
```