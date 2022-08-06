# 다운로드 받아서 설치
# https://minikube.sigs.k8s.io/docs/start/

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64
sudo install minikube-linux-arm64 /usr/local/bin/minikube

minikube start

# nginx 인그레스 컨트롤러 활성화
# https://kubernetes.io/ko/docs/tasks/access-application-cluster/ingress-minikube/
minikube addons enable ingress