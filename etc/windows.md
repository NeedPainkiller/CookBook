# SSH

## windows ssh pem permision
```cmd
icacls.exe xxx.pem /reset
icacls.exe xxx.pem /grant:r %username%:(R)
icacls.exe xxx.pem /inheritance:r
```

# NAT 설정
https://myblog.opendocs.co.kr/archives/17

## MASTER
https://it-svr.com/hyper-v-nat-portforwarding/
```bash
New-VMSwitch -SwitchName "NAT-Switch" -SwitchType Internal
New-NetIPAddress -IPAddress 10.0.0.1 -PrefixLength 24 -InterfaceAlias "vEthernet (NAT-Switch)"
New-NetNat -Name NAT-Swtich -InternalIPInterfaceAddressPrefix 10.0.0.0/24
Add-NetNatStaticMapping -ExternalIPAddress "0.0.0.0/0" -ExternalPort 10022 -Protocol TCP -InternalIP…
ssh rainbow@10.0.0.xxx -p 10022
```

## SLAVE
https://www.manualfactory.net/10151
https://chunggaeguri.tistory.com/entry/CentOS-7-%EC%97%90%EB%9F%AC-Job-for-sshdservice-failed-because
### ip
```bash
vi /etc/sysconfig/network-scripts/ifcfg-eth0

service network restart
```