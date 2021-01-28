# docker-study2021/chap3

# コンテナ技術　社内勉強会用　資料
目次  
1. 入門編　とりあえずdockerコンテナを動かす
2. 応用編　コンテナ技術の裏側を少し深堀りする
3. k8sの動きを見てみる

# 3. k8s編
## 3.1. minikube環境を準備
動作環境は各自準備ください。  
本手順は、CentOS7で事前検証しています。  
スペック:CPU:2、Mem:2G, HDD:8G on VirtalBox  


＃一括インストール  
# sh ./install.sh  

・dockerインストール  
sudo yum update -y  
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo  
sudo yum install -y docker-ce docker-ce-cli containerd.io  
sudo yum install -y conntrack  

・dockerの動作確認  
sudo systemctl start docker  

docker run --rm hello-world  
docker rmi hello-world  

sudo systemctl enable docker  

・kubectl v1.20.2 インストール (2021/1/28　現在)  
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.20.2/bin/linux/amd64/kubectl -k  
chmod +x ./kubectl  
mv -f ./kubectl /usr/local/bin  

kubectl version --client  

・minikubeのインストール  
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -k  
chmod +x minikube  
install minikube /usr/local/bin/  
rm ./minikube

## 3.2. minikube環境の立ち上げ
・立上げ  
minikube start --vm-driver=none  

・状況確認
minikube status  
以下、host、kubelet、apiserverが Running　になっていればOK  
> type: Control Plane
> host: Running
> kubelet: Running
> apiserver: Running
> kubeconfig: Configured
> timeToStop: Nonexistent

