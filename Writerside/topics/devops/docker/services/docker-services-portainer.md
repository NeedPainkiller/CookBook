# Portainer

## 개요 {id="portainer_1"}

- Portainer는 Docker를 위한 경량화된 관리 UI 를 제공하는 서비스 이다

## 설치 {id="portainer_2"}
- simple
```yaml
version: '3.9'

services:
  portainer:
    image: portainer/portainer-ce:alpine
    container_name: portainer
    restart: always
    ports:
      - 9000:9000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer/data:/data
```
- with ssl
```yaml
version: '3.9'

services:
  portainer:
    image: portainer/portainer-ce:alpine
    container_name: portainer
    restart: always
    ports:
      - 9000:9000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer/data:/data
      - /home/sammy/docker/site/ssl:/certs:ro
    command:
      --ssl
      --sslcert /certs/fullchain.pem
      --sslkey /certs/privkey.pem
```


<seealso>
  <category ref="official">
    <a href="https://www.portainer.io/">Portainer</a>
  </category>
</seealso>