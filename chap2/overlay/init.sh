umount merged > /dev/null 2>&1
rm -rf ./lower1 ./lower2 ./upper ./merged ./work
mkdir lower1 lower2 upper merged
mkdir work
echo "Created in Lower1" > lower1/abc.txt
echo "Created in Lower2" > lower2/xyz.txt
mount -t overlay overlay -o lowerdir=lower1:lower2,upperdir=upper,workdir=work merged
