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

## Yarn 설치 {id="nodejs_3"}
```Bash
npm install -g yarn
yarn --version
```
### Yarn 명령어
```Bash
#package.json 생성
yarn init 
#package.json 파일 및 해당 종속성에 나열된 모든 모듈을 설치
yarn or yarn install 
# node_modules에 이미 설치된 파일이 제거되지 않았는지 확인
yarn install --check-files
#특정 패키지의 특정 버전 설치
yarn add package_name@버전 
# 패키지 설치 후 package.json에 해당 패키지를 종속성으로 추가합니다.
yarn add --dev package_name@버전
#특정 저장소 내 패키지 설치. 주로 github을 이와 같이 설치합니다.
yarn add 주소 
#옵션. 글로벌로 설치. 로컬의 다른 프로젝트도 이 패키지를 사용 가능하게 됩니다.
yarn global add package_name 

#패키지 삭제 명령어입니다.
yarn remove 
#설치한 패키지들을 업데이트해줍니다.
yarn upgrade 
#중복 설치된 패키지들을 정리해주는 명령어입니다.
npm dedupe 
```
