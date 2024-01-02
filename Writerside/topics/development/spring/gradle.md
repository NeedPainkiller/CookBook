# Gradle

## Gradle 설치 및 설정 {#gradle-installation}

1. Java 8 이상 설치

```Bash
java -version
```

2. 공식 홈페이지에서 Gradle 다운로드

- [Gradle 다운로드](https://gradle.org/install/)
- Binary-only 또는 Complete 으로 다운로드

3. 압축 해제 후 환경변수 설정

- `GRADLE_HOME` : Gradle 압축 해제 경로 (새 변수)
- `Path` : &percnt;\GRADLE_HOME&percnt;\bin; (시스템 - path 변수에 추가)

4. 설치 확인

```Bash
gradle -v
```

## Gradle 업그레이드 {#gradle-upgrade}

1. Gradle Wrapper 생성
```Bash
gradle wrapper
```

2. (옵션1) Gradle Wrapper 경로 (gradle/wrapper/gradle-wrapper.properties) 에서 버전 변경

- gradle/wrapper/gradle-wrapper.properties 파일 > distributionUrl 변경
```Bash
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```
- gradlew.bat 실행
```Bash
gradlew.bat build 
```

2. (옵션2) Gradle Wrapper 명령어로 버전 변경

```Bash
gradlew wrapper --gradle-version <version>
```
- gradlew.bat 실행
```Bash
gradlew.bat build 
```

<seealso>
    <category ref="official">
        <a href="https://gradle.org/">Gradle 공식 홈페이지</a>
        <a href="https://gradle.org/install/">Gradle 공식 설치 가이드라인</a>
    </category>
</seealso>