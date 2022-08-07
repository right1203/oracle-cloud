# Oracle Cloud의 ARM 프리티어를 사용해보자.

Oracle Cloud에서 Arm 기반 Ampere A1 코어 및 24GB 메모리를 프리티어로 제공해준다. [프리티어 범위](https://www.oracle.com/kr/cloud/free/#always-free)

이걸 구성한 내용을 기록해두자.

### 1. Instance 구성

- 인스턴스는 알아서 잘 생성하면 된다.
- Ubuntu 20.04로 설정하고, 부트 볼륨은 100GB로 했다.
- VNIC로 예약된 IP를 할당 받아서 고정 IP로 변경했다.
- 서브넷에서 80, 443 포트 및 기타 포트를 설정했다.
- OS 자체의 방화벽도 허용해줘야 한다.
- 블록 볼륨은 50GB 할당 받아서 /dev/sdb로 마운트했다. [설정 방법](https://kibua20.tistory.com/122)
- root와 ubuntu의 비밀번호를 `sudo passwd root`와 같이 설정했다.

```
# 블록 볼륨 마운트
chmod +x ./block_volume.sh
./block_volume.sh

# OS 방화벽 열기
sudo iptables -I INPUT 9 -s 10.0.0.0/8 -j ACCEPT
sudo iptables -I INPUT 10 -d 10.0.0.0/8 -j ACCEPT

sudo iptables -I FORWARD 9 -s 10.0.0.0/8 -j ACCEPT
sudo iptables -I FORWARD 10 -d 10.0.0.0/8 -j ACCEPT

sudo netfilter-persistent save

```

### 2. Docker 설치

- 공식 홈페이지를 따라했다. [Docker 공식 홈페이지](https://docs.docker.com/engine/install/ubuntu/)

```
chmod +x ./docker_install.sh
./docker_install.sh
```

### ~~3. minikube 설치 (VM에 minikube를 설치해서 사용하지 말자)~~

- 쿠버네티스의 라이트 버전을 여러개를 고민해봤다.
- k3s, minikube, kind를 살펴보았는데 현재 상황에서 가장 적합한 것은 minikube인 것 같아서 minikube를 설치했다.
- 설치는 공식 홈페이지를 따라했다. [Minikube 공식 홈페이지](https://minikube.sigs.k8s.io/docs/start/)

```
chmod +x ./minikube_install.sh
./minikube_install.sh
```

### 4. kubectl 설치

- minikube의 kubectl은 krew와 같은 다른 패키지를 설치했을 때 호환이 안 된다.
- kubectl을 따로 설치하자. 역시 공홈을 참조했다. [kubectl 공식 홈페이지](https://kubernetes.io/ko/docs/tasks/tools/install-kubectl-linux/)

```
chmod +x ./kubectl_install.sh
./kubectl_install.sh
```

### ~~5. minio 설치~~ (minikube에 minio 설치하지 말자. Oracle VM은 k3s 클러스터로 쓰자)

- 저장공간을 한 번 써보고 싶어서 minio를 minikube에 올려봤다.
- kubectl의 krew 플러그인 매니저를 이용해서 minio-operator와 minio-tenant를 구축했다.
- kubernetes 레포에 따로 코드를 관리한다. https://github.com/right1203/kubernetes

```
chmod +x ../../kubernetes/minio/minio_install.sh
../../kubernetes/minio/minio_install.sh
```

### 6. 이슈

#### 6.1. VM에 SSH로 접속해서 minikube 접속?
- minikube에 올린 minio를 외부에 노출시켜보려고 했다.
- 하지만 어떻게 해도 minio가 오라클의 공용IP로 접속이 안 됐다.
- 처음으로 돌아가서 minikube로 deployment를 띄우고, kubectl expose NodeBalancer, minikube tunnel로 시도를 해봤지만 그래도 안 됐다.
- 다시 생각해보니, VM을 SSH로 접근 -> minikube 설치 -> SSH로 VM 내에 클러스터 설치는 이상하다. 쿠버네티스의 목적에 맞지도 않고, 하나의 VM에 쿠버네티스 클러스터를 구성하는 것도 쿠버네티스 목적에 맞지 않는 것 같다.
- 만약에 할거라면 VM 자체를 클러스터로  쓰거나, VM에는 도커로만 설치하자.

#### 6.2. ARM에서 도커 사용 시 exec format error 이슈

- ARM 기반의 CPU를 사용하다보니 도커를 띄울 때 에러가 발생했다.
  - `exec user process caused "exec format error"`
- x86_64 -> 다른 아키텍쳐의 호환성을 해결해주는 방법은 있다. https://github.com/multiarch/qemu-user-static
- 근본적인 해결방법은 멀티플랫폼 빌드를 하는 것이다. ([docker buildx 사용](https://gurumee92.tistory.com/311))

**[트러블슈팅]**
```
# qemu-user-static 사용 (현재 플랫폼이 x86_64인 경우에만 동작)
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# docker buildx로 멀티플랫폼 빌드
docker buildx build --platform=linux/arm64/v8,linux/amd64 -t image-name:version .
```

### 7. k3s로 Oracle VM을 클러스터 노드로 사용해보자.

- 우선 단일 클러스터로 써보자.
```
# k3s 설치
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san {VM IP 주소}" sh -s -

# k3s 설정파일 확인 (아래 출력되는 내용 복사)
sudo cat /etc/rancher/k3s/k3s.yaml

# 로컬!!!에서 k3s 설정파일에 내용 붙어녛기
# name, cluster, context와 서버 주소는 바꿔줘야 한다.

# 아래 명령어로 쉽게 바꿀 수 있다.
# :%s/127.0.0.1/your-k3s-instance-ip/g
# :%s/default/your-k3s-name/g

vi ~/.kube/k3s-config
export KUBECONFIG=$HOME/.kube/config-k3s:$HOME/.kube/config:$KUBECONFIG

[내 설정 파일 (~는 원래 값 그대로 두면 됨)]
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ~
    server: https://{IP 주소}:6443
  name: oracle-arm1
contexts:
- context:
    cluster: oracle-arm1
    user: oracle-arm1
  name: oracle-arm1
current-context: oracle-arm1
kind: Config
preferences: {}
users:
- name: oracle-arm1
  user:
    client-certificate-data: ~
    client-key-data: ~


# context 확인
kubectl config get-contexts

# context 변경
kubectl config use-context oracle-arm1

# 로컬에서 연결 시도
kubectl get pod -A

# 연결 이슈 트러블슈팅
# Unable to connect to the server: x509: certificate is valid for 10.0.0.228, 10.43.0.1, 127.0.0.1, ::1, not 146.56.38.76
# tls-san을 추가해야 한다고 한다. 설치할 때 아래 코드로 설치하자. https://github.com/k3s-io/k3s/issues/1381
# curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san {VM IP 주소}" sh -s -

# 연결이 잘 안된다면 Oracle의 네트워크 정책과 OS 방화벽을 체크해보자.
```

### 8. k3s 클러스터에 서비스 올리고 외부 접속해보기

### 9. k3s 클러스터 서비스에 도메인 연결해보기

### 10. k3s 클러스터를 master node 1개, worker node 3개로 구성해보기
- 여기를 주로 참고하자. https://urunimi.github.io/oci/kubernetes/infra/oci-k8s/

