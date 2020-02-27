# permit mount drives for user otus

groupadd mount_group
usermod -aG mount_group otus

touch /etc/polkit-1/rules.d/10-mount.rules
echo "polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
             action.id == "org.freedesktop.udisks2.filesystem-mount") &&
                     subject.isInGroup("mount_group")) {
                             return polkit.Result.YES;
                                 }
                                 });" >> /etc/polkit-1/rules.d/10-mount.rules
								 
systemctl restart polkit.service
								 
# permit ssh login for user otus2 only from 12-00 to 20-00  every day
echo "account    required     pam_time.so" >> /etc/pam.d/sshd
echo "sshd;*;otus2;Al1200-2000" >> /etc/security/time.conf

# change root for user otus3 while login via ssh
USR=otus3
RD=/home/$USR/chroot
mkdir $RD
cd $RD

DIRS="bin sbin lib64 etc dev home usr usr/bin /usr/sbin usr/lib home/$USR"
for dir in $DIRS; do
mkdir -p $dir
done

CMDS="/bin/sh /bin/bash /bin/cat /bin/ls /bin/cp /bin/mv /bin/cd /bin/rm /bin/mkdir /usr/bin/id"
LIBS=`ldd $CMDS|grep -v ':$'|grep -v "not a dynamic executable"|cut -f 3 -d " "|sort|uniq|sed 1d`

for lib in $LIBS; do
cp -f $lib .$lib
done
cp -f /lib64/ld-linux-x86-64.so.2 ./lib64

for cmd in $CMDS; do
cp -f $cmd .$cmd
done

mount --bind -nodev /dev $RD/dev
mount --bind -nodev /dev/pts $RD/dev/pts
mount --bind -nodev /dev/null $RD/dev/null

chown root:root -R $RD
chown $USR:$USR $RD/home/$USR
chown root:root $RD/..
chmod 755 $RD -R
chmod 700 $RD/home/$USR

echo "Match User $USR" >> /etc/ssh/sshd_config
echo "	ChrootDirectory $RD" >> /etc/ssh/sshd_config

cp /etc/profile $RD/etc
echo "export PATH=$PATH:/bin" >> $RD/etc/profile

systemctl restart sshd

