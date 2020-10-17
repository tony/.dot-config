sudo poudriere ports -c -p $USER -M $HOME/work/freebsd/ports -F
sudo poudriere jail -c -j freebsd_11-current -v head -m svn
sudo poudriere jail -c -j 101amd64 -v head -v 10.2-RELEASE -a amd64
