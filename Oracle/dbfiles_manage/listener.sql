#####查看监听状态
[oracle@rac01 ~]$ lsnrctl status lsnr_name
####启动监听
[oracle@rac01 ~]$ lsnrctl start lsnr_name
####关闭监听
[oracle@rac01 ~]$ lsnrctl stop lsnr_name

禁用本地验证(10g以上)：添加LOCAL_OS_AUTHENTICATION_LISTENER= OFF

设置密码：
LSNRCTL> show current_listener
LSNRCTL> set current_listener LISTENER
LSNRCTL> change_password
LSNRCTL> set password         
LSNRCTL> save_config
LSNRCTL> save_status
[oracle@rac01 ~]$cat /oracle/orabase/product/10.2/rdbms/network/admin/listener.ora
#----ADDED BY TNSLSNR 22-JAN-2013 16:36:56---
PASSWORDS_LISTENER = AFF46841FDDE6D3F
#--------------------------------------------


LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS_LIST =
        (ADDRESS = (PROTOCOL = TCP)(HOST = 10.0.0.108)(PORT =1521))
      )
      )
      )

SID_LIST_LISTENER =  
      (SID_LIST =  
        (SID_DESC =  
          (SID_NAME = PLSExtProc)  
          (ORACLE_HOME = /opt/oracle/11204/product/11.2.0.4/db_1)  
          (PROGRAM = extproc)  
        )  
       (SID_DESC =           
         (GLOBAL_DBNAME = bjpaasc)  
         (ORACLE_HOME = /opt/oracle/11204/product/11.2.0.4/db_1)
         (SID_NAME = bjpaasc)      
       )
  )


LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
      (ADDRESS = (PROTOCOL = TCP)(HOST = ZJHZ-BJIAGW-SMServer06)(PORT = 1521))
    )
  )



LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS_LIST =
         (ADDRESS = (PROTOCOL = TCP)(HOST = ZJHZ-BJIAGW-SMServer06)(PORT = 1521))
      )
      )
      )

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS_LIST =
        (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-db107)(PORT = 1521))
      )
      )
      )      
      
  
SID_LIST_LISTENER =  
      (SID_LIST =  
       (SID_DESC =             
         (GLOBAL_DBNAME = orcl)  
         (ORACLE_HOME = /home/oracle/oracle_11/app/product/11.2.0home_1)
         (SID_NAME = orcl)      
       )
  )



















TNS = 
  (DESCRIPTION_LIST =
     (LOAD_BALANCE = off)
     (FAILOVER = on)
        (DESCRIPTION =
           (ADDRESS_LIST =
              (LOAD_BALANCE=OFF)
              (FAILOVER=ON)
              (ADDRESS = (PROTOCOL = TCP)(HOST = 10.212.200.76)(PORT = 1521))
           )
           (CONNECT_DATA =
             (SERVICE_NAME = zc_bbmp)
             (INSTANCE_NAME = sqpaasa1)
             (FAILOVER_MODE=(TYPE=session)(METHOD=basic)(RETRIES=4)(DELAY=1))
           )
        )
        (DESCRIPTION =
           (ADDRESS_LIST =
              (LOAD_BALANCE=OFF)
              (FAILOVER=ON)
              (ADDRESS = (PROTOCOL = TCP)(HOST = 10.212.200.78)(PORT = 1521))
           )
           (CONNECT_DATA =
              (SERVICE_NAME = zc_bbmp)
              (INSTANCE_NAME = sqpaasa3)
              (FAILOVER_MODE=(TYPE=session)(METHOD=basic)(RETRIES=4)(DELAY=1))
           )
        )
  )



anix22=   #网络服务名 随便起
 (DESCRIPTION=           
     (ADDRESS_LIST=                                     
     (ADDRESS =(PROTOCOL=TCP)(HOST=DB)(PORT=1521))    （端口）
     (ADDRESS =(PROTOCOL=TCP)(HOST=DB)(PORT=1522))
      )
    (CONNECT_DATA=
        (SERVER=SHARED)     #监听模式默认独享DEDICATED
        (SERVICE_NAME =anix)  #数据库的服务名 通常是全局数据库名
        )
)

######客户端连接时间负载平衡
ERP =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (LOAD_BALANCE=ON)
      (ADDRESS=(PROTOCOL=TCP)(HOST=node1vip)(PORT=1521))
      (ADDRESS=(PROTOCOL=TCP)(HOST=node2vip)(PORT=1521))
    )
    (CONNECT_DATA=(SERVICE_NAME=ERP)))

######客户端连接时间故障转移
ERP =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (LOAD_BALANCE=ON)
      (FAILOVER=ON)
      (ADDRESS=(PROTOCOL=TCP)(HOST=node1vip)(PORT=1521))
      (ADDRESS=(PROTOCOL=TCP)(HOST=node2vip)(PORT=1521))
    )
(CONNECT_DATA=(SERVICE_NAME=ERP)))

####RAC服务器端连接时间负载平衡
设置参数*.REMOTE_LISTENER=RACDB_LISTENERS
RACDB_LISTENERS=
(DESCRIPTION=
(ADDRESS=(PROTOCOL=tcp)(HOST=node1vip)(PORT=1521))
(ADDRESS=(PROTOCOL=tcp)(HOST=node2vip)(PORT=1521)))

ERP = (DESCRIPTION=
      (ADDRESS_LIST=
(LOAD_BALANCE=ON)
(FAILOVER=ON)
          (ADDRESS=(PROTOCOL=TCP)(HOST=node1vip)(PORT=1521))
          (ADDRESS=(PROTOCOL=TCP)(HOST=node2vip)(PORT=1521))
)
      (CONNECT_DATA=(SERVICE_NAME=ERP)))


#####共享服务器模式配置

anix22=   #网络服务名 随便起
 (DESCRIPTION=           
     (ADDRESS_LIST=                                     
     (ADDRESS =(PROTOCOL=TCP)(HOST=DB)(PORT=1521))    （端口）
     (ADDRESS =(PROTOCOL=TCP)(HOST=DB)(PORT=1522))
      )
    (CONNECT_DATA=
        (SERVER=SHARED)     #监听模式默认独享DEDICATED
        (SERVICE_NAME =anix)  #数据库的服务名 通常是全局数据库名
        )
)

LISTENER2 =  
      (DESCRIPTION_LIST =  
        (DESCRIPTION =  
          (ADDRESS = (PROTOCOL = TCP)(HOST = 144.194.192.183)(PORT = 1526)(IP = FIRST)) ## 端口修改在这里体现  
          (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC0))  
        )  
      )

SID_LIST_LISTENER2 =  
      (SID_LIST =  
        (SID_DESC =  
          (SID_NAME = PLSExtProc)  
          (ORACLE_HOME = /oracle/app/oracle/product/10.2.0/db_1)  
          (PROGRAM = extproc)  
        )  
        (SID_DESC =   ## 静态注册在这里体现  
          (GLOBAL_DBNAME = anix)  
          (ORACLE_HOME = /oracle/app/oracle/product/10.2.0/db_1)  
          (SID_NAME = anix)  
        )  
      )   

alter system set shared_servers=1;
alter system set dispatchers='(ADDRESS=(PROTOCOL=tcp)(HOST=192.168.13.15))(DISPATCHERS=2)'; --修改调度进程数2同时不指定端口号自动寻找空闲端口
alter system set dispatchers='(ADDRESS=(PROTOCOL=tcp)(HOST=192.168.13.15)(PORT=1521))(DISPATCHERS=1)';-- 修改调度进程数为1 指定该调度进程走1521端口 
alter system set local_listener='anix22'; 修改本地监听
show parameter dispatcher
show parameter dispatchers
show parameter local_listener


-----监听加密操作
$ORACLE_HOME/network/admin/listener.ora果有，责修改如下：
LOCAL_OS_AUTHENTICATION_LISTENER = OFF

lsnrctl
LSNRCTL>set current_listener  LISTENER 上面表红的别名
LSNRCTL>change_password          -------Oracle$zj123
LSNRCTL>set passwd 
LSNRCTL>save_config
其中必须要使用change_password ，而不是set password ,无需重启监听立即生效




------------过滤监听日志中的ip地址
 cat listener_zjhz-bjiagw-mdsp-rac01.log.2013bak|fgrep "establish"|awk -F* '{print $3}'|awk -F= '{ print $4}'|sed -e 's/......$//g'|sort |uniq -c|sort
 
--------采集监听连接信息
fgrep "(CONNECT_DATA=(SERVER=" listener_zjhz-bjiagw-mdsp-rac03.log|fgrep "establish"|awk -F* '{print $3}'|awk -F= '{ print $4}'|sed -e 's/......$//g'|sort |uniq -c|sort 
1.根据监听日志生成insert数据
grep 'establish'  listener_zjhz-bjiagw-mdsp-rac03.log | sed 's/\*.*SERVICE_NAME=/  /g;s/).*tcp)(HOST=/ /g;s/).*$//g'   |  awk  '{if(NF==4){print "insert into t_tab  values('\''"$1"'\'','\''"$2"'\'','\''"$3"'\'','\''"$4"'\'');"}}'   > /home/oracle/listener_m3_insert.sql
2.建表并入库数据
--a1 日期
--a2 时间
--a3 服务名
--a4 客户端ip
Create table t_tab( a1 varchar2(50),a2  varchar2(50),a3  varchar2(50),a4  varchar2(50));
@/arch01/insert.26.sql
Commit









据ORACLE解释，在任何操作系统版本都有此问题。
现象：监听器启动后，隔一段时间（长短不定），就会出现无法连接： 若是用10201版本的SQLPLUS，则会出现 NO LISTENER。
9207 版本的SQLPLUS，则会出现：没反应，HANG住。
原因：10201 版本上的一个BUG：4518443。其会自动创建一个子监听器，当出现此情况时，监听器将会挂起。
/opt/oracle/product/10g/network/log/listener.log有如下语句:
WARNING: Subscription for node down event still pending
检查是否真因为此BUG造成此现象：
$ ps -ef | grep tnslsnr
ora10g 8909 1 0 Sep 15 ? 902:44 /u05/10GHOME/DBHOME/bin/tnslsnr sales -inherit
ora10g 22685 8909 0 14:19:23 ? 0:00 /u05/10GHOME/DBHOME/bin/tnslsnr sales –inherit
正常情况只有一个监听器，而此BUG则会出现两个监听器。
解决方法：打补丁4518443 或者在listener.ora 文件里加入：
SUBSCRIBE_FOR_NODE_DOWN_EVENT_<listener_name>=OFF
其中，<listener_name> 是数据库的监听器的名称。如：默认情况下，监听器名为：LISTENER 。则语句就是：
SUBSCRIBE_FOR_NODE_DOWN_EVENT_LISTENER=OFF
重启监听程序:
lsnrctl stop
lncrctl start
