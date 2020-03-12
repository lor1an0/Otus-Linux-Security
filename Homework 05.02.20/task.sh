# permit mount drives for user otus
groupadd mount_group
usermod -aG mount_group otus
yum -y install udisks2
yum -y install policycoreutils-python
\cp --no-preserve=context /vagrant/files/10-mount.rules /etc/polkit-1/rules.d/10-mount.rules
		
#change allowed logon time for user otus2 from 12:00 to 20:00
sed -ie '/account.*include.*password-auth/ a\account required pam_time.so' /etc/pam.d/sshd
\cp -f --no-preserve=context /vagrant/files/time.conf /etc/security
	
# change root for user otus3 while login via ssh
USR=otus3
RD=/home/$USR/chroot
mkdir $RD
cd $RD

DIRS="bin sbin lib64 etc dev home usr usr/bin /usr/sbin usr/lib home/$USR"
for dir in $DIRS; do
mkdir -p $dir
done

CMDS="/usr/bin/whoami /bin/sh /bin/bash /bin/cat /bin/ls /bin/cp /bin/mv /bin/cd /bin/rm /bin/mkdir /usr/bin/id"

\cp -Rf /usr/lib64 $RD

for cmd in $CMDS; do
cp -f $cmd .$cmd
done

mount --bind -nodev /dev $RD/dev
mount --bind -nodev /dev/pts $RD/dev/pts
mount --bind -nodev /dev/null $RD/dev/null

chmod 777 /dev/null 
chown root:root -R $RD
chown root:root $RD/..
chown $USR:$USR $RD/home/$USR
chmod 755 $RD -R
chmod 700 $RD/home/$USR

cp /etc/profile $RD/etc
cp /etc/passwd $RD/etc
cp /etc/group $RD/etc
cp /etc/nsswitch.conf $RD/etc
echo "export PATH=$PATH:/bin" >> $RD/etc/profile
  
sudo \cp -f --no-preserve=context /vagrant/files/sshd_config /etc/ssh/sshd_config

systemctl restart sshd
systemctl restart polkit.service
