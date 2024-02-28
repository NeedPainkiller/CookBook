# WOL (Wake On Lan) 설정

## 설치
```Bash
sudo apt-get install net-tools ethtool wakeonlan
```

## 인터페이스 설정
1. 인터페이스 확인
- enp.... : 유선
- wlp.... : 무선
```Bash
ifconfig
```

2. WOL 활성화
```Bash
# wol 활성화
sudo ethtool -s 인터페이스명 wol g

# wol 작동상태 확인
sudo ethtool 인터페이스명
```
- Wake-on : g 확인

3. 인터페이스 설정 수정
<tabs>
    <tab title="/etc/network/interfaces (before 18.04)">
        <code-block lang="bash">
            sudo vi /etc/network/interfaces
        </code-block>
        <sub>/etc/network/interfaces 에 추가</sub>
        <code-block lang="bash">
            post-up /sbin/ethtool -s 인터페이스명 wol g
            post-down /sbin/ethtool -s 인터페이스명 wol g
        </code-block>
    </tab>
    <tab title="/etc/netplan/00-installer-config.yaml">
        <code-block lang="bash">
            sudo vi /etc/netplan/00-installer-config.yaml
        </code-block>
        <sub>/etc/netplan/00-installer-config.yaml 의 인터페이스 명을 가진 dhcp4: true 아래에 추가</sub>
        <code-block lang="yaml">
            # This is the network config written by 'subiquity'
network:
  ethernets:
    enp5s0:
      dhcp4: true
      wakeonlan: true
  version: 2
        </code-block>
        <sub>적용</sub>
        <code-block lang="bash">
            sudo netplan apply
        </code-block>
    </tab>
</tabs>