# nodejs

## NodeJS 버젼 확인 {id="nodejs_1"}
- [저장소](https://nodejs.org/dist) 링크에서 정확한 버젼명 확인 가능
- [공식 홈페이지](https://nodejs.org/en) LTS 확인 할 것
- LTS 버젼 권장

## NodeJS 버젼 관리 시스템 설치 {id="nodejs_2"}
<tabs>
    <tab title="nvm (Windows)">
        <a href="https://github.com/coreybutler/nvm-windows">Github</a>
        <a href="https://github.com/coreybutler/nvm-windows/releases">Downloads</a>
        <p>최신 릴리즈 <shortcut>nvm-setup.exe</shortcut> 다운로드 및 설치</p>
        <p>아래 명령어 활용하여 LTS 버젼 설치 진행</p>
        <code-block lang="shell">
            nvm --version
            nvm install {version}
            nvm use {version}
            node -v
        </code-block>
    </tab>
    <tab title="nodenv (Mac/Linux)">
        <a href="https://github.com/nodenv/nodenv#installation">nodenv installation</a>
    </tab>
</tabs>
