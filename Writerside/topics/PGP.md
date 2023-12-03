# PGP 설정 및 활용

## PGP 설치 {id="pgp_1"}

<tabs>
    <tab title="Windows">
        <a href="https://gpg4win.org/download.html">kleopatra 설치</a>
    </tab>
    <tab title="Linux (WSL)">
        <code-block lang="bash">
            sudo apt update
            sudo apt-get install gnupg
        </code-block>
    </tab>

</tabs>

## PGP 생성 및 백업 {id="pgp_2"}

### PGP 생성 {id="pgp_2-1"}

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

### PGP 백업 {id="pgp_2-2"}

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

### PGP 참조 환경변수 등록 {id="pgp_2-3"}

- ```GNUPGHOME``` 환경변수 지정 필요
- Windows 기준 ```C:\Users\<username>\AppData\Roaming\gnupg``` 경로로 지정

## Github 저장소 연동 {id="pgp_3"}

### GPG 키 등록 {id="pgp_3-1"}

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
            git config --global user.email kam6512@gmail.com
            git config --global user.name "YoungWon Kang"
            git config --global user.signingkey {Key ID}
            git config --global commit.gpgsign true
            git config --global -l
        </code-block>
    </tab>
    <tab title="Linux (WSL)">
        <code-block lang="bash">
            git config --global user.email kam6512@gmail.com
            git config --global user.name "YoungWon Kang"
            git config --global user.signingkey {Key ID}
            git config --global commit.gpgsign true
            git config --global gpg.program gpg2
            gpg2 --list-keys --keyid-format LONG
            gpg --edit-key {Key ID}
        </code-block>
    </tab>
</tabs>

<seealso>
    <category ref="wrs">
        <a href="https://plugins.jetbrains.com/plugin/20158-writerside/docs/markup-reference.html">Markup reference</a>
        <a href="https://plugins.jetbrains.com/plugin/20158-writerside/docs/manage-table-of-contents.html">Reorder topics in the TOC</a>
        <a href="https://plugins.jetbrains.com/plugin/20158-writerside/docs/local-build.html">Build and publish</a>
        <a href="https://plugins.jetbrains.com/plugin/20158-writerside/docs/configure-search.html">Configure Search</a>
    </category>
</seealso>