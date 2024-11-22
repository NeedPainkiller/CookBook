# Layered-BootJar

## Layered Jar
- 애플리케이션 JAR를 여러 레이어로 분리하여 구성
- Docker 이미지 빌드 시 캐시 활용 가능
- 변경이 적은 레이어와 자주 변경되는 레이어를 분리


### 기본 레이어 구조

```Bash
- dependencies       (자주 변경되지 않는 외부 라이브러리)
- spring-boot-loader (스프링 부트 로더)
- snapshot-dependencies (스냅샷 버전 라이브러리)
- application       (애플리케이션 코드)
```

## Gradle 설정 방법
```gradle
bootJar {
    layered {
        enabled = true
        application {
            intoLayer("spring-boot-loader") {
                include "org/springframework/boot/loader/**"
            }
            intoLayer("application")
        }
        dependencies {
            intoLayer("application") {
                includeProjectDependencies()
            }
            intoLayer("dependencies")
        }
        layerOrder = ["dependencies", "spring-boot-loader", "application"]
    }
}
```

## DockerFile 최적화 예시
```Docker
FROM eclipse-temurin:17-jre as builder
WORKDIR application
ARG JAR_FILE=build/libs/*.jar
COPY ${JAR_FILE} application.jar
RUN java -Djarmode=layertools -jar application.jar extract

FROM eclipse-temurin:17-jre
WORKDIR application
COPY --from=builder application/dependencies/ ./
COPY --from=builder application/spring-boot-loader/ ./
COPY --from=builder application/snapshot-dependencies/ ./
COPY --from=builder application/application/ ./
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
```

<seealso>
    <category ref="official">
        <a href="https://www.baeldung.com/spring-boot-docker-images#layered-jars">Creating Docker Images with Spring Boot</a>
    </category>
</seealso>
