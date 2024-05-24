# 무선랜  설정

## 설치
```Bash
sudo apt-get install wireless-tools wpasupplicant -y

sudo apt upgrade -y
sudo apt update -y

sudo apt install git linux-headers-generic build-essential dkms -y

# NetworkManager 설치
sudo apt install network-manager -y
```

## 무선 랜카드 확인
```Bash
# 인터페이스 목록 출력
ip link show
```
- wlan 또는 wlx 로 시작하는 인터페이스 명 확인 (startwith "wl")

```Bash
# 인터페이스 활성화 확인
ip link show [인터페이스 이름]

# 인터페이스 활성화
sudo ip link set [인터페이스 이름] up
```

## 무선랜 네트워크 스캔
```Bash
sudo iwlist [인터페이스 이름] scan
```

## 무선랜 네트워크 연결
- NetworkManager 사용
```Bash
sudo systemctl start NetworkManager
sudo systemctl enable NetworkManager
```

- 연결
```Bash
sudo nmcli dev wifi connect [SSID] password [비밀번호]
# 또는 TUI 활용
sudo nmtui
```