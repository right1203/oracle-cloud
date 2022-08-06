# Oracle Cloud의 ARM 프리티어를 사용해보자.

Oracle Cloud에서 Arm 기반 Ampere A1 코어 및 24GB 메모리를 프리티어로 제공해준다. [프리티어 범위](https://www.oracle.com/kr/cloud/free/#always-free)

이걸 구성한 내용을 기록해두자.

### 1. Instance 구성

- 인스턴스는 알아서 잘 생성하면 된다.
- Ubuntu 20.04로 설정하고, 부트 볼륨은 100GB로 했다.
- VNIC로 예약된 IP를 할당 받아서 고정 IP로 변경했다.
- 서브넷에서 80, 443 포트 및 기타 포트를 설정했다.
- 블록 볼륨은 50GB 할당 받아서 /dev/sdb로 마운트했다. [설정 방법](https://kibua20.tistory.com/122)
- root와 ubuntu의 비밀번호를 `sudo passwd root`와 같이 설정했다.

```
# 블록 볼륨 마운트
chmod +x ./block_volume.sh
./block_volume.sh
```

### 2. Docker 설치

- 공식 홈페이지를 따라했다. [Docker 공식 홈페이지](https://docs.docker.com/engine/install/ubuntu/)

```
chmod +x ./docker_install.sh
./docker_install.sh
```

### 3. minikube 설치

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

### 5. minio 설치

- 저장공간을 한 번 써보고 싶어서 minio를 minikube에 올려봤다.
- kubectl의 krew 플러그인 매니저를 이용해서 minio-operator와 minio-tenant를 구축했다.
- kubernetes 레포에 따로 코드를 관리한다. https://github.com/right1203/kubernetes

```
chmod +x ../../kubernetes/minio/minio_install.sh
../../kubernetes/minio/minio_install.sh
```
