コンテナ技術　社内勉強会用　資料
# 2. 応用編
　※dockerコマンドで容易にコンテナを作れますが、どのような仕組みで動いているか少し知っていると理解が深まります  
　そこで、コンテナを構成している主要素の namespace、cgroup、overlayfs について、少し深堀します  
## 2.1. docker環境を準備
　動作環境は各自準備ください  
　本手順は、CentOS7で事前検証しています  
　スペック:CPU:2、Mem:2G, HDD:8G on VirtalBox  
## 2.2. 名前空間(namespace)
#### （１）ホスト名(uts) 
　まずは、ホスト名における名前空間を見てみます  
　※本検証は、sshなどで複数のterminalを開いて行ってください  
 
　①現在のプロセスの名前空間一覧を表示  
 　　inode番号が、所属する名前空間となる  
> ls -l /proc/$$/ns

　②uts名前空間の作成  
　　システムコールのunshareコマンドを使います
> unshare -u  

　③再び名前空間一覧を表示  
　　すると、utsのinode番号が変わっていることが分かる  
> ls -l /proc/$$/ns

　④ホスト名を変更する  
　　ホスト名を変更して、pingを行うと変更したホスト名で応答が正常に返ってくる  
> hostname hoge  
> hostname  
> ping -c 3 hoge　

　⑤別のTerminal上で、確認すると inode番号が変わっていないことが見て取れる  
　　hostnameコマンドで確認すると、元のnamespaceでは、影響がないことが分かる  
> ls -l /proc/$$/ns  
> hostname   
  
ntsについては、非常にシンプルに名前空間を分けてhost名を変更できることがわかりました  

--- 
#### （２）プロセスID(pid) 
　続いて、プロセスIDについて確認してみます  
 
　①pid名前空間の作成  
> unshare -p -f  
> echo $$  
> ps aux  

　　echo $$とすると、プロセスIDが　1番が割り当てられています  
　　しかし、ps aux コマンドを見ると、プロセスIDの１番は、systemd　のプロセスとなっており、合っていません  
  
　　psコマンドは、/procを参照して表示しています(/procはマウントポイントに紐づいています)  
　　そのため、pid名前空間を新たに作った場合は、mountポイントも併せて名前空間を作成する必要があります  
  
　　しかし、今回はmountポイントは変更していないため、mount名前空間は元の空間を参照しているので、食い違っています  
 
　②pid名前空間をprocマウント付きで再作成  
> exit  
> unshare -p -f --mount-proc  
> echo $$  
> ps aux  

　　mount-procオプションを付加することで、/procの名前空間作成とマウントを並行して実施してくれます  
　　これで、psコマンド上でも、プロセスIDの1番が自身のbashコマンドになりました  
  
　　プロセス空間が別になったため、他のプロセスが見えなくなり、大分すっきりしたと思います
 
以上のようにプロセス空間を簡単に分離できました
 
---
#### （３）ディレクトリ(chroot/pivot_root) 
　続いて、ディレクトリ分離について確認してみます  
　Linuxでは、/home/XXXのようなディレクトリ構造となりますが、  
　コンテナ間で互いのディレクトリが見えては困るので、分離する必要があります  
 
　①分離用のディレクトリを作成  
> useradd userYY

　　ユーザをスイッチし、myfileを作ります  
> su - userYY  
> touch myfile  
> exit  
 
　②chrootコマンドにて、/home/userYYディレクトリを隔離　　
> MYROOT=/home/userYY  
> cp -a /{bin,lib,lib64} $MYROOT  
> mkdir -p $MYROOT/usr/{bin,lib,lib64}  
> cp -p /usr/bin/* $MYROOT/usr/bin > /dev/null 2>&1  
> cp -p /lib64/* $MYROOT/usr/lib64 > /dev/null 2>&1  
> sudo chroot $MYROOT  
> pwd  
> ls -l  

　　pwd を見ると / ディレクトリになっており、　①でコピーしたmyfileのみしか見れないようになります  
　　このように参照可能なディレクトリを無理やりルートディレクトリに置き換える仕組みとなります  

　③chrootの問題点  
　　chrootは、SFTPでサーバにログインする際に、対象ディレクトリを制限する際にも使われる技術ですが、  
　　簡単に脱出できてしまう問題があります  

　　次のC言語プログラムを実行すると、/home/userYYディレクトリからその上のディレクトリに移動できてしまいます  
  
　　テスト用Cコード  
```
  void main(int argc, char *argv[]) { 
      mkdir(".xx", 0755); 
      chroot(".xx"); 
      int i; 
      for (i = 0; i < 256; i++) { chdir(".."); } 
      chroot(".") ; 
      argv++; 
      execvp(argv[0], argv); 
  }
```

　この問題を回避するため、dockerなどでは、pivot_rootという仕組みを使っています  
　　chrootは、　指定したディレクトリを　/ ルートディレクトリに置き換える  
　　pivot_rootは、　from と to　を指定して、ディレクトリを取り換える  
　という違いがあります  
 
　pivot_rootは、chrootに比べ複雑なので、今回は詳しい説明は割愛します  
　興味がある方は、pivot_rootで検索してみてください  

---
## 2.3. 制御グループ(cgroup)
　　CPUやメモリー使用量を各コンテナで制御する仕組みとして、cgroupが使われますので、少し動きを確認します  
　　cgroupは、/sys/fs/cgroupのマウントポイント内で、階層構造で管理しています  
　　dockerでCPU制限をする例を見ながら、しくみを確認してみます  
#### （１）CPU使用率(cpu.cfs_quota_us/cpu.cfs_period_us)
　　CPU使用率を○○％に抑えるなどの設定は、cfs_quota_usとcfs_period_usを組み合わせて行っています  
 
　①まずは制限なしでdockerを起動  
　　別のTerminal上で、topコマンドなどで確認すると、CPUが100%近くなっているのが確認できます  
> docker run --rm -it ubuntu  /bin/bash  
> yes > /dev/null 2>&1  

　②コンテナのCPU使用率上限を20%に抑える  
　　別のTerminal上で、topコマンドなどで確認すると、CPUが20%付近で抑えられているのが確認できます  
> docker run --rm --cpuset-cpus 0 --cpu-quota 10000 --cpu-period 50000 -it ubuntu /bin/bash  
> yes > /dev/null 2>&1  

　③cgroupの設定内容を確認  
　　/sys/fs/cgroup/cpu/docker/[コンテナID]/以下にある  
　　　cpu.cfs_quota_usには、10000 = 10ミリ秒  
　　　cpu.cfs_period_usには、50000 = 50ミリ秒  
　　がセットされており、この値を参照して、cgroupがリソース使用量を制限しています  
> ls -l /sys/fs/cgroup/cpu/docker/[コンテナID]/  
> cat  cpu.cfs_quota_us  
> cat  cpu.cfs_period_us  

このような仕組みで、CPU使用率を制限できます  

---
#### （２）CPU共有割合(cpu.shares)
  　上述（１）ではCPU使用率を制限しましたが、こちらは複数のコンテナ間で利用するCPUの共有割合を指定するやり方になります  
　　cgroupの設定値は、cpu.sharesを使います  
  
　①コンテナの3台のCPU共有割合を20%,30%,50%としたい  
　　Terminalを３つ立ち上げ、以下を実行します  
> docker run  --rm --name cont1 --cpuset-cpus 0 --cpu-shares 1024 -it ubuntu  /bin/bash  
> docker run  --rm --name cont2 --cpuset-cpus 0 --cpu-shares 1536 -it ubuntu  /bin/bash  
> docker run  --rm --name cont3 --cpuset-cpus 0 --cpu-shares 2560 -it ubuntu  /bin/bash  

　　また、次のコマンドを投入して、各コンテナのCPU使用率を上げます  
　　別のTerminalを立ち上げ、topコマンドを参照すると、コンテナ３つの使用率が、20,30,50%程度に按分されているのが見て取れます  
> yes > /dev/null 2>&1  

　②cgroupの設定内容を確認  
　　/sys/fs/cgroup/cpu/docker/[コンテナID]/以下にある  
　　　cpu.shares に、1024,1536,2560がそれぞれ入っています  
　　これらは、1024:1536:2560の比率で制御されています  
　　なお、デフォルト値は、1024となっています  
> ls -l /sys/fs/cgroup/cpu/docker/[コンテナID]/  
> cat cpu.shares  

このような仕組みで、CPU共有割合を制御できます  

---
## 2.4. 結合ファイルシステム(overlayfs)
　dockerなどのコンテナでは、ディスクを効率的に使える結合ファイルシステムが使われています  
　Dockerfileを作る際に、ディスク使用の無駄を発生させないためにも、この仕組みを知っておく必要があります  
　実際に見ながら、動きを確認してみます  
#### （１）overlayにてマウント
　　overlayfsの仕組みは、lowerディレクトリ×複数と、upperディレクトリx1と、mergedディレクトリx1で構成されています  
　　これらのディレクトリを重ねて、一つのディレクトリに見せる技術になります  
　　といっても、この説明だけではよく分からないと思いますので、実際に動かします  

　①まず、実験用ディレクトリを作成 
> mkdir lower1 lower2 upper merged  
> mkdir work  

　②lower1と2に、サンプルtxtを作成  
> echo "Created in Lower1" > lower1/abc.txt  
> echo "Created in Lower2" > lower2/xyz.txt  

　③overlayfsでマウント  
> mount -t overlay overlay -o lowerdir=lower1:lower2,upperdir=upper,workdir=work merged  

---
#### （２）overlayの動きを確認
　①mergedディレクトリの確認  
> cd ./merged  
> ls -l  

　　abc.txt および xyz.txt が見れる  
　　両者はそれぞれ、lower1、lower2 に実体があるが、mergedディレクトリに並んであるように見えます  
 
　②新規ファイル作成  
> echo "Created in merged" > hoge.txt  
> ls -l  
> ls -l ../upper  

　　mergedディレクトリ上には、abc.txt、xyz.txt と並んで、hoge.txt ができており  
　　upperディレクトリには、新規に作成したhoge.txtができていることが分かります  
　　つまりは、新規にファイルを作成すると、upperに実体ができ、それをmergedに透過させて表示させています  
　　これで、overlayfsの仕組みが少し見えてきたと思います  
 
　③ファイルの更新  
> echo "Changed in merged" > abc.txt  
> ls -l  
> ls -l ../upper

　　mergedディレクトリ上には、abc.txt が更新され、  
　　また、upperディレクトリ上にも abc.txt が出現して、変更されたことが分かります  
 
　④ファイル削除
> rm xyz.txt  
> ls -l  
> ls -l ../upper
 
　　mergedディレクトリ上には、xyz.txt が削除されますが、  
　　upperディレクトリ上では、xyz.txt が残った状態となります  
　　ls -l でみると以下の様に表示されますが、一番左のcというキャラクタビットがONになります  
　　c---------. 1 root root 0, 0  xyz.txt  
　　これは、削除されたことを示すフラグみたいなものになります  whiteoutなどとも呼ばれます  
 
　このように、削除した場合も、実体が消えるわけではなく、lower1,2などに残り続けますので、  
　注意が必要です  

---
#### （３）docker imageのレイアウトを確認
　　最後に、dockerイメージについても確認しておきます  
> docker inspect [イメージリポジトリ名] or [イメージID]  

　こちらのコマンドでイメージ内容を確認すると、lower,upper,mergedの記載があります  

　これらは、/var/lib/docker/overlay2/　以下に展開されて、普通のディレクトリとしてみることが可能です  
 
　以下は、出力例の抜粋  
```
 "Data": {
         "LowerDir": "/var/lib/docker/overlay2/5315f85cb9a3fe07990fea8b7ced634ce9bcefc78818aee1ecf0fb8300d243b0/diff:/var/lib/docker/overlay2/1aaf711a64dae95d79c6f16642ac8ef6d190ce77fe697496d7452bd1db2704ae/diff",
         "MergedDir": "/var/lib/docker/overlay2/3785af07e87821cf9df69ee3f66dee3c6dac11387e173f4b2e934cbeeb32059e/merged",
         "UpperDir": "/var/lib/docker/overlay2/3785af07e87821cf9df69ee3f66dee3c6dac11387e173f4b2e934cbeeb32059e/diff",
         "WorkDir": "/var/lib/docker/overlay2/3785af07e87821cf9df69ee3f66dee3c6dac11387e173f4b2e934cbeeb32059e/work"
        },
       "Name": "overlay2"
```
