コンテナ技術　社内勉強会用　資料
# 3. kubernetes(k8s)編
## 3.1. minikube環境を準備
　minikubeは、1台のマシン上でk8sを動かす実験用の環境を構築できるツールです  
　動作環境は各自準備ください。  
　本手順は、CentOS7で事前検証しています。  
　スペック:CPU:2、Mem:2G, HDD:8G on VirtalBox  

### 3.1.1. 一括インストール  
> sh ./install.sh  

### 3.1.2. step by step でインストール  
#### （１）dockerインストール
> sudo yum update -y  
> sudo yum install -y yum-utils
> sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo  
> sudo yum install -y docker-ce docker-ce-cli containerd.io  
> sudo yum install -y conntrack  
#### （２）dockerの動作確認  
　●Docker起動  
> sudo systemctl start docker  

　●hello-world 動作確認  
> docker run --rm hello-world  
> docker rmi hello-world  

　●Docker自動実行有効化  
> sudo systemctl enable docker  

#### （３）kubectl v1.18.3 インストール
> curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kubectl -k  
> chmod +x ./kubectl  
> mv -f ./kubectl /usr/local/bin  
> kubectl version --client  

#### （４）minikube v1.12.2 のインストール  
> curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.12.2/minikube-linux-amd64 -k  
> chmod +x minikube  
> install minikube /usr/local/bin/  
> rm ./minikube
　●minikube環境の立ち上げ
> minikube start --vm-driver=none  

　●状況確認
> minikube status  

　以下のhost、kubelet、apiserverが Running　になっていればOK  
> type: Control Plane  
> host: Running  
> kubelet: Running  
> apiserver: Running  
> kubeconfig: Configured  

## 3.2. k8s　サンプル構成の立ち上げ
　●YAMLファイルを読み込み、Podを立ち上げる  
> kubectl apply -f k8s/sample.yml  

　●起動したPodおよび外部接続可能なIPアドレスが付与されたかを確認する  
> kubectl get ingress,svc,pod 

## 3.3. Pod障害時の自動復旧
　●Pod一覧を表示  
> kubectl get pod  

　●Podを強制終了  
> pods=  
> kubectl delete pods {$pods} --grace-period=0 --force  

　●再びPod一覧を表示し、自動で復旧していることを確認  
> kubectl get pod   

## 3.4. スケールアウト/スケールイン
　●k8s/sample.yml内のreplicas の数を変更する  
> replicas: 2  ====> 10  

　●sample.ymlを再読み込み  
> kubectl apply -f k8s/sample.yml  

　●Pod一覧を表示 2->10へ増加している  
> kubectl get pod  

　●同様に 10->5に減らしてみる  

## 3.5. ローリングアップデート/ロールバック
　●アプリVerを1から2にアップデートしてみる  

　●ブラウザでアクセスし、背景が緑で、Ver1が表示されることを確認する  
　※ブラウザを複数作成し、5ブラウザ並列で表示させる    

　●k8s/sample.yml内のimage のタグ名を変更する  
> image: ino99/myweb-k8s:v1 ==> v2に変更  

　●sample.ymlを再読み込み  
> kubectl apply -f k8s/sample.yml  

　●ブラウザの表示が、順次　緑から　赤に変わっていき  Ver2が表示される  

　●最後に、アプリVerを2から1にロールバックしてみる  
> kubectl roolout undo deployment/myweb  

　●ブラウザの表示が、順次　赤から　緑に変わっていき  Ver1が表示される  
