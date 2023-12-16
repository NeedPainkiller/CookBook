# Gitlab

## 설치 (Docker) {#gitlab_1}
- gitlab 의 공식 Docker 이미지는 WS 와 WAS 가 모두 포함되어 있다
- 포트는 기본 HTTP/HTTPS 포트인 80/443 을 사용한다

```yaml
version: '3.9'

services:
  gitlab:
    image: 'gitlab/gitlab-ce:16.6.2-ce.0'
    container_name: gitlab
    restart: always
    hostname: '127.0.0.1'
    # hostname: 'gitlab.needpainkiller.xyz'
    shm_size: '256m'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.needpainkiller.com'
        gitlab_rails['gitlab_shell_ssh_port'] = 8022
        # Add any other gitlab.rb configuration here, each on its own line
      TZ: 'Asia/Seoul'
    ports:
      - '127.0.0.1:80:80'
      - '127.0.0.1:443:443'
      - '127.0.0.1:8022:22'
    expose:
      - "31080"
      - "31443"
      - "31022"
    volumes:
      - './gitlab/config:/etc/gitlab'
      - './gitlab/logs:/var/log/gitlab'
      - './gitlab/data:/var/opt/gitlab'
```
<seealso>
    <category ref="official">
        <a href="https://about.gitlab.com/releases/">GitLab releases</a>
        <a href="https://about.gitlab.com/releases/categories/releases/">Releases Posts</a>
        <a href="https://docs.gitlab.com/ee/install/docker.html">GitLab Docker images</a>
    </category>
</seealso>
