コンテナ技術　社内勉強会用　資料
# 1. 入門編
## 1.1. docker環境を準備
　docker動作環境は各自準備ください。  
　手元に環境が無い場合は、[Play with docker](https://labs.play-with-docker.com/) の利用をお勧めします。  
　利用には、[docker hubへのユーザ登録(無料)](https://matsuand.github.io/docs.docker.jp.onthefly/docker-id/
) が必要です。  
　※但し4時間の利用制限あり（再度ログインすることで、何度も利用可能）  

　dockerの環境が準備できたら、以下モジュールをgithubからクローンします。  
> git clone https://github.com/ino99/docker-study2021.git  
> cd docker-study2021/chap1  
## 1.2. ファイル構成
　docker-study2021/chap1のファイル構成は次の通りです。
|ファイル名|概要|
| ---- | ---- |
|app.py|flask　を使い　Hello world　を表示します。|
|requirements.txt|python pip で導入する項目のリストです。今回はFlaskのみです。|
|Dockerfile|Docker イメージ構成を記載したファイルです。|
## 1.3. イメージファイルのビルド
　Dockerfileに記載した内容で、イメージファイルを生成します。  
　pyhello:v1　というタグ名で、イメージファイルを作成するには、次のコマンドを実行します。  
> docker build -t pyhello:v1 ./  
## 1.4. イメージファイルの確認
　作成したイメージファイルの一覧を、次のコマンドで確認します。
> docker images
## 1.5. コンテナ起動
　作成したイメージファイルを元に、コンテナを作成＆起動します。
> docker run -d -p 5000:5000 pyhello:v1
## 1.6. コンテナ一覧
　起動中のコンテナ一覧を確認します。
> docker ps  

　-aを付加すると、停止中のコンテナを含め表示します。
> docker ps -a 　
## 1.7. コンテナ内のflaskへアクセス
　上記1.5で指定したポート番号5000番にてブラウザでアクセスすると、  
　「Hello World」が表示されることを確認します。  

## 1.8. コンテナ停止
　起動中のコンテナを停止します。
> docker stop [コンテナID]   

　docker psコマンドの結果で表示されるコンテナIDを指定します。
## 1.9. コンテナ削除
　停止中のコンテナを削除します。  
　stopはコンテナ停止のみ、実体は残っているため、  
　rmコマンドで削除する必要があります。
> docker rm [コンテナID]
