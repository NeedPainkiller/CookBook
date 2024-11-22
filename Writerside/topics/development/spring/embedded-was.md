# Embedded WAS

## Embedded Tomcat 제외처리
- Spring Boot 는 기본 내장 톰캣을 제공한다
- 해당 톰캣을 제외하여 jar 크기를 절약할 수 있다
```Gradle
dependencies {
    // 필요없는 의존성 제거
    implementation('org.springframework.boot:spring-boot-starter-web') {
        exclude module: 'spring-boot-starter-tomcat' // 내장 톰캣이 필요없는 경우
    }
} 
```
## Change Embedded WAS 
- Tomcat 대신 jetty, undertow 로 대체 가능하다
### Jetty
```Gradle
dependencies {
    implementation('org.springframework.boot:spring-boot-starter-web') {
        exclude module: 'spring-boot-starter-tomcat'
    }
    implementation 'org.springframework.boot:spring-boot-starter-jetty'
}
```
- 가벼운 메모리 사용량
- 오래된 역사와 안정성
- 임베디드 환경에 적합


### Undertow
```Gradle
dependencies {
    implementation('org.springframework.boot:spring-boot-starter-web') {
        exclude module: 'spring-boot-starter-tomcat'
    }
    implementation 'org.springframework.boot:spring-boot-starter-undertow'
}
```
- 메모리 사용량이 가장 적음
- 높은 성능과 확장성
- Red Hat에서 개발

### 성능비교 (참고)

- 메모리 사용: Undertow < Jetty < Tomcat
- 요청 처리량: Undertow > Jetty ≈ Tomcat

<seealso>
    <category ref="official">
        <a href="https://hyojaedev.tistory.com/32">Undertow 적용하기 (다른 WAS 적용해보기)</a>
    </category>
</seealso>
