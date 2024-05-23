 # Kubernetes

## 개요 {id="kubernetes_1"}

- [Ubuntu 22 쿠버네티스 설치](https://macaronics.net/index.php/m02/linux/view/2204)
```Bash
## 쿠버네티스 초기화
kubeadm reset


## 쿠버네티스 && 도커 기동 중지
sudo systemctl stop kubelet
sudo systemctl stop docker

## 쿠버네티스 네트워크 설정( Cluster Network Interface ) 삭제
sudo ip link delete cni0
sudo ip link delete flannel.1

## 쿠버네티스 관련 파일 삭제
sudo rm -rf /var/lib/cni/
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /var/lib/etcd
sudo rm -rf /run/flannel
sudo rm -rf /etc/cni
sudo rm -rf /etc/kubernetes
sudo rm -rf ~/.kube

## 쿠버네티스 관련 패키지 삭제(Ubuntu)
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube* -y
sudo apt-get autoremove 
```


<img src="k8s_ecosystem.png" alt=""/>

<seealso>
    <category ref="official">
        <a href="https://kubernetes.io/ko/docs/concepts/overview/what-is-kubernetes/">Kubernetes</a>
    </category>
    <category ref="reference">
        <a href="https://yozm.wishket.com/magazine/detail/2371/">2024년 쿠버네티스 표준 아키텍처</a>
    </category>
</seealso>


