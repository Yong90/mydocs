asm常见参数：
和database实例一样，asm同样具有启动实例的相关参数，具体如下：
asm_diskgroups:指定asm实例启动的时候需要mount的disk group名字：
asm_disktsring :指定一个asm实例寻找磁盘的路径名可以有通配符。
asm_power_limit:指定在磁盘组中平衡数据的时候默认的power大小。
asm_preferred_read_failure_groups:指定优先读取的故障组
diagnostic_dest:asm实例diagnostics的目录
instance_type:实例类型，对于asm实例必须为asm
remote_login_passwordfile:验证是否需要去读密码文件


sm实例和数据库实例参数文件搜索过程：
对于asm实例在启动的时候需要参数文件，那么一般搜索过程为：
1、先根据GPNP profile文件指定的参数文件位置进行寻找
2、如果没有在GPNP profile中指定的目录找到，那么将寻找$ORACLE_HME/dbs/spfile+ASM.ora
3、如果没有spfile+ASM.ora,那么将寻找pfile文件。
如果上述没有找到则无法启动asm
对于数据库实例启动的时候需要参数文件，那么搜素过程为：
1、寻找 $ORACLE_HOME/dbs/spfile<ORACLE_SID>.ora,
2、寻找 $ORACLE_HOME/dbs/spfile.ora
3、寻找 $ORACLE_HOME/dbs/init<ORACLE_SID>.ora
如果上述没有找到参数文件，那么数据库实例无法启动。







-----创建磁盘组
CREATE DISKGROUP diskgroup_name
              [ { HIGH | NORMAL | EXTERNAL } REDUNDANCY ]
              [ FAILGROUP failgroup_name ]
              DISK [ NAME disk_name ] [ SIZE size_clause ] [ FORCE | NOFORCE ] ...; 
create diskgroup dgtest normal redundancy
failgroup DATA1 disk '/dev/oracleasm/disks/VOL5' name DATA1
failgroup DATA2 disk '/dev/oracleasm/disks/VOL6' name DATA2; 

create diskgroup datadg External REDUNDANCY
 disk '/dev/oracleasm/datadisk01'
 attribute
 'au_size'='4M',
 'compatible.asm'='12.1',
 'compatible.rdbms'='12.1'
 /	


create diskgroup datagroup3 normal redundancy
   failgroup failgroup_1 disk
    '/dev/oracleasm/disks/ASMDISK7' NAME DATAGROUP3_DISK7
    failgroup failgroup_2 disk
    '/dev/oracleasm/disks/ASMDISK8' NAME DATAGROUP3_DISK8,
    '/dev/oracleasm/disks/ASMDISK9' NAME DATAGROUP3_DISK9
quorum failgroup failgroup_3 disk
     8  '/dev/oracleasm/disks/ASMDISK10' NAME DATAGROUP3_DISK10
   ATTRIBUTE 'au_size'='4M',
   'compatible.rdbms'='11.2',
   'compatible.asm'='11.2',
   'sector_size'='512';



------查看extend
select disk_kffxp disk#, 
XNUM_KFFXP extent#,
case lxn_kffxp
  when 0 then 'Primary Copy'
  when 1 then 'Mirrored Copy'
  when 2 then '2nd Mirrored Copy or metadata'
  else 'Unknown' END TYPE
from x$kffxp
where 
number_kffxp=287
and xnum_kffxp!=65534
order by 2;




磁盘成员管理 
为diskgroup增加disk
alter diskgroup DATA add disk '/dev/oracleasm/VOL5' name VOL5,'/dev/oracleasm/VOL6' name VOL6; 
从diskgroup删除disk
alter diskgroup DATA drop disk VOL5; 
取消删除disk的命令，只在上述命令没执行完成的时候有效
ALTER DISKGROUP DATA UNDROP DISKS; 
为DG2的个故障组各添加一个成员
alter diskgroup DG2
add failgroup FG1 disk '/dev/oracleasm/disks/VOL7'
add failgroup FG2 disk '/dev/oracleasm/disks/VOL8'
add failgroup FG3 disk '/dev/oracleasm/disks/VOL9'; 
数据文件别名 
取别名
alter diskgroup <diskgroup_name> add alias <alias_name> for '<asm_file>';   
ALTER DISKGROUP disk_group_1 ADD ALIAS '+disk_group_1/my_dir/my_file.dbf' FOR '+disk_group_1/mydb/datafile/my_ts.342.3'; 
注意:10g中只有利用OMF创建的ASM文件才能取别名(11g未测试)，且别名和原文件名的diskgroup必须一致，如上例的+disk_group_1 
重命名别名
ALTER DISKGROUP disk_group_1 RENAME ALIAS '+disk_group_1/my_dir/my_file.dbf'  TO '+disk_group_1/my_dir/my_file2.dbf'; 
删除别名
ALTER DISKGROUP disk_group_1 DELETE ALIAS '+disk_group_1/my_dir/my_file.dbf'; 
使用别名删除数据文件
ALTER DISKGROUP disk_group_1 DROP FILE '+disk_group_1/my_dir/my_file.dbf'; 
使用全面删除数据文件
ALTER DISKGROUP disk_group_1 DROP FILE '+disk_group_1/mydb/datafile/my_ts.342.3'; 
查看别名信息
select *　from v$asm_alias; 
手动Rebalance
alter diskgroup DG2 rebalance power 3 wait; 
为磁盘组增加目录
为磁盘组增加目录
alter diskgroup DG2 add directory '+DG2/datafile';    
注意必须确保各级目录都存在，否则会报错ORA-15173

ASM的 磁盘组动态重新平衡
alter diskgroup ORADG add disk 'ORCL:VOL6' rebalance power 11;




ASM的常见故障 
1.创建磁盘时出现错误可以查看asm日志
tail -f /var/log/oracleasm     
2.启动asm实例时出现ORA-29701错误
ORA-29701: unable to connect to Cluster Manager 
首次需要启用css服务，使用root帐户,运行
$ORACLE_HOME/bin/localconfig add   
如果下次启动实例的时候仍然碰到如下报错：
ORA-29701: unable to connect to Cluster Manager 
那么检查/etc/inittab 文件，看看是否有下面这行
h1:35:respawn:/etc/init.d/init.cssd run >/dev/null 2>&1 </dev/null 
如果没有请添加，如果被注释了请取消注释(root帐户)。
也可以使用root帐户执行/u01/oracle/10g/bin/localconfig reset 来解决
如果在执行长时间hang住，可以执行如下操作
$ORACLE_HOME/bin/localconfig delete
$ORACLE_HOME/root.sh    
$ORACLE_HOME/bin/localconfig add   
3.磁盘搜索路径问题 
SQL> create diskgroup DG1 normal redundancy disk 'ORCL:VOL1','ORCL:VOL2';
create diskgroup DG1 normal redundancy disk 'ORCL:VOL1','ORCL:VOL2'
*
ERROR at line 1:
ORA-15018: diskgroup cannot be created
ORA-15031: disk specification 'ORCL:VOL2' matches no disks
ORA-15031: disk specification 'ORCL:VOL1' matches no disks 
使用oraclasm创建磁盘后，缺省会在/dev/oracleasm/disks目录下添加刚刚创建的磁盘映射,修改asm_diskstring修改路径之后再次创建即可
alter system set asm_diskstring='/dev/oracleasm/disks/VOL*' 
注意事项： ASM 实例在配置好并且创建了ASM磁盘组之后，还必须保证已经注册到Listener中后才能在数据库实例中使用，否则就需要手工注册ASM 实例： 
SQL>alter system register;


ASM 磁盘的相关视图 
v$asm_disk(_stat)       --查看磁盘及其状态信息
v$asm_diskgroup(_stat)  --查看磁盘组及其状态信息
v$asm_operation         --查看当前磁盘的操作信息
v$asm_client            --返回当前连接的客户端实例信息
v$asm_file              --返回asm文件的相关信息
v$asm_template          --返回asm文件样本的相关信息
v$asm_alias             --返回asm文件的别名信息




--------ASM磁盘查询
set linesize 1000 pagesize 500
col name for a20
col state for a20
col type for a20
col  total_gb for 999999.99
col  free_gb for 999999.99
SELECT a.NAME,
       a.STATE,
       a.TYPE,
       a.TOTAL_MB / 1024 total_gb,
       decode(a.FREE_MB,'',1,0,1,a.FREE_MB) / 1024 free_gb,
       trunc(a.FREE_MB/decode(a.FREE_MB,'',1,0,1,a.FREE_MB) *100,2) pct_free
  FROM v$asm_diskgroup a order by  6;

set linesize 1000 pagesize 500
col name for a20
col state for a20
col path for a40
col  total_gb for 999999.99
col  free_gb for 999999.99  
SELECT a.NAME,
       b.PATH,
       b.STATE,
       b.MOUNT_STATUS,
       b.TOTAL_MB/1024 total_gb,
       b.FREE_MB/1024 free_gb
  FROM v$asm_disk b, v$asm_diskgroup a
 WHERE a.GROUP_NUMBER = b.GROUP_NUMBER order by 2,1;
