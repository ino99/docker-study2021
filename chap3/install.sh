# install docker & kubectl & minikube  for centos7


KUBE_VER="v1.20.2"
sudo yum update -y  

# Install Docker-ce
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo  
sudo yum install -y docker-ce docker-ce-cli containerd.io  
sudo yum install -y conntrack  
sudo systemctl start docker  
sudo systemctl enable docker  

#Install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBE_VER}/bin/linux/amd64/kubectl -k  
chmod +x ./kubectl  
mv -f ./kubectl /usr/local/bin  


#Install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -k  
chmod +x minikube  
install minikube /usr/local/bin/  

