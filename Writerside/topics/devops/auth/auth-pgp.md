# PGP

## PGP 설치 {id="pgp_1"}

<tabs>
    <tab title="Windows">
        <procedure>
            <step>
                <p><shortcut>gpg4win</shortcut> 설치</p>
                <a href="https://gpg4win.org/download.html">kleopatra 설치</a>
            </step>
            <step>
                <p><shortcut>GNUPGHOME</shortcut> 환경변수 지정 필요</p>
                <p>Windows 기준 <shortcut>C:\Users\username\AppData\Roaming\gnupg</shortcut> 경로로 지정</p>
            </step>
        </procedure>
    </tab>
    <tab title="Linux (WSL)">
        <code-block lang="bash">
            sudo apt update
            sudo apt-get install gnupg
        </code-block>
    </tab>

</tabs>

## PGP 생성 및 백업 {id="pgp_2"}

### PGP 생성 {id="pgp_2_1"}

<tabs>
    <tab title="Windows">
        <procedure title="Windows (kleopatra)">
            <step>
                <p>kleopatra 에서 PGP 만들기</p>
                <img src="pgp-install-windows-kleopatra-1.png" alt="kleopatra 화면" border-effect="line"/>
                <p><shortcut>파일</shortcut> > <shortcut>새 OpenPGP 쌍</shortcut> 클릭</p>
                <img src="pgp-install-windows-kleopatra-2.png" alt="새 OpenPGP 쌍" border-effect="line"/>
                <p>인증서에서 사용할<shortcut>이름</shortcut> 과 <shortcut>이메일 주소</shortcut> 기입<br/>(권장)본인 실명과 저장소 등에서 주로 사용하는 이메일을 사용할 것</p>
                <img src="pgp-install-windows-kleopatra-3.png" alt="새 OpenPGP 쌍" border-effect="line"/>
                <p><shortcut>고급 설정</shortcut> 에서 인증서의 키 구성은 아래와 같이 설정 (유효 기간은 알아서 지정할 것)</p>
                <img src="pgp-install-windows-kleopatra-4.png" alt="새 OpenPGP 쌍" border-effect="line"/>
            </step>
        </procedure>
    </tab>
    <tab title="Linux (WSL)">
        <code-block lang="bash">
            # PGP 생성 (이메, 이름, 암호 입력 후 엔터)
            gpg --full-generate-key
            # 생성된 PGP 확인
            gpg --list-secret-keys --keyid-format LONG
            # public key 확인
            gpg -k
            # private key 확인
            gpg -K
            # 핑거프린트 확인
            gpg --fingerprint
        </code-block>
    </tab>
</tabs>

### PGP 백업 {id="pgp_2_2"}
<tabs>
    <tab title="Windows">
        <procedure title="Windows (kleopatra)">
            <step>
                <p>kleopatra 에서 PGP 백업</p>
                <img src="pgp-backup-windows-kleopatra-1.png" alt="kleopatra 화면" border-effect="line"/>
            </step>
            <step>
                <p>백업할 PGP 선택 후 <shortcut>파일</shortcut> > <shortcut>내보내기</shortcut> 클릭 > 공개 키 (xxx_public.asc) 백업</p>
            </step>
            <step>
                <p>백업할 PGP 선택 후 <shortcut>파일</shortcut> > <shortcut>비밀 키 백업</shortcut> 클릭 > 비밀 키 (xxx_SECRET.asc) 백업</p>
            </step>
        </procedure>
    </tab>
    <tab title="Linux (WSL)">
        <procedure title="Windows (kleopatra)">
            <step>
                <p>1안. gnupg 폴더 백업</p>
                <code-block lang="bash">
                    cp -r ~/.gnupg ~/gnupg-backup
                </code-block>
            </step>
            <step>
                <p>2안. gpg 명령어 사용</p>
                <code-block lang="bash">
                    gpg --export -a -r "사용자명" -o "public.asc"
                    gpg --export-secret-keys -a -r "사용자명" -o "secret.asc"
                </code-block>
            </step>
            <step>
                <p>백업할 PGP 선택 후 <shortcut>파일</shortcut> > <shortcut>비밀 키 백업</shortcut> 클릭 > 비밀 키 (xxx_SECRET.asc) 백업</p>
            </step>
        </procedure>
    </tab>
</tabs>

### PGP 참조 환경변수 등록 {id="pgp_2_3"}

## Github 저장소 연동 {id="pgp_3"}

### GPG 키 등록 {id="pgp_3_1"}

- Github 로그인
- Settings > SSH and GPG Keys
- GPG keys 의 New GPG Key 선택
- 공개 키 입력란에 위의 PGP 백업 중 내보내기한 공개 키 파일 (xxx_public.asc) 내용 입력

### 로컬 장비 Git 에 GPG 키 적용 {id="pgp_3_2"}

- Github 에 등록한 GPG 키의 "Key ID" 를 복사

<tabs>
    <tab title="Windows">
        <code-block lang="shell">
            git config --global gpg.program "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
            git config --global user.email your_email@example.com
            git config --global user.name "your_name"
            git config --global user.signingkey {Key ID}
            git config --global commit.gpgsign true
            git config --global -l
        </code-block>
    </tab>
    <tab title="Linux (WSL)">
        <code-block lang="bash">
            git config --global user.email your_email@example.com
            git config --global user.name "your_name"
            git config --global user.signingkey {Key ID}
            git config --global commit.gpgsign true
            git config --global gpg.program gpg2
            gpg2 --list-keys --keyid-format LONG
            gpg --edit-key {Key ID}
        </code-block>
    </tab>
</tabs>

## 데이터 암복호화 {id="pgp_4"}
- 공개키로 데이터를 암호화 할 수 있고, 개인키로 데이터를 복호화 할 수 있다
```Bash
# 암호화
gpg -o "암호화된 파일 명" --encrypt --recipient "받을사람" "파일 명" 

# 복호화
gpg -o "복호화된 파일 명" --decrypt "암호화된 파일 명"
```


## PGP 가져오기, 삭제  {id="pgp_5"}
### PGP 가져오기 {id="pgp_5_1"}
<tabs>
    <tab title="Linux (WSL)">
        <code-block lang="bash">
            # public key import
            gpg --import public.asc
            # private key import - 패스워드 필요
            gpg --import secret.asc
            # 키 신뢰 처리
            gpg --edit-key "키 이름"
            # 아래 명령어로 신뢰도를 설정
            trust
        </code-block>
    </tab>
</tabs>

### PGP 삭제 {id="pgp_5_2"}
<tabs>
    <tab title="Linux (WSL)">
        <code-block lang="bash">
            # public key import
            gpg --delete-key "키 이름"
            # private key import - 패스워드 필요
            gpg --delete-secert-key "키 이름"
        </code-block>
    </tab>
</tabs>