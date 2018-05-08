1、常见目录
ORACLE_BASE/../oraInventory   ------清单目录，存储oracle软件的安装清单
ORACLE_HOME=ORACLE_BASE/product/<version>/<install_name> 
ADR_HOME=ORACLE_BASE/diag/rdbms/lower(db_unique_name)/instance_name   ----诊断目录11g

mkdir -p /oracle/grid/grid
chown -R grid:oinstall /oracle/grid
chmod -R 775 /oracle/grid

mkdir -p /oracle/database
chown -R oracle:oinstall /oracle/database
chmod -R 775 /oracle/database


2、常见用户
oinstall                 安装和升级oracle                          oraInst.loc文件中的inst_group变量，还可以在应答文件中使用UNIX_GROUP_NAME
dba        sysdba        创建、删除、修改、启动、                  应答文件DBA_GROUP
                         关闭数据库，切换日志归档模式，
                         备份恢复数据库

oper       sysoper       启动、关闭、修改、备份、恢复数据库         应答文件OPER_GROUP
                         修改归档模式

asmdba     sysdba自动    管理ASM实例
           存储管理

asmoper    sysoper自动   启动、停止ASM实例
           存储管理
          
asmadmin   sysasm        挂载、卸载磁盘组，管理其他存储设备

backupdba  sysbackup     启动关闭和执行备份恢复                    应答文件BACKUPDBA_GROUP
                         （12c）

dgdba     sysdg          管理Data Guard（12c）                     应答文件DGDBA_GROUP

kmdba    syskm           加密管理相关操作                          应答文件KMDBA_GROUP


----------12c
###
清理环境
userdel -r grid
userdel -r oracle
groupdel oinstall
groupdel dba
groupdel oper
groupdel asmadmin
groupdel asmdba
groupdel asmoper
groupdel backupdba
groupdel dgdba
groupdel kmdba





####创建用户及组
/usr/sbin/groupadd -g 50001 oinstall
/usr/sbin/groupadd -g 50002 dba
/usr/sbin/groupadd -g 50003 oper
/usr/sbin/groupadd -g 50004 asmadmin
/usr/sbin/groupadd -g 50005 asmdba
/usr/sbin/groupadd -g 50006 asmoper
/usr/sbin/groupadd -g 50007 backupdba
/usr/sbin/groupadd -g 50008 dgdba
/usr/sbin/groupadd -g 50009 kmdba
/usr/sbin/useradd -u 50001 -g oinstall -G asmadmin,asmdba,asmoper grid
/usr/sbin/useradd -u 50002 -g oinstall -G dba,asmdba,oper,backupdba,dgdba,kmdba oracle
echo "oracle" | passwd --stdin oracle
echo "oracle" | passwd --stdin grid
####更新用户及密码
echo "Oracle@2o17" | passwd --stdin oracle
echo "Oracle@2o17" | passwd --stdin grid


--------11g

/usr/sbin/groupadd -g 50001 oinstall
/usr/sbin/groupadd -g 50002 dba
/usr/sbin/groupadd -g 50003 oper
/usr/sbin/groupadd -g 50004 asmadmin
/usr/sbin/groupadd -g 50005 asmdba
/usr/sbin/groupadd -g 50006 asmoper
/usr/sbin/useradd -u 50009 -g oinstall -G dba,asmdba,oper   oracle   
/usr/sbin/useradd -u 50008 -g oinstall -G dba,asmadmin,asmdba,asmoper grid
echo "oracle" | passwd --stdin oracle
echo "oracle" | passwd --stdin oracle


echo "Oracle@2o16" | passwd --stdin oracle
echo "Oracle@2o16" | passwd --stdin grid





/usr/sbin/groupadd -g 50010 cloudera
/usr/sbin/useradd -u 50010 -g cloudera -G cloudera,root   cloudera   
echo "cloudera" | passwd --stdin cloudera






 mkdir  /opt/oracle
 mkdir  /opt/grid
 chown oracle:oinstall  /opt/oracle
 chown grid:oinstall  /opt/grid

3、主机参数
3.1、内核参数
------linux
vi /etc/sysctl.conf

# for oracle rac @yjb @20170517

fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 60293120
kernel.shmmax = 246960619520
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
kernel.panic_on_oops = 1
#vm.nr_hugepages=87040
vm.swappiness=10 
#vm.min_free_kbytes=10485760

-------------内存调优
sysctl -w vm.min_free_kbytes=4096000  （设置为内核保留的内存大小）
sysctl -w vm.vfs_cache_pressure=200    （默认值：100表示内核以平等的速度去考虑pagecache和swapcache的回收再利用，减小它，会触发内核保持目录与inodes的缓存内存。增大它，会触发内核回收再利用目录与inodes的缓存内存。）
sysctl -w vm.swappiness=40   （老版本的 linux 是设置 vm.pagecache 参数 代表着 100-40=60 即60%内存使用率就开始使用swap)

#for oracle
###设置异步IO块的大小，建议1M及以上
fs.aio-max-nr = 1048576     
fs.file-max = 6815744
##Max(2097152,(物理内存大小/pagesize)),pagesize可以通过命令getconf PAGE_SIZE获得
kernel.shmall = 2097152   
###物理内存 * 0.8，不低于SGA_MAX_SIZE 
kernel.shmmax = 1568892928 
kernel.shmmni = 4096
# semaphores: semmsl, semmns, semopm, semmni
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default=262144
net.core.rmem_max=4194304
net.core.wmem_default=262144
net.core.wmem_max=1048586
net.ipv4.ip_local_port_range = 9000 65500
###这个参数是个bug：18468128
kernel.panic_on_oops = 1  
kernel.pid_max=139264
net.ipv4.tcp_wmem = 262144 262144 262144
net.ipv4.tcp_rmem = 4194304 4194304 4194304
net.ipv4.conf.all.accept_redirects=0
 ####大页   cat /proc/meminfo |grep Huge   ipcs -a
vm.nr_hugepages=7680  


kernel.shmall = 2097152 # 可以使用的共享内存的总量。
kernel.shmmax = 2147483648 # 最大共享内存段大小。
kernel.shmmni = 4096 # 整个系统共享内存段的最大数目。
kernel.sem = 250 32000 100 128 # 每个信号对象集的最大信号对象数；系统范围内最大信号对象数；每个信号对象支持的最大操作数；系统范围内最大信号对象集数。
fs.file-max = 65536 # 系统中所允许的文件句柄最大数目。
net.ipv4.ip_local_port_range = 1024 65000 # 应用程序可使用的IPv4端口范围。
net.core.rmem_default = 1048576 # 套接字接收缓冲区大小的缺省值
net.core.rmem_max = 1048576 # 套接字接收缓冲区大小的最大值
net.core.wmem_default = 262144 # 套接字发送缓冲区大小的缺省值
net.core.wmem_max = 262144 # 套接字发送缓冲区大小的最大值



/sbin/sysctl -a | grep kernel.sem |awk \'{printf ("%d  %d  %d  %d\n",$3,$4,$5,$6)}\'
/sbin/sysctl -a | grep vm.hugetlb_shm_group |awk '{printf ("%d\n",$3)}'

cat /proc/meminfo |grep HugePages_Total|awk '{printf ("%d\n",$2)}'

3.2、用户资源组限制
-----linux
grid  oracle 用户资源限制
vi  /etc/security/limits.conf
#for oracle rac @yjb @20170517
grid  soft  nproc   32768
grid  hard  nproc   65536
grid  soft  nofile  32768
grid  hard  nofile  65536
grid  soft  stcak   32768
grid  hard  stcak   65536
grid  soft  memlock  -1
grid  hard  memlock  -1
oracle  soft  nproc   32768
oracle  hard  nproc   65536
oracle  soft  nofile  32768
oracle  hard  nofile  65536
oracle  soft  stack   32768
oracle  hard  stack   65536
oracle  soft  memlock  -1
oracle  hard  memlock  -1


grid  soft  nproc   32768
grid  hard  nproc   65536
grid  soft  nofile  32768
grid  hard  nofile  65536
grid  soft  stcak   32768
grid  hard  stcak   65536
grid  soft  memlock  -1
grid  hard  memlock  -1

*  soft  nproc   32768
*  hard  nproc   65536
*  soft  nofile  32768
*  hard  nofile  65536
*  soft  stack   32768
*  hard  stack   65536
*  soft  memlock  -1
*  hard  memlock  -1

ora11g  soft  nproc   32768
ora11g  hard  nproc   65536
ora11g  soft  nofile  32768
ora11g  hard  nofile  65536
ora11g  soft  stack   32768
ora11g  hard  stack   65536
ora11g  soft  memlock  -1
ora11g  hard  memlock  -1



vi /etc/pam.d/login
#for oracle  
session required pam_limits.so    ----登陆限制

echo "
#for oracle 
session required pam_limits.so" >>/etc/pam.d/login;cat /etc/pam.d/login


3.3、环境变量
-------linux
vi /etc/profile
if [ $USER = "oracle" ] || [ $USER = "grid" ]; then
if [ $SHELL = "/bin/ksh" ]; then
ulimit -p 16384
ulimit -n 65536
else
ulimit -u 16384 -n 65536
fi
umask 022
fi


关闭防火墙及selinux
-----selinux
#查看selinux状态
getenforce   
#临时关闭selinux 重启失效
setenforce 0;getenforce 
#彻底关闭
vi /etc/selinux/config
SELINUX=disabled

echo "# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted processes are protected,
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted " >/etc/selinux/config




------/dev/shm
vi /etc/fstab
tmpfs      /dev/shm      tmpfs   defaults,size=5g   0   0

mount -o remount /dev/shm

-----
vi /etc/sysconfig/network
NOZEROCONF=yes


-------iptables
##查看状态
iptables -L
##清理规则临时允许，重启失效
iptables -F
#彻底关闭
chkconfig iptables off
service iptables stop


vi /home/oracle/.bash_profile
export ORACLE_BASE=/opt/oracle/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11204/db_1
export ORACLE_SID=xspaasd3
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
umask 0022
# export DISPLAY=10.211.120.206:0.0


export ORACLE_BASE=/opt/oracle/oracle
export ORACLE_HOME=$ORACLE_BASE/product/9208/db_1
export ORACLE_SID=
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
# export DISPLAY=10.211.120.206:0.0



vi /home/grid/.bash_profile
export ORACLE_BASE=/opt/oracle/grid/grid
export ORACLE_HOME=/opt/oracle/12201/grid
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID=+ASM1
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
umask 0022
# export DISPLAY=10.211.120.206:0.0


mkdir -p /opt/oracle/software
chown oracle:oinstall -R  /opt/oracle
chmod 775 -R  /opt/oracle




vi /home/oracle/.profile
export ORACLE_BASE=/opt/oracle/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0.4/db_1
export ORACLE_SID=
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
# export DISPLAY=10.211.120.206:0.0

vi /home/grid/.profile
export ORACLE_BASE=/opt/oracle/grid/grid
export ORACLE_HOME=/opt/oracle/11.2.0.4/grid
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID=+ASM1
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
#export DISPLAY=10.211.120.206:0.0









####12c设置
ulimit -Sn 4096
ulimit -Hn 65536
limit -Su 2047
ulimit -Hu 16384
ulimit -Ss 10240
ulimit -Hs 32768





####其他环境变量按需修改
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/10.2.0/db_1
export ORA_CRS_HOME=$ORACLE_BASE/product/crs
export ORACLE_SID=rac3
export PATH=.:${PATH}:$HOME/bin:$ORACLE_HOME/bin
export PATH=${PATH}:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin
export PATH=${PATH}:$ORACLE_BASE/common/oracle/bin
export ORACLE_TERM=xterm
export TNS_ADMIN=$ORACLE_HOME/network/admin
export ORA_NLS10=$ORACLE_HOME/nls/data
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export CLASSPATH=$ORACLE_HOME/JRE
export CLASSPATH=${CLASSPATH}:$ORACLE_HOME/jlib
export CLASSPATH=${CLASSPATH}:$ORACLE_HOME/rdbms/jlib
export CLASSPATH=${CLASSPATH}:$ORACLE_HOME/network/jlib
export THREADS_FLAG=native
export TEMP=/tmp
export TMPDIR=/tmp



3.4、修改主机名及hosts文件
-------linux
vi  /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=rac12c01
NOZEROCONF=yes

--------RHEL6
service avahi-daemon start 
chkconfig avahi-daemon on 

service avahi-daemon stop
chkconfig avahi-daemon off 


--------RHEL7
systemctl enable avahi-daemon.service
/bin/systemctl start  avahi-daemon.service


ifconfig eth0:0 169.254.100.100 netmask 255.255.0.0 up
ifconfig eth0:0 169.254.100.200 netmask 255.255.0.0 up


vi /etc/hosts


#Public
188.102.15.214    zjhz-xspaase01
188.102.15.215    zjhz-xspaase02

#VIP
188.102.15.221    zjhz-xspaase01-vip   
188.102.15.222    zjhz-xspaase02-vip   

#Private
172.16.8.9    zjhz-xspaase01-priv  
172.16.8.10    zjhz-xspaase02-priv  

###SCANIP
188.102.15.223    xspaase-scan01




#Public
188.102.15.210   zjhz-xspaasd01                   
188.102.15.211   zjhz-xspaasd02
188.102.15.212   zjhz-xspaasd03

#VIP
188.102.15.217   zjhz-xspaasd01-vip                   
188.102.15.218   zjhz-xspaasd02-vip
188.102.15.219   zjhz-xspaasd03-vip

#Private
172.16.8.6   zjhz-xspaasd01-priv                  
172.16.8.7   zjhz-xspaasd02-priv
172.16.8.8   zjhz-xspaasd03-priv

188.102.15.220    xspaasd-scan01


4、其他配置
4.1、oraInst.loc
linux存放在/etc/   其他Unix存在/var/opt/oracle/
--内容
inventory_loc=ORACLE_BASE/../oraInventory   ---按照实际定
inst_group=oinstall


4.2、应答文件
./response/db_install.rsp
./response/dbca.rsp
./response/netca.rsp

将数据库listener.ora, sqlnet.ora的超时设置为0（即不限制，Oracle 11g默认值为60秒），然后重启数据库。
– sqlnet.ora设置，每个DB节点需更改
SQLNET.INBOUND_CONNECT_TIMEOUT = 0
– listener.ora设置，每个DB节点需更改
INBOUND_CONNECT_TIMEOUT_LISTENER = 0


-----------------------------------软件检查
--------10gR2 RHEL4 Linux x86-64
binutils-2.15.92.0.2-10.EL4
compat-db-4.1.25-9
compat-libstdc++-33-3.2.3-47.3
compat-libstdc++-33-3.2.3-47.3(i386)
compat-libstdc++-296.i386
control-center-2.8.0-12
gcc-3.4.3-22.1
gcc-c++-3.4.3-22.1
glibc-2.3.4-2
glibc-2.3.4-2(i386)
glibc-common-2.3.4-2
glibc-devel-2.3.4-2
glibc-devel-2.3.4-2(i386)
gnome-libs-1.4.1.2.90-44.1
libaio-0.3.96-3
libgcc-3.4.3-9.EL4
libstdc++-3.4.3-9.EL4
libstdc++-devel-3.4.3-9.EL4
make-3.80-5
numactl-0.6.4.x86_64
pdksh-5.2.14-30
sysstat-5.0.5-1

--------10gR2 RHEL5 Linux x86-64
yum install  binutils compat-db compat-gcc-34 compat-gcc-34-c++ compat-libstdc++-33 compat-libstdc++-33.i386 compat-libstdc++-296.i386 gcc gcc-c++ glibc glibc.i386 glibc-common glibc-devel glibc-devel.i386 glibc-headers libgcc.i386 libXp.i386 libXt.i386 libXtst.i386 libaio libaio-devel libgcc libstdc++ libstdc++-devel libgomp make numactl-devel.x86_64 sysstat unixODBC.x86_64 unixODBC.i386 unixODBC-devel.x86_64 unixODBC-devel.i386

--------10gR2 SLES10 Linux x86-64
binutils-2.16.91.0.5
compat-libstdc++-5.0.7-22.2
gcc-4.1.0
gcc-c++-4.1.0
glibc-2.4-31.63
glibc-32bit-2.4-31.63 (32 bit)
glibc-devel-2.4-31.63
glibc-devel-32bit-2.4-31.63 (32 bit)
libaio-0.3.104
libaio-32bit-0.3.104 (32 bit)
libaio-devel-0.3.104
libelf-0.8.5
libgcc-4.1.0
libstdc++-4.1.0
libstdc++-devel-4.1.0
make-3.80
numactl-0.9.6.x86_64
sysstat-6.0.2


--------10gR2 SLES11 Linux x86-64
binutils-2.19
gcc-4.3
gcc-32bit-4.3
gcc-c++-4.3
glibc-2.9
glibc-32bit-2.9
glibc-devel-2.9
glibc-devel-32bit-2.9
ksh-93t
libaio-0.3.104
libaio-32bit-0.3.104
libaio-devel-0.3.104
libaio-devel-32bit-0.3.104
libstdc++33-3.3.3
libstdc++33-32bit-3.3.3
libstdc++43-4.3.3_20081022
libstdc++43-32bit-4.3.3_20081022
libstdc++43-devel-4.3.3_20081022
libstdc++43-devel-32bit-4.3.3_20081022
libgcc43-4.3.3_20081022
libstdc++-devel-4.3
make-3.81
sysstat-8.1.5



-----11gR2  RHEL 6   x86-64
rpm -q --qf '%{NAME}-%{VERSION}-%{RELEASE} (%{ARCH})\n'  \
binutils.x86_64 compat-libcap1.x86_64 compat-libstdc++-33.x86_64 compat-libstdc++-33.i686 \
gcc.x86_64 gcc-c++.x86_64 glibc.i686 glibc.x86_64 glibc-devel.x86_64 glibc-devel.i686 ksh libgcc.i686 libgcc.x86_64 \
libstdc++.x86_64 libstdc++.i686 libstdc++-devel.x86_64 libstdc++-devel.i686 libaio.x86_64 libaio.i686 libaio-devel.x86_64  \
libaio-devel.i686 make sysstat.x86_64 unixODBC.x86_64 unixODBC.i686 unixODBC-devel.x86_64 unixODBC-devel.i686 elfutils-libelf-devel\
|grep -E '^package'

yum install -y  binutils.x86_64 compat-libcap1.x86_64 compat-libstdc++-33.x86_64 compat-libstdc++-33.i686 \
gcc.x86_64 gcc-c++.x86_64 glibc.i686 glibc.x86_64 glibc-devel.x86_64 glibc-devel.i686 ksh libgcc.i686 libgcc.x86_64 \
libstdc++.x86_64 libstdc++.i686 libstdc++-devel.x86_64 libstdc++-devel.i686 libaio.x86_64 libaio.i686 libaio-devel.x86_64  \
libaio-devel.i686 make sysstat.x86_64 unixODBC.x86_64 unixODBC.i686 unixODBC-devel.x86_64 unixODBC-devel.i686 elfutils-libelf-devel



-----11gR2  RHEL7   x86-64
yum install -y  binutils.x86_64 compat-libcap1.x86_64 compat-libstdc++-33.el7.i686 make.x86_64 \
compat-libstdc++-33.x86_64 gcc.x86_64 gcc-c++.x86_64 glibc.i686 glibc.x86_64 glibc-devel.el7.i686  libstdc++.i686 \
glibc-devel.el7.x86_64 ksh libaio.i686 libaio.x86_64 libaio-devel.i686 libaio-devel.x86_64 libgcc.i686 libgcc.x86_64 \
libstdc++.x86_64 libstdc++-devel.el7.i686 libstdc++-devel.x86_64 libXi.i686 libXi.x86_64 libXtst.i686 libXtst.x86_64  \
sysstat.x86_64 unixODBC.x86_64 unixODBC.i686 unixODBC-devel.x86_64 unixODBC-devel.i686 elfutils-libelf-devel



-----11gR2  SUSE 11 x86-64



------- 12cR1 RHEL6 x86-64
yum install -y  binutils.x86_64 compat-libcap1.x86_64 compat-libstdc++-33.x86_64 compat-libstdc++-33..i686 gcc.x86_64 gcc-c++.x86_64 glibc.i686 glibc.x86_64 \
glibc-devel.x86_64 glibc-devel.i686 ksh libgcc.i686 libgcc.x86_64 libstdc++.x86_64 libstdc++.i686 libstdc++.x86_64 libstdc++-devel.x86_64 \
libaio.x86_64 libaio.i686 libaio-devel.x86_64 libaio-devel.i686 libXext.x86_64 libXext.i686 libXtst.x86_64 libXtst.i686 libX11.x86_64 \
libX11.i686 libXau.x86_64 libXau.i686 libxcb.x86_64 libxcb.i686 libXi.x86_64 libXi.i686 make.x86_64 sysstat.x86_64 nfs-utils.x86_64  \
unixODBC.x86_64 unixODBC.i686 unixODBC-devel.x86_64 unixODBC-devel.i686 elfutils-libelf-devel xorg-x11-utils.x86_64 xorg-x11-xauth.x86_64

------- 12cR1 RHEL7 x86-64
yum install -y binutils.x86_64    gcc.x86_64  gcc-c++.x86_64  glibc.i686  glibc.x86_64  glibc-devel.i686  glibc-devel.x86_64 \
libaio-devel.i686  libaio-devel.x86_64  ksh make.x86_64 libXi.i686 libXi.x86_64 libXtst.i686 libXtst.x86_64 libgcc.i686   \
libgcc.x86_64  libstdc++.i686 libstdc++.x86_64  libstdc++-devel.x86_64  libstdc++-devel.x86_64  sysstat.x86_64 libaio.i686  libaio.x86_64 \
unixODBC.x86_64 unixODBC.i686 unixODBC-devel.x86_64 unixODBC-devel.i686 compat-libcap1.x86_64 xorg-x11-utils.x86_64 xorg-x11-xauth.x86_64

--------12cR2 RHEL7 x86-64
yum install binutils.x86_64 compat-libcap1.x86_64 compat-libstdc++-33.i686 compat-libstdc++-33.x86_64 glibc.i686 \
glibc.x86_64 glibc-devel.i686 glibc-devel.x86_64 ksh libaio.i686 libaio.x86_64 libaio-devel.i686 libaio-devel.x86_64 libgcc.i686 \
libgcc.x86_64 libstdc++.i686 libstdc++.x86_64 libstdc++-devel.i686 libstdc++-devel.x86_64 libxcb.i686 libxcb.x86_64 libX11.i686 sysstat.x86_64 \
libX11.x86_64 libXau.i686 libXau.x86_64 libXi.i686 libXi.x86_64 libXtst.i686 libXtst.x86_64 make.x86_64 net-tools.x86_64 nfs-utils.x86_64 \
smartmontools.x86_64 unixODBC.x86_64 unixODBC.i686 unixODBC-devel.x86_64 unixODBC-devel.i686

--------12cR2 RHEL6 x86-64
yum install binutils.x86_64 gcc gcc-c++ compat-libcap1.x86_64 compat-libstdc++-33.x86_64 compat-libstdc++-33.i686 e2fsprogs.x86_64 \
e2fsprogs-libs.x86_64 glibc.i686 glibc.x86_64 glibc-devel.i686 glibc-devel.x86_64 pksh libaio.x86_64 libaio-devel.x86_64 \
libaio-devel.i686 libX11.i686 libX11.x86_64 libXau.i686 libXau.x86_64 libXi.i686  libXi.x86_64 libXtst.i686  libXtst.x86_64 \
libgcc.x86_64 libstdc++.i686 libstdc++.x86_64 libstdc++.i686 libstdc++-devel.x86_64 libxcb.i686 libxcb.x86_64  net-tools.x86_64 nfs-utils.x86_64 \
smartmontools.x86_64 sysstat.x86_64  libaio.i686 libgcc.i686  make.x86_64 unixODBC.x86_64 unixODBC.i686 unixODBC-devel.x86_64 unixODBC-devel.i686





------- 12cR1 SUSE11 x86-64
zypper in  binutils gcc gcc-c++ glibc glibc-devel \
ksh-93u libaio libaio-devel libcap1 libstdc++33 libstdc++33-32bit libstdc++43-devel libstdc++46 \
libgcc46 make sysstat xorg-x11-libs-32bit xorg-x11-libs xorg-x11-libX11-32bit xorg-x11-libX11 \
xorg-x11-libXau-32bit xorg-x11-libXau xorg-x11-libxcb-32bit xorg-x11-libxcb xorg-x11-libXext-32bit \
xorg-x11-libXext nfs-kernel-server unixODBC unixODBC-32bit unixODBC-devel unixODBC-devel-32bit

------- 12cR1 SUSE12 x86-64
zypper in binutils gcc gcc48 glibc glibc-32bit glibc-devel.x86_64 glibc-devel-32bit.x86_64 \
mksh libaio1 libaio-devel libcap1 libstdc++48-devel.x86_64 libstdc++48-devel-32bit.x86_64 \
libstdc++6.x86_64 libstdc++6-32bit.x86_64 libstdc++-devel.x86_64 libstdc++-devel-32bit.x86_64 libgcc_s1.x86_64 \
libgcc_s1-32bit.x86_64 make.x86_64 sysstat.x86_64 xorg-x11-driver-video.x86_64 xorg-x11-server.x86_64 \
xorg-x11-essentials xorg-x11-Xvnc xorg-x11-fonts-core xorg-x11 xorg-x11-server-extra.x86_64 \
xorg-x11-libs xorg-x11-fonts unixODBC unixODBC-32bit unixODBC-devel unixODBC-devel-32bit



## for python
yum install -y bzip2* sqlite-devel  openssl-devel readline-devel ncurses-devel tkinter

-------12cR1
yum install -y compat-libcap1.x86_64 compat-libstdc++-33.x86_64 gcc-c++.x86_64 ksh.x86_64 libaio-devel.x86_64 \
libstdc++-devel.x86_64 nfs-utils.x86_64 psmisc.x86_64 xorg-x11-utils.x86_64 xorg-x11-xauth.x86_64 \
gssproxy.x86_64 keyutils.x86_64 libXext.x86_64 libXi.x86_64 libXinerama.x86_64 libXmu.x86_64 \
libXrandr.x86_64 libXrender.x86_64 libXtst.x86_64 libXv.x86_64 libXxf86dga.x86_64 libXxf86misc.x86_64 \
libXxf86vm.x86_64 libdmx.x86_64 libevent.x86_64 libnfsidmap.x86_64 libtirpc.x86_64 rpcbind.x86_64 \
libXt.x86_64 libbasicobjects.x86_64 libcollection.x86_64 libini_config.x86_64 libref_array.x86_64 \
libverto-tevent.x86_64 libICE.x86_64 libSM.x86_64 libpath_utils.x86_64 libtalloc.x86_64 libtevent.x86_64



-----suse
rpm -q --qf '%{NAME}-%{VERSION}-%{RELEASE} (%{ARCH})\n'  \
binutils gcc gcc-32bit gcc-c++ glibc glibc-32bit glibc-devel glibc-devel-32bit ksh-93t \
libaio libaio-32bit libaio-devel libaio-devel-32bit libstdc++33 libstdc++33-32bit libstdc++43 \
libstdc++43-32bit libstdc++43-devel libstdc++43-devel-32bit libgcc43 libstdc++-devel make \
sysstat   unixODBC unixODBC-32bit unixODBC-devel unixODBC-devel-32bit  |grep -E '^package'

zypper in  binutils gcc gcc-32bit gcc-c++ glibc glibc-32bit glibc-devel glibc-devel-32bit ksh-93t \
libaio libaio-32bit libaio-devel libaio-devel-32bit libstdc++33 libstdc++33-32bit libstdc++43 \
libstdc++43-32bit libstdc++43-devel libstdc++43-devel-32bit libgcc43 libstdc++-devel make \
sysstat   unixODBC unixODBC-32bit unixODBC-devel unixODBC-devel-32bit 
  







/opt/oracle/11204/product/11.2.0/db_1/OPatch/opatch auto /opt/oracle/soft/20996923 -oh /opt/softs/p22191577/22191577  -ocmrf  /opt/oracle/11204/product/11.2.0/db_1/OPatch/ocm/bin/ocm.rsp 


/opt/oracle/grid/11.2.0/grid/OPatch/opatch lsinv
/opt/oracle/oracle/product/11.2.0/db_1/OPatch/opatch lsinv









mount /dev/cdrom /root/rhel-server-6.5-x86_64-dvd.iso

mount -o loop -t iso9660 /root/rhel-server-6.5-x86_64-dvd.iso /mnt/rhel65iso

-----------yum源配置
-------挂载ISO
mount /dev/cdrom /mnt/centos6.8
mkdir /mnt/rhel65iso
mount -o loop -t iso9660 /root/rhel-server-6.5-x86_64-dvd.iso /mnt/rhel65iso
----RHEL
mv /etc/yum.repos.d/rhel-source.repo  /etc/yum.repos.d/rhel-source.repo.20160902.bak
vi /etc/yum.repos.d/rhel-source.repo
[resource-ISO]
name=Red Hat Enterprise Linux $releasever - $basearch - Source
baseurl=file:///media/RHEL_5.11\ x86_64\ DVD/Server/
enabled=1
gpgcheck=0


mount /dev/cdrom    /mnt/cdrom
[base-source]
name=CentOS-$releasever - Base Sources
baseurl=file:///mnt/cdrom
gpgcheck=1
enabled=1
gpgkey=file:///mnt/cdrom/RPM-GPG-KEY-CentOS-7





vi /etc/yum.repos.d/rhel-source.repo
[resource-ISO]
name=Red Hat Enterprise Linux $releasever - $basearch - Source
baseurl=http://192.168.10.126/CentOS_6.5_Final/
enabled=1
gpgcheck=0


[CDH-5.10.1]
name=CDH-5.10.1 - Source
baseurl=http://192.168.10.126/cloudera/cdh/5.10.1/
enabled=1
gpgcheck=0

[CM-5.10.1]
name=CDH-5.10.1 - Source
baseurl=http://192.168.10.126/cloudera//cm/5.10.1
enabled=1
gpgcheck=0


[resource-ISO-6.8]
name=Red Hat Enterprise Linux $releasever - $basearch - Source
baseurl=file:///media/RHEL_6.5\ x86_64\ Disc\ 1
enabled=1
gpgcheck=0

-----SUSE
vi /etc/zypp/repos.d/SUSE-Linux-Enterprise-Server-11-SP3_11.3.3-1.138.repo      
[SUSE-Linux-Enterprise-Server-11-SP3_11.3.3-1.138]
name=SUSE-Linux-Enterprise-Server-11-SP3 11.3.3-1.138
enabled=1
autorefresh=0
baseurl=iso:///?iso=SLES-11-SP3-DVD-x86_64-GM-DVD1.iso&url=file:///root/software/
path=/
type=yast2
keeppackages=0    


for i in list_hostname: 
        locals()[i]=i 
    print locals()




5、安装

./runInstaller -ignoreSysPrereqs -force -responseFile   应答文件
./runInstaller -silent -force -responseFile /opt/database/response/db_install.rsp
$RACLE_HOME/root.sh



$ORACLE_HOME/bin/dbca -silent -createDatabase -templateName General_Purpose.dbc  -gdbName yong -sid yong -sysPassword oracle -systemPassword  oracle -storageType ASM -diskGroupName YONG_DG -datafileJarLocation $ORACLE_HOME/assistants/dbca/templates -nodeinfo rac1,rac2 -characterset AL32UTF8 -obfuscatedPasswords false -sampleSchema true  -asmSysPassword oracle





6、通过以安装了的软件来复制安装
tar -cvf  $ORACLE_HOME
or
tar -cvf - $ORACLE_HOME |ssh remote_host "cd $ORACLE_HOME/..  ; tar -xvf -"


grep -Ev "^$|^#" db_install.rsp 

附加oracle主目录
cd $ORACLE_HOME/oui/bin
./runInstaller -silent -attachHOME -invPtrLoc /etc/oraInst.loc  ORACLE_HOME="$ORACLE_HOME" ORACLE_HOME_NAME="ONEW"


./runInstaller -ignoreSysPrereqs

./runInstaller -silent -debug -force  \  
FROM_LOCATION=/soft/database/stage/products.xml  \  
oracle.install.option=INSTALL_DB_SWONLY \  
ORACLE_HOSTNAME=ocpyang.sz.com \  
UNIX_GROUP_NAME=oinstall \  
INVENTORY_LOCATION=/u01/app/oraInventory \  
SELECTED_LANGUAGES=en,zh_CN \  
ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1 \  
ORACLE_BASE=/u01/app/oracle \  
oracle.install.db.InstallEdition=EE \  
oracle.install.db.EEOptionsSelection=false \  
oracle.install.db.DBA_GROUP=dba \  
oracle.install.db.OPER_GROUP=oper \  
oracle.install.db.config.starterdb.type=GENERAL_PURPOSE \  
oracle.install.db.config.starterdb.memoryOption=false \  
oracle.install.db.config.starterdb.installExampleSchemas=false \  
oracle.install.db.config.starterdb.enableSecuritySettings=true \  
oracle.install.db.config.starterdb.control=DB_CONTROL \  
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false \  
DECLINE_SECURITY_UPDATES=true \  
oracle.installer.autoupdates.option=SKIP_UPDATES   

./runInstaller -silent -debug -force  \  
ORACLE_HOSTNAME=rac1
INVENTORY_LOCATION=/u01/app/oraInventory
SELECTED_LANGUAGES=en
oracle.install.option=CRS_CONFIG
ORACLE_BASE=/u01/app/grid
ORACLE_HOME=/u01/app/11.2.0/grid
oracle.install.asm.OSDBA=asmdba
oracle.install.asm.OSOPER=asmoper
oracle.install.asm.OSASM=asmadmin
oracle.install.crs.config.gpnp.scanName=scan.luocs.com
oracle.install.crs.config.gpnp.scanPort=1521
oracle.install.crs.config.clusterName=rac-cluster
oracle.install.crs.config.gpnp.configureGNS=false
oracle.install.crs.config.gpnp.gnsSubDomain=
oracle.install.crs.config.gpnp.gnsVIPAddress=
oracle.install.crs.config.autoConfigureClusterNodeVIP=false
oracle.install.crs.config.clusterNodes=rac1:rac1-vip,rac2:rac2-vip
oracle.install.crs.config.networkInterfaceList=eth0:192.168.53.0:1,eth1:10.0.3.0:2
oracle.install.crs.config.storageOption=ASM_STORAGE
oracle.install.crs.config.sharedFileSystemStorage.diskDriveMapping=
oracle.install.crs.config.sharedFileSystemStorage.votingDiskLocations=
oracle.install.crs.config.sharedFileSystemStorage.votingDiskRedundancy=
oracle.install.crs.config.sharedFileSystemStorage.ocrLocations=
oracle.install.crs.config.sharedFileSystemStorage.ocrRedundancy=
oracle.install.crs.config.useIPMI=false
oracle.install.crs.config.ipmi.bmcUsername=
oracle.install.crs.config.ipmi.bmcPassword=
oracle.install.asm.SYSASMPassword=oracle
oracle.install.asm.diskGroup.name=CRS
oracle.install.asm.diskGroup.redundancy=EXTERNAL
oracle.install.asm.diskGroup.AUSize=4
oracle.install.asm.diskGroup.disks=/dev/oracleasm/disks/CRS1
oracle.install.asm.diskGroup.diskDiscoveryString=/dev/oracleasm/disks/*            */
oracle.install.asm.monitorPassword=oracle
oracle.install.crs.upgrade.clusterNodes=
oracle.install.asm.upgradeASM=false
oracle.installer.autoupdates.option=SKIP_UPDATES

sh runInstaller -silent -debug -force  FROM_LOCATION=/home/oracle/soft/database/stage/products.xml  oracle.install.option=INSTALL_DB_SWONLY \
ORACLE_HOSTNAME=yong UNIX_GROUP_NAME=oinstall INVENTORY_LOCATION=/opt/oracle/oraInventory SELECTED_LANGUAGES=en,zh_CN ORACLE_HOME=$ORACLE_HOME ORACLE_BASE=$ORACLE_BASE oracle.install.db.InstallEdition=EE oracle.install.db.EEOptionsSelection=false oracle.install.db.DBA_GROUP=dba oracle.install.db.OPER_GROUP=oper oracle.install.db.config.starterdb.type=GENERAL_PURPOSE oracle.install.db.config.starterdb.memoryOption=false oracle.install.db.config.starterdb.installExampleSchemas=false oracle.install.db.config.starterdb.enableSecuritySettings=true oracle.install.db.config.starterdb.control=DB_CONTROL SECURITY_UPDATES_VIA_MYORACLESUPPORT=false DECLINE_SECURITY_UPDATES=true oracle.installer.autoupdates.option=SKIP_UPDATES  




As a root user, execute the following script(s):
        1. /opt/oracle/oraInventory/orainstRoot.sh
        2. /opt/oracle/oracle/product/12.1.0.2/db_1/root.sh

subprocess.Popen("dir", shell=True, stdout=subprocess.PIPE


unzip -o /home/oracle/soft/p6880880_112000_Linux-x86-64.zip -d $ORACLE_HOME

/opt/oracle/oracle/product/12.1.0.2/db_1/OPatch/ocm/bin/ocm.rsp



  

7、安装失败重新安装

oraInventory/ContentsXML/inventory.xml



8、补丁
$ORACLE_HOME/OPatch/opatch  napply -skip_subset  -skip_duplicate


###############################安装问题汇总
1、RHEL 7.2 存在ASM配置问题需要
The second observed error occurs during installation and upgrade when asmca fails with the following error:
KFOD-00313: No ASM instances available. CSS group services were successfully initilized by kgxgncin
KFOD-00105: Could not open pfile 'init@.ora'
Doc ID 2081410.1

WORKAROUND：
1) Set RemoveIPC=no in /etc/systemd/logind.conf
2) Reboot the server or restart systemd-logind as follows:
     # systemctl daemon-reload
     # systemctl restart systemd-logind

2、在OEL 6.3上搭建一台11G的RAC测试环境，在最后执行root.sh脚本的时候遇到libcap.so.1: cannot open shared object file: No such file or directory 错误。
安装：rpm -ivh compat-libcap1-1.10-1.x86_64.rpm
删除以前的CRS配置: perl $GRID_HOME/crs/install/rootcrs.pl -verbose -deconfig -force
重新配置：/oracle/grid/11.2.0/grid/root.sh

3、INS-32026 INSTALL_COMMON_HINT_DATABASE_LOCATION_ERROR
mount -t tmpfs shmfs -o size=4g /dev/shm
vi /etc/fstab
shmfs /dev/shm tmpfs size=4g 0


4、重新配置或迁移MGMTDB资料库 (Doc ID 1589394.1)
    4.1、停止并禁用ora.crf
        <GI_HOME>/bin/crsctl stop res ora.crf -init
        <GI_HOME>/bin/crsctl modify res ora.crf -attr ENABLED=0 -init
    4.2、删除现有资料库
        <GI_HOME>/bin/srvctl status mgmtdb
        <GI_HOME>/bin/dbca -silent -deleteDatabase -sourceDB -MGMTDB
    4.3、重建资料库
        for 12.1.0.1 ASM：<GI_HOME>/bin/dbca -silent -createDatabase -templateName MGMTSeed_Database.dbc -sid -MGMTDB -gdbName _mgmtdb -storageType ASM -diskGroupName <+NEW_DG> -datafileJarLocation <GI_HOME>/assistants/dbca/templates -characterset AL32UTF8 -autoGeneratePasswords -oui_internal
        for 12.1.0.1 FS：<GI_HOME>/bin/dbca -silent -createDatabase -templateName MGMTSeed_Database.dbc -sid -MGMTDB -gdbName _mgmtdb -storageType FS -datafileDestination <NFS_Location> -datafileJarLocation <GI_HOME>/assistants/dbca/templates -characterset AL32UTF8 -autoGeneratePasswords -oui_internal
        For 12.1.0.2 ASM：<GI_HOME>/bin/dbca -silent -createDatabase -sid -MGMTDB -createAsContainerDatabase true -templateName MGMTSeed_Database.dbc -gdbName _mgmtdb -storageType ASM -diskGroupName <+NEW_DG> -datafileJarLocation $GI_HOME/assistants/dbca/templates -characterset AL32UTF8 -autoGeneratePasswords -skipUserTemplateCheck
        For 12.1.0.2 FS：<GI_HOME>/bin/dbca -silent -createDatabase -sid -MGMTDB -createAsContainerDatabase true -templateName MGMTSeed_Database.dbc -gdbName _mgmtdb -storageType FS -datafileDestination <NFS_Location> -datafileJarLocation $GI_HOME/assistants/dbca/templates -characterset AL32UTF8 -autoGeneratePasswords -skipUserTemplateCheck
        For PDB：<GI_HOME>/bin/dbca -silent -createPluggableDatabase -sourceDB -MGMTDB -pdbName <CLUSTER_NAME> -createPDBFrom RMANBACKUP -PDBBackUpfile <GI_HOME>/assistants/dbca/templates/mgmtseed_pdb.dfb -PDBMetadataFile <GI_HOME>/assistants/dbca/templates/mgmtseed_pdb.xml -createAsClone true 
    4.4、查看状态
        <GI_HOME>/bin/srvctl status MGMTDB
        <GI_HOME>/bin/mgmtca
    4.5、开启ora.crf
        <GI_HOME>/bin/crsctl modify res ora.crf -attr ENABLED=1 -init
        <GI_HOME>/bin/crsctl start res ora.crf -init  
 
5、数据库响应与IO性能不匹配，建议数据库做IO校验，脚本如下，做完后重启数据库，11g
select * from v$io_calibration_status;


1)、权限，必须具有sysdba执行该过程的权限，另外需要打开timed_statistics。
2)、确定异步i/o在数据库的所有数据文件和临时文件都已经得到应用启动，我们可以通过v$datafile 和v$iostat_file视图关联进行、确认。
                                                    col name format a50
 select name,asynch_io from v$datafile f,v$iostat_file i
 where f.file#=i.file_no
 and (filetype_name='Data File' or filetype_name='Temp File');
 如果异步i/o没有启动，设置disk_asynch_io=true启动该功能，但默认是开启的。
3)、确保服务器只有需要测试的数据库开启，避免其他应用软件的影响。
4)、对于RAC，需要确保所有的实例都开启，因为 将会对所有节点做全面的校对，执行该过程只需在一个实例即可。
5)、确保只有一个用户执行一个校对i/o的操作。可以通过v$io_calibration_status查看当前鉴定状态。
　清除IO校准只需要删除表resource_io_calibrate$的数据，参考文档：
How To Delete Calibrate I/O In The Instance (Doc ID 1393405.1)






 set timing on serveroutput on
  declare
    v_max_iops BINARY_INTEGER;
    v_max_mbps BINARY_INTEGER;
    v_act_lat BINARY_INTEGER;
  begin
    -- DBMS_RESOURCE_MANAGER.CALIBRATE_IO (disk_count,max_latency , iops, mbps, lat);
    dbms_resource_manager.CALIBRATE_IO(5,5,v_max_iops,v_max_mbps,v_act_lat);
    dbms_output.put_line('max iops : ' || v_max_iops );
    dbms_output.put_line('max mbps : ' || v_max_mbps );
    dbms_output.put_line('actual latency : ' || v_act_lat );
  end;
  /

 set timing on serveroutput on
  declare
    v_max_iops BINARY_INTEGER;
    v_max_mbps BINARY_INTEGER;
    v_act_lat BINARY_INTEGER;
  begin
    dbms_resource_manager.CALIBRATE_IO(5,5,v_max_iops,v_max_mbps,v_act_lat);
    dbms_output.put_line('max iops : ' || v_max_iops );
    dbms_output.put_line('max mbps : ' || v_max_mbps );
    dbms_output.put_line('actual latency : ' || v_act_lat );
  end;
  /

SET SERVEROUTPUT ON
DECLARE
    lat INTEGER;
    iops INTEGER;
    mbps INTEGER;
BEGIN
DBMS_RESOURCE_MANAGER.CALIBRATE_IO (3,10, iops, mbps, lat);
DBMS_OUTPUT.PUT_LINE ('max_iops = ' || iops);
DBMS_OUTPUT.PUT_LINE ('latency = ' || lat);
dbms_output.put_line('max_mbps = ' || mbps);
end;
/


6、11.2.0.2 之后版本Pmon终止ASM或数据库实例
    多为节点间HAIP不通
    ifconfig bond1:1 169.254.96.100 netmask 255.255.0.0 up
    ifconfig bond1:1 169.254.96.101 netmask 255.255.0.0 up
    ifconfig bond1:1 169.254.96.102 netmask 255.255.0.0 up

    ifconfig bond1:1 169.254.96.100 netmask 255.255.0.0 down
    ifconfig bond1:1 169.254.96.101 netmask 255.255.0.0 down
    ifconfig bond1:1 169.254.96.102 netmask 255.255.0.0 down       
        
oclumon manage -get master  ----查看主节点        
        
        
        
7、添加节点
./sshUserSetup.sh -user oracle  -hosts "zjhz-nmxx010 zjhz-nmxx011 zjhz-nmxx012 zjhz-nmxx013"   -advanced -noPromptPassphrase  
./sshUserSetup.sh -user grid  -hosts "zjhz-nmxx010-prv zjhz-nmxx011-prv zjhz-nmxx012-prv zjhz-nmxx013-prv"   -advanced -noPromptPassphrase       
./addNode.sh -silent "CLUSTER_NEW_NODES={zjhz-nmxx011}" "CLUSTER_NEW_PRIVATE_NODE_NAMES={zjhz-nmxx011-prv}" "CLUSTER_NEW_VIRTUAL_HOSTNAMES={zjhz-nmxx011-vip}"        
 
       

8、手动配置信任
./sshUserSetup.sh -user oracle  -hosts "ora11g-srv01 ora11g-srv02"  -advanced -noPromptPassphrase              

Oracle@2o16

ssh zjhz-wxzhfx01 date
ssh zjhz-wxzhfx01-priv date

ssh zjhz-wxzhfx02 date
ssh zjhz-wxzhfx02-priv date

9、执行安装前检查
全面检查:
./runcluvfy.sh  stage -pre crsinst -n "broker01,broker02,broker03,broker04"  -verbose
./runcluvfy.sh  stage -pre dbinst -n "zjhz-xs-zhzgrz-db01,zjhz-xs-zhzgrz-db02"  -verbose


/opt/oracle/soft/grid/runcluvfy.sh  stage -post crsinst -n "zjhz-nmxx010,zjhz-nmxx011,zjhz-nmxx012,zjhz-nmxx013"  -verbose
/opt/oracle/soft/grid/runcluvfy.sh  stage -post dbinst -n "zjhz-nmxx010,zjhz-nmxx011,zjhz-nmxx012,zjhz-nmxx013"  -verbose

10、linux OS最佳实践
    a、配置ntpd
    b、关闭Transparent HugePages
        RHEL6： /etc/grub.conf 添加 transparent_hugepage=never 重启主机
            or vi  /etc/rc.local
                if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
                   echo never > /sys/kernel/mm/transparent_hugepage/enabled
                fi
                if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
                   echo never > /sys/kernel/mm/transparent_hugepage/defrag
                fi

        RHEL7：参照2066217.1
    c、关闭ASLR (Address Space Layout Randomization)
    d、设置 vm.min_free_kbytes 内核参数保留 512MB，以允许 OS 更快地回收内存，这样可以避免内存低的压力。
    e、禁用 AVAHI 等第三方MDNS守护进程以确保cssd能够正常启动
        net.core.rmem_default=262144
        net.core.rmem_max=4194304 (for 11g and all RDS implementations)
        net.core.rmem_max=2097152 (for 10g)
        net.core.wmem_default=262144
        net.core.wmem_max=1048576 (with RDS use at least 2097152)
    f、对于 10gR2 和 11gR1 安装，验证 oradism 可执行文件是否与所有权和权限 "-rwsr-sr-x 1 root dba oradism" 匹配，并确保 lms 正在实时模式下运行。








--------------RAC auto补丁操作
unzip  p6880880*  -d $ORACLE_HOME
-----grid
/opt/oracle/11.2.0.4/grid/OPatch/opatch auto /opt/oracle/soft/gipsu/23274134 \
-oh /opt/oracle/11.2.0.4/grid  -ocmrf /opt/oracle/11.2.0.4/grid/OPatch/ocm/bin/ocm.rsp

----oracle
/opt/oracle/oracle/product/11.2.0.4/db_1/OPatch/opatch auto /opt/oracle/soft/gipsu/23274134 \
-oh /opt/oracle/oracle/product/11.2.0.4/db_1 -ocmrf /opt/oracle/11.2.0.4/grid/OPatch/ocm/bin/ocm.rsp


$ORACLE_HOME/OPatch/opatch lsinv|grep "Patch description:"






#############################################NTPD服务检查
-------RHEL  linux
# service ntpd status           -----ntpd当前状态
# chkconfig ntpd  --list      -----查看ntpd开机状态
#cat /etc/ntp.conf              -----查看ntpd配置文件，配置文件中配置了统一时间服务器ip
server 10.70.91.148
server 10.70.91.149
#cat /etc/sysconfig/ntpd   -----查看ntpd参数文件，参数文件的OPTIONS选项必须包含‘-x’选项
OPTIONS="-x -u ntp:ntp -p /var/run/ntpd.pid" 
# Set to 'yes' to sync hw clock after successful ntpdate 
SYNC_HWCLOCK=yes
# Additional options for ntpdate
NTPDATE_OPTIONS=""



---suse
# /sbin/service ntp start
# /sbin/service ntp stop
# /sbin/service ntp restart        
# /sbin/service ntp status

/etc/sysconfig/ntpd
OPTIONS="-x -u ntp:ntp -p /var/run/ntpd.pid -g"



------HP-UX
zjddcs20:/#vi /etc/ntp.conf
server 10.70.213.132 version 3 prefer
server 10.70.213.133 version 3
server 10.70.10.75 version 3
driftfile /etc/ntp.drift
zjddcs20:/#cd /etc/rc.config.d/
zjddcs19:/etc/rc.config.d# cp netdaemons netdaemons.old
zjddcs19:/etc/rc.config.d# chmod +w netdaemons

zjddcs19:/etc/rc.config.d# vi /etc/rc.config.d/netdaemons	
export NTPDATE_SERVER=
export XNTPD=1
export XNTPD_ARGS="-x"

AIX平台：
cat /etc/rc.tcpip ，显示结果如下为正常：
start /usr/sbin/xntpd "$src_running" "-x"

##########################################################################











-------------------------------------------------------裸设备映射
------Linux 6
vi  /etc/udev/rules.d/99-oracle-asmdevices.rules
KERNEL=="sdb1", NAME+="/asmdisks/ocrdisk01", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sdb2", NAME+="/asmdisks/ocrdisk02", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sdb3", NAME+="/asmdisks/ocrdisk03", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sdb5", NAME+="/asmdisks/asmdisk01", OWNER="grid", GROUP="asmadmin", MODE="0660"

chown grid:asmadmin /dev/sdb1
chown grid:asmadmin /dev/sdb2
chown grid:asmadmin /dev/sdb3
chown grid:asmadmin /dev/sdb5
chmod 660 /dev/sdb1
chmod 660 /dev/sdb2
chmod 660 /dev/sdb3
chmod 660 /dev/sdb5

--------suse 11
vi  /etc/raw
raw1:sdb1
raw2:sdb2
raw3:sdb3

----50-udev-default.rules中的
KERNEL=="raw[0-9]*", SUBSYSTEM=="raw", NAME="raw/%k", GROUP="disk" 注释掉


vi /etc/udev/rules.d/99-udev-raw.rules
KERNEL=="raw[1-2]", SUBSYSTEM=="raw", NAME="raw/%k",OWNER="oracle", GROUP="oinstall",MODE="660"

---------
##重启udev的服务
/etc/init.d/boot.udev stop
/etc/init.d/boot.udev start
##启动裸设备
rcraw start
chkconfig raw on
raw -qa


-----------------------------------scsi_id

------------------获得id
vi  /etc/scsi_id.config
options=-g


----Oracle Linux 5
/sbin/scsi_id -g -u -s /block/sdb

-----Oracle Linux 6
/sbin/scsi_id -g -u -d /dev/sdb

---Oracle Linux 7
/usr/lib/udev/scsi_id -g -u -d /dev/sdb



disk.EnableUUID="TRUE"
disk.locking = "FALSE"
scsi1.shared = "TRUE"
diskLib.dataCacheMaxSize = "0"
diskLib.dataCacheMaxReadAheadSize = "0"
diskLib.dataCacheMinReadAheadSize = "0"
diskLib.dataCachePageSize= "4096"
diskLib.maxUnsyncedWrites = "0"
 
scsi1.present = "TRUE"
scsi1.virtualDev = "lsilogic"
scsil.sharedBus = "VIRTUAL"
scsi1:0.present = "TRUE"
scsi1:0.mode = "independent-persistent"
scsi1:0.fileName = "E:\share\ocr_vote.vmdk"
scsi1:0.deviceType = "disk"
scsi1:0.redo = ""






------------------规则
vi /etc/udev/rules.d/99-oracle-asmdevices.rules

---Oracle Linux 5
for i in b c d e f ;
do
echo "KERNEL==\"sd*\", BUS==\"scsi\", PROGRAM==\"/sbin/scsi_id --whitelisted --replace-whitespace --device=/dev/\$name\", RESULT==\"`/sbin/scsi_id -g -u -s /dev/sd$i`\", NAME=\"asm-disk$i\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\"" >> /etc/udev/rules.d/99-oracle-asmdevices.rules
done

--###分区盘
KERNEL=="sd?1", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -s /block/$parent", RESULT=="36000c29d0c3f51aa397e2da6c8a9dc1d", NAME="/oradisks/asmdisk1", OWNER="grid", GROUP="asmadmin", MODE="0660"


-----Oracle Linux 6
--###裸盘
for i in b c d e ;
do
echo "KERNEL==\"sd*\", BUS==\"scsi\", PROGRAM==\"/sbin/scsi_id --whitelisted --replace-whitespace --device=/dev/\$name\", RESULT==\"`/sbin/scsi_id  --whitelisted --replace-whitespace --device=/dev/sd$i`\", NAME=\"oracleasm/asm-disk$i\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\""   >>  /etc/udev/rules.d/99-oracle-asmdevices.rules  
done

for i in c d e f g h i j k l m n o p q r s t ; 
do
echo "/dev/sd$i      `/sbin/scsi_id -g -u -d /dev/sd$i`"
done

for i in c d e f g h i j k l m n o p q r s t ; 
do
echo "KERNEL==\"sd?1\", BUS==\"scsi\", PROGRAM==\"/sbin/scsi_id -g -u -d /dev/\$parent\", RESULT==\"`/sbin/scsi_id -g -u -d /dev/sd$i`\", NAME=\"oracleasm/asmdisk$i\", OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"0660\""
done


KERNEL=="sd*", BUS=="scsi", PROGRAM=="/sbin/scsi_id --whitelisted --replace-whitespace --device=/dev/$name", RESULT=="1ATA_VBOX_HARDDISK_VB7e8db8b6-707bf584", SYMLINK+="asmdisk/asm-diskc", OWNER="grid", GROUP="asmadmin", MODE="0660"

KERNEL=="sd?1", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdisk1",  OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?2", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdisk2",  OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?3", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdisk3",  OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?5", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdisk5",  OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?6", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdisk6",  OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?7", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdisk7",  OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?8", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdisk8",  OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?9", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdisk9",  OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?10", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis10", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?11", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis11", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?12", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis12", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?13", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis13", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?14", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis14", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?15", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis15", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?16", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis16", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?17", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis17", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?18", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis18", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?19", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis19", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?20", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis20", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?21", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis21", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?22", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis22", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?23", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis23", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?24", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis24", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?25", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis25", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?26", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis26", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?27", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis27", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?28", BUS=="scsi", PROGRAM=="/sbin/scsi_id -g -u -d /dev/$parent", RESULT=="1ATA_VBOX_HARDDISK_VBabd51b88-89be7e1a", SYMLINK+="asmdisk/asmdis28", OWNER="grid", GROUP="asmadmin", MODE="0660"

-----Oracle Linux 7
KERNEL=="sd?1", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$parent", RESULT=="36000c299db2824d8c65006e7584965ea", SYMLINK+="oradisks/datadisk01", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?2", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$parent", RESULT=="36000c297a31c91e4ea9543b3464a02e4", SYMLINK+="oradisks/datadisk02", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?3", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$parent", RESULT=="36000c297a31c91e4ea9543b3464a02e4", SYMLINK+="oradisks/datadisk03", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sd?5", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d /dev/$parent", RESULT=="36000c297a31c91e4ea9543b3464a02e4", SYMLINK+="oradisks/datadisk04", OWNER="grid", GROUP="asmadmin", MODE="0660"

------更新分区表
# /sbin/partprobe /dev/sdb1

----测试映射关系
# #OL5
# udevtest /block/sdb/sdb1
# #OL6 and OL7
# udevadm test /block/sdb/sdb1

----重启udev
# #OL5
# /sbin/udevcontrol reload_rules
# #OL6 and OL7
# udevadm control --reload-rules
# #OL5 and OL6 : Not needed for OL7
# /sbin/start_udev

ls -al /dev/oradisks

--------------udev rules in OL7 related to ASM on multipath disks
Step 1: Determine the UUID of the multipath disk meant for Oracle ASM use.

# udevadm info --query=all --name=/dev/mapper/mpathn1 | grep -i DM_UUID

Note: In the above command is /dev/mapper/mpathn1 is just an example multipath disk, in you case it may be different.

Step 2: Create a udev rule file /etc/udev/rules.d/96-asmmultipath.rules
# touch /etc/udev/rules.d/96-asmmultipath.rules

Step 3: Add below udev rule for a multipath device using it's DM_UUID value under the file /etc/udev/rules.d/96-asmmultipath.rules
ACTION=="add|change", ENV{DM_UUID}=="mpath-<DM_UUID>", SYMLINK+="udev-asmdisk1", GROUP="oinstall", OWNER="grid", MODE="0660"

Note: Replace <DM_UUID> with the one you got it from the step 1 command output.

# vi /etc/udev/rules.d/96-asmmultipath.rules
Add above udev rule
Now save & exit

Step 4: To add or load Udev rules using the below commands.
# /sbin/udevadm control --reload-rules
# /sbin/udevadm trigger --type=devices --action=change


Step 5: Check file permissions on the disk paths.
# ls -l /dev/udev-asmdisk1
# ls -l /dev/mapper/mpathn
# ls -l /dev/dm-x

Note: Here dm-x can be anything like dm-0 or dm-1 or dm-2, so it's based upon your environment 

Step 6: Login as a grid user and check disk information using the sg_inq command. You should be able to see disk information using the below sg_inq commands.
# su - grid
$ sg_inq /dev/mapper/mpathn
$ sg_inq /dev/dm-x

Step 7: Now you can proceed further with the RAC setup.


------------------------------------------Solaris安装

-------------------查看当前swap大小
zfs list 
----扩展swap
zfs set volsize=5G rpool/swap  

--------关闭和启动图形界面也有所变化
--关闭图形界面
svcadm disable svc:/application/graphical-login/gdm:default
--启动图形界面
svcadm enable  svc:/application/graphical-login/gdm:default

------------网络查看与配置
--使用 netadm 查看系统上哪些网络配置文件是活动的
netadm list

--手动网络配置
ipadm create-ip net0
ipadm create-addr -T static -a 172.11.10.60/24 net1/acme
ipadm show-if
ipadm show-addr

--可以添加持久性默认路由
route -p add default 10.163.198.1

--设置主机名
svccfg -s svc:/system/identity:node setprop config/nodename = astring: hostname
svcadm refresh svc:/system/identity:node
svcadm restart identity:node
cat /etc/hosts

--配置DNS
root@vzwc1:~# svccfg  
svc:> select name-service/switch  
svc:/system/name-service/switch> setprop config/host = astring: "files dns"  
svc:/system/name-service/switch> setprop config/ipnodes = astring:  "files dns"  
svc:/system/name-service/switch> select name-service/switch:default  
svc:/system/name-service/switch:default> refresh  
svc:/system/name-service/switch:default> validate  
svc:/system/name-service/switch:default> exit  

oracle@vzwc1:~/.ssh$ ifconfig -a                                                                                                                                                                                                      
lo0: flags=2001000849<UP,LOOPBACK,RUNNING,MULTICAST,IPv4,VIRTUAL> mtu 8232 index 1  
        inet 127.0.0.1 netmask ff000000   
net0: flags=1000843<UP,BROADCAST,RUNNING,MULTICAST,IPv4> mtu 1500 index 2  
        inet 192.168.1.61 netmask ffffff00 broadcast 192.168.1.255  
net1: flags=1000843<UP,BROADCAST,RUNNING,MULTICAST,IPv4> mtu 1500 index 3  
        inet 172.168.1.61 netmask ffffff00 broadcast 172.168.1.255  
lo0: flags=2002000849<UP,LOOPBACK,RUNNING,MULTICAST,IPv6,VIRTUAL> mtu 8252 index 1  
        inet6 ::1/128   
net0: flags=20002000840<RUNNING,MULTICAST,IPv6> mtu 1500 index 2  
        inet6 ::/0   
net1: flags=20002000840<RUNNING,MULTICAST,IPv6> mtu 1500 index 3  
        inet6 ::/0   
oracle@vzwc1:~/.ssh$                                                                                                                                                                                                                  
oracle@vzwc1:~/.ssh$                                                                                                                                                                                                                  
oracle@vzwc1:~/.ssh$ ping -s www.baidu.com                                                                                                                                                                                            
PING www.baidu.com: 56 data bytes  
64 bytes from 115.239.210.26: icmp_seq=0. time=11.186 ms  
64 bytes from 115.239.210.26: icmp_seq=1. time=11.315 ms  
64 bytes from 115.239.210.26: icmp_seq=2. time=10.247 ms  
^C  
----www.baidu.com PING Statistics----  
3 packets transmitted, 3 packets received, 0% packet loss  
round-trip (ms)  min/avg/max/stddev = 10.247/10.916/11.315/0.583  





------------存储及内存检查
# /usr/sbin/prtconf | grep "Memory size"
# /usr/sbin/swap -s
# df -h 

挂载镜像
# mount -F hsfs -o ro `lofiadm -a /home/oracle/sol-11-exp-201011-repo-full.iso` /mnt
设置镜像为本地repository
# pkg set-publisher -Pe -O file:///mnt/repo/ solaris
或者使用在线repository
# pkg set-publisher -Pe -O http://pkg.oracle.com/solaris/release solaris
进行软件包检查
pkginfo -i SUNWarc SUNWbtool SUNWhea SUNWlibm SUNWlibms SUNWpool SUNWpoolr SUNWsprot SUNWtoo SUNWuiu8 SUNWfont-xorg-core SUNWfont-xorg-iso8859-1 SUNWmfrun SUNWxorg-client-programs SUNWxorg-clientlibs SUNWxwfsw SUNWxwplt
-----------------软件包检查和安装
pkginfo -i  SUNWarc SUNWbtool SUNWhea SUNWlibC SUNWlibm SUNWlibms SUNWsprot SUNWtoo SUNWi1of SUNWi1cs SUNWi15cs SUNWxwfnt SUNWcsl  
----安装包，/path为光盘挂载的路径
pkgadd -d /path SUNWarc SUNWbtool SUNWhea SUNWlibC SUNWlibm SUNWlibms SUNWsprot SUNWtoo SUNWi1of SUNWi1cs SUNWi15cs SUNWxwfnt SUNWcsl 
pkg install compatibility/packages/SUNWxwplt SUNWmfrun SUNWarc SUNWhea SUNWlibm
---下面检查一下补丁的情况，需要最小安装下列的补丁：119963-14、120753-06、139574-03、141414-02、141444-09：
 patchadd -p |grep 119963
 patchadd -p |grep 120753
 patchadd -p |grep 139574
 patchadd -p |grep 141414


----------------etc/hosts
vi /etc/hosts
#Public
10.211.106.196  imep5 
10.211.106.197  imep6

#VIP
10.211.106.217  imep5vip
10.211.106.218  imep6vip

#Private
192.167.10.10   imep5priv
192.167.10.11   imep6priv

192.168.11.15 ora12c


----------------------修改系统的参数
vi /etc/system

set noexec_user_stack=1 
set semsys:seminfo_semmni=100 
set semsys:seminfo_semmns=1024 
set semsys:seminfo_semmsl=256 
set semsys:seminfo_semvmx=32767 
##--实际值需大于SGA的值 set shmsys:shminfo_shmmni=100 
set shmsys:shminfo_shmmax=62949672950   
set shmsys:shminfo_shmmni=100


--- UDP and TCP
--查看
/usr/sbin/ndd /dev/tcp tcp_smallest_anon_port tcp_largest_anon_port
--设置
/usr/sbin/ndd -set /dev/tcp tcp_smallest_anon_port 9000
/usr/sbin/ndd -set /dev/tcp tcp_largest_anon_port 65500
/usr/sbin/ndd -set /dev/udp udp_smallest_anon_port 9000
/usr/sbin/ndd -set /dev/udp udp_largest_anon_port 65500


-----shell 限制
STACK	Size of the stack segment of the process	at most 10240	at most 32768
NOFILES	Open file descriptors	at least 1024	at least 65536
MAXUPRC or MAXPROC	Maximum user processes	at least 2047	at least 16384

Shell Limit Recommended Value 查看方式
TIME -1 (Unlimited) ulimit –t 默认 unlimited
FILE -1 (Unlimited) ulimit –f 默认 unlimited
DATA Minimum value: 1048576 ulimit –d 默认 unlimited
STACK Minimum value: 32768 ulimit –s 默认 8192
NOFILES Minimum value: 4096 ulimit –n 默认 256
VMEMORY Minimum value: 4194304 ulimit –v 默认 unlimited


vi /etc/.login and vi /etc/profile
ulimit -s 32768
ulimit -n 4096






--------------创建组及用户
/usr/sbin/groupadd -g 5001 oinstall
/usr/sbin/groupadd -g 5002 dba
/usr/sbin/groupadd -g 5003 oper
/usr/sbin/groupadd -g 5004 asmadmin
/usr/sbin/groupadd -g 5005 asmdba
/usr/sbin/groupadd -g 5006 asmoper
useradd -g oinstall -G dba,asmdba,asmadmin -m -d /export/home/oracle -s /usr/bin/bash oracle
useradd -g oinstall -G asmadmin,asmdba,asmoper,dba,oper  -m -d /export/home/grid -s /usr/bin/bash grid



检查、创建 project，修改相应参数
projadd -U oracle -K "project.max-shm-memory=(priv,64g,deny)" user.oracle
projmod -sK "project.max-sem-nsems=(priv,512,deny)" user.oracle
projmod -sK "project.max-sem-ids=(priv,256,deny)" user.oracle
projmod -sK "project.max-shm-ids=(priv,128,deny)" user.oracle

projadd -U grid -K "project.max-shm-memory=(priv,5g,deny)" user.grid
projmod -sK "project.max-sem-nsems=(priv,512,deny)"  user.grid
projmod -sK "project.max-sem-ids=(priv,128,deny)"  user.grid
projmod -sK "project.max-shm-ids=(priv,128,deny)"  user.grid


验证修改
root@dyyydb1 # su - oracle
$ id -p
uid=1200(oracle) gid=1000(oinstall) projid=101(user.oracle)
$ exit
root@dyyydb1 #
$ prctl -n project.max-shm-memory -i process $$
或
# su - oracle
$ prctl -i project user.oracle

------------------网络参数
# ipadm set-prop -p smallest_anon_port=9000 tcp
# ipadm set-prop -p largest_anon_port=65500 tcp
# ipadm set-prop -p smallest_anon_port=9000 udp
# ipadm set-prop -p largest_anon_port=65500 udp

以root用户编辑 /etc/ssh/sshd_config 并修改 LoginGraceTime 值为 0
LoginGraceTime 0
载入配置
# svcadm restart ssh


-------------------------------环境变量
Oracle 用户：
umask 022
ORACLE_BASE=/export/home/oracle
export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
export ORACLE_HOME
PATH=$ORACLE_HOME/bin:/usr/bin:/etc:/usr/sbin:/usr/ucb:/usr/bin/X11:/sbin:$PATH
export PATH
ORACLE_SID=smapora
export ORACLE_SID
LD_LIBRARY_PATH=$ORACLE_HOME/lib32:$ORACLE_HOME/lib:/usr/lib
export LD_LIBRARY_PATH
LIBPATH=$ORACLE_HOME/lib:$ORACLE_HOME/lib32:$ORACLE_HOME/ctx/lib
export LIBPATH
NLS_LANG="American_America.ZHS16GBK"
export NLS_LANG    


ORACLE_SID=hisd1; export ORACLE_SID
ORACLE_UNQNAME=hisd; export ORACLE_UNQNAME
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1; export ORACLE_HOME
JAVA_HOME=$ORACLE_HOME/jdk; export JAVA_HOME
ORACLE_PATH=/u01/app/common/oracle/sql; export ORACLE_PATH
ORACLE_TERM=xterm; export ORACLE_TERM
NLS_DATE_FORMAT="DD-MON-YYYY HH24:MI:SS"; export NLS_DATE_FORMAT
TNS_ADMIN=$ORACLE_HOME/network/admin; export TNS_ADMIN
ORA_NLS11=$ORACLE_HOME/nls/data; export ORA_NLS11
PATH=.:${JAVA_HOME}/bin:${PATH}:$HOME/bin:$ORACLE_HOME/bin
PATH=${PATH}:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin
PATH=${PATH}:/u01/app/common/oracle/bin
export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/JRE
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/rdbms/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/network/jlib
export CLASSPATH
THREADS_FLAG=native; export THREADS_FLAG
TEMP=/tmp
export TEMP
TMPDIR=/tmp
export TMPDIR
TERM=vt100
export TERM
umask 022




umask 022
ORACLE_BASE=/opt/oracle
export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
export ORACLE_HOME
PATH=$ORACLE_HOME/bin:/usr/bin:/etc:/usr/sbin:/usr/ucb:/usr/bin/X11:/sbin:$PATH
export PATH
ORACLE_SID=yliu
export ORACLE_SID
LD_LIBRARY_PATH=$ORACLE_HOME/lib32:$ORACLE_HOME/lib:/usr/lib
export LD_LIBRARY_PATH
LIBPATH=$ORACLE_HOME/lib:$ORACLE_HOME/lib32:$ORACLE_HOME/ctx/lib
export LIBPATH
















---------grid
ORACLE_SID=+ASM1; export ORACLE_SID
ORACLE_BASE=/u01/app/grid; export ORACLE_BASE
ORACLE_HOME=/u01/app/11.2.0/grid; export ORACLE_HOME
JAVA_HOME=$ORACLE_HOME/jdk; export JAVA_HOME
ORACLE_PATH=/u01/app/oracle/common/oracle/sql; export ORACLE_PATH
ORACLE_TERM=xterm; export ORACLE_TERM
NLS_DATE_FORMAT="DD-MON-YYYY HH24:MI:SS"; export NLS_DATE_FORMAT
TNS_ADMIN=$ORACLE_HOME/network/admin; export TNS_ADMIN
ORA_NLS11=$ORACLE_HOME/nls/data; export ORA_NLS11
PATH=.:${JAVA_HOME}/bin:${PATH}:$HOME/bin:$ORACLE_HOME/bin
PATH=${PATH}:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin
PATH=${PATH}:/u01/app/common/oracle/bin
export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/JRE
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/rdbms/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/network/jlib
export CLASSPATH
THREADS_FLAG=native; export THREADS_FLAG
export TEMP=/tmp
export TMPDIR=/tmp
umask 022
ulimit -t unlimited
ulimit -f unlimited
ulimit -d unlimited
ulimit -s unlimited
ulimit -v unlimited



---------------其他
---禁用sendmail服务
#svcadm disable sendmail-client
----NTPD配置

-------开放root登录权限，修改/etc/default/login文件
vi /etc/default/login
PermitRootLogin yes
svcadm restart svc:/network/ssh:default


安装过程中的错误
1 [INS-13001] Environment does meet minimum requirements. Are you sure you want to continue?
    解决方法：下载oracle补丁10098816，并安装

2 Checking monitor: must be configured to display at least 256 colors >>> Could not execute auto check for display colors using command /usr/openwin/bin/xdpyinfo. Check if the DISPLAY variable is set. Failed <<<< Some requirement checks failed. You must fulfill these requirements before continuing with the installation,at which time they will be rechecked.
    解决方法：安装SUNWxwplt 软件包，并设置DISPLAY参数，并以root用户执行”xhost +“命令

3 Exception in thread “main” java.lang.UnsatisfiedLinkError:
… libmawt.so: ld.so.1: java: fatal: libXm.so.4: open failed: No such file or directory
   解决方法：安装SUNWmfrun软件包
 
4 在运行runinstall界面的预安装检查中提示内核参数"project.max-shm-memory"设置不当，即使运行runfixup.sh后依然报错
  解决方法：重启系统
