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
- `Path` : `%GRADLE_HOME%\bin;` (시스템 - path 변수에 추가)

4. 설치 확인

```Bash
gradle -v
```

## Gradle 업그레이드 {#gradle-upgrade}

<seealso>
    <category ref="official">
        <a href="https://gradle.org/">Gradle 공식 홈페이지</a>
        <a href="https://gradle.org/install/">Gradle 공식 설치 가이드라인</a>
    </category>
</seealso>