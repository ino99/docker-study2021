コンテナ技術　社内勉強会用　資料
# 3. Kubernetes(k8s)を試す
## 3.1. minikube環境を準備
　minikubeは、1台のマシン上でk8sを動かす実験用の  
　環境を構築できるツールです  
　なお、自身で試す場合の検証環境は各自準備ください  
　本手順は、CentOS7で事前検証しています  
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
　①Docker起動  
> sudo systemctl start docker  

　②hello-world 動作確認  
> docker run --rm hello-world  
> docker rmi hello-world  

　③Docker自動実行有効化  
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
　①YAMLファイルを読み込みPodを起動  
> kubectl apply -f k8s/sample.yml  

　②Pod,SVC,Ingressの起動状態確認  
> kubectl get ingress,svc,pod 

## 3.3. Pod障害時の自動復旧
　①Pod一覧を表示  
> kubectl get pod  

　②Podを強制終了  
> pods= [`終了したいpodを入力`]  
> kubectl delete pods ${pods} --grace-period=0 --force  

　③自動復旧の確認  
> kubectl get pod   

## 3.4. スケールアウト/スケールイン
　①k8s/sample.yml内のreplicas 数を変更  
> replicas: 2  ====> 10  

　②sample.yml を再適応  
> kubectl apply -f k8s/sample.yml  

　③Pod一覧を表示（2->10へ増加している）  
> kubectl get pod  

　④同様に 10->5に変更  

## 3.5. ローリングアップデート/ロールバック
　ここでは、  
　アプリVerを 1 → 2 にアップデート  
　アプリVerを 2 → 1 へロールバック  
　を確認します  

　①ブラウザにて背景が緑でVer1と表示されることを確認  
　※ブラウザを複数起動し並列で表示させる    

　②k8s/sample.yml内のimage のタグ名を変更  
> image: ino99/myweb-k8s:v1 ==> v2に変更  

　③sample.ymlを再適応  
> kubectl apply -f k8s/sample.yml  

　②ブラウザ表示が、緑→赤、V1→2へ切替わるのを確認  

　③ロールバックを実行  
> kubectl roolout undo deployment/myweb  

　④ブラウザ表示が、赤→緑、V2→1へ切替わるのを確認  
