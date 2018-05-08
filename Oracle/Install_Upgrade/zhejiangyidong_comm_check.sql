



cd /home/oracle/shsnc/lyong/scripts

python27 py2handover.py ipaddr=10.211.103.242  port=22 orapwd=oracle/Zxcv1234  dbaddr=10.211.103.243:1521/infoxdb  dbuser=system/Zxcv1234 >./handhtml/10.211.103.242.html
python27 py2handover.py ipaddr=10.211.103.243  port=22 orapwd=oracle/Zxcv1234  dbaddr=10.211.103.243:1521/infoxdb  dbuser=system/Zxcv1234 >./handhtml/10.211.103.243.html

python27 py2handover.py ipaddr=10.211.86.72  port=22 orapwd=oracle/Zxcv1234  dbaddr=10.211.86.72:1521/infoxdb  dbuser=system/Zxcv1234 >./handhtml/10.211.86.72.html
python27 py2handover.py ipaddr=10.211.86.66  port=22 orapwd=oracle/Zxcv1234  dbaddr=10.211.86.66:1521/sdpdb  dbuser=system/Zxcv1234 >./handhtml/10.211.86.66.html
python27 py2handover.py ipaddr=10.211.86.67  port=22 orapwd=oracle/Zxcv1234  dbaddr=10.211.86.66:1521/sdpdb  dbuser=system/Zxcv1234 >./handhtml/10.211.86.67.html














-----------------入网检查，OS环境
------host name and VERSION
hostname
cat /etc/redhat-release 
cat /etc/SuSE-release 

#####Users belong to groups
id oracle
id grid


-------11g rpm packet inspection
-------RHEL6
rpm -q --qf '%{NAME}-%{VERSION}-%{RELEASE} (%{ARCH})\n'  \
binutils compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 gcc gcc-c++ \
glibc.i686 glibc glibc-devel glibc-devel.i686 ksh libgcc.i686 libgcc libstdc++ \
libstdc++.i686 libstdc++-devel libstdc++-devel.i686 libaio libaio.i686 libaio-devel \
libaio-devel.i686 make sysstat unixODBC unixODBC.i686 unixODBC-devel unixODBC-devel.i686 elfutils-libelf-devel

------SUSE 11
rpm -q --qf '%{NAME}-%{VERSION}-%{RELEASE} (%{ARCH})\n'    \
 binutils gcc gcc-32bit gcc-c++ glibc glibc-32bit glibc-devel glibc-devel-32bit   ksh-93t libaio \
libaio-32bit libaio-devel libaio-devel-32bit libstdc++33 libstdc++33-32bit libstdc++43  libstdc++43-32bit libstdc++43-devel \
libstdc++43-devel-32bit libgcc43 libstdc++-devel make sysstat unixODBC unixODBC-32bit unixODBC-devel unixODBC-devel-32bit





------system configure

#######################################################
grep dba /etc/group;grep oinstall /etc/group


#######################################################
grep oracle /etc/passwd


#######################################################
cat /proc/meminfo | grep -i hugepage


#######################################################
  grep pam_limits.so /etc/pam.d/login 


#######################################################
ps -ef |grep -v grep|grep ntp


#######################################################
tail -20 /etc/sysctl.conf 


#######################################################
su - oracle
/usr/bin/ldd $ORACLE_HOME/bin/oracle | grep libaio

#######################################################





--------database  env
$ORACLE_HOME/OPatch/opatch lsinventory -oh $ORACLE_HOME


tail -6 /etc/oratab


-----------日志
adrci << EOF
show alert -term -p "MESSAGE_TEXT like '%ORA-%'"
EOF

PURGE -age 1440 -type ALERT

------失效组件

sqlplus / as sysdba

set linesize 500 pagesize 2000
col object_name format a35
col owner  for a15
select owner,/*object_name, */object_type, count(*)
  from (select owner,object_name, object_type
          from dba_objects
         where status != 'VALID'
        union
        select 'registry' owner,comp_name as object_name, 'dba_registry' object_type
          from dba_registry d1
         where status != 'VALID'
        union
        select INDEX_OWNER owner,index_name || partition_name object_name,
               'PART_INDEX' object_type
          from dba_ind_PARTITIONS
         where status != 'USABLE')
 group by owner, object_type order by 1,2,3;
 
 

set linesize 1000 pagesize 500
col COMP_NAME for a40    
col STATUS for a10
col VERSION for a15
col OTHER_SCHEMAS for a15
col NAMESPACE for a10
col CONTROL for a10
col SCHEMA for a15
col PROCEDURE for a35
col PARENT_ID for a5
col COMP_ID for a10
select * from dba_registry d1 where status != 'VALID';
         
 --------------------表空间
 set linesize 1000 pagesize 500
col tablespace_name for a30
with free_space as (SELECT /*+ MATERIALIZED*/ tablespace_name,
               file_id,
               SUM(BYTES) BYTES,
               MAX(BYTES) maxbytes
          FROM dba_free_space
         GROUP BY tablespace_name, file_id)
SELECT df.tablespace_name,
       COUNT(*) datafile_count,
       ROUND(SUM(df.BYTES) / 1048576 / 1024, 2) size_gb,
       ROUND(SUM(free.BYTES) / 1048576 / 1024, 2) free_gb,
       ROUND(SUM(df.BYTES) / 1048576 / 1024 -
             SUM(free.BYTES) / 1048576 / 1024,
             2) used_gb,
       ROUND(MAX(free.maxbytes) / 1048576 / 1024, 2) maxfree,
       100 - ROUND(100.0 * SUM(free.BYTES) / SUM(df.BYTES), 2) pct_used,
       ROUND(100.0 * SUM(free.BYTES) / SUM(df.BYTES), 2) pct_free
  FROM dba_data_files df,
       free_space free
 WHERE df.tablespace_name = free.tablespace_name(+)
   AND df.file_id = free.file_id(+)
 GROUP BY df.tablespace_name
 ORDER BY 8;
 
 
 
 
 --------------自动扩展数据文件
set lines 1320 pages 1000 
col FILE_NAME for a100 
select * from (
select a.TABLESPACE_NAME,FILE_NAME,a.bytes/1024/1024/1024 size_gb
  from dba_data_files a
 where a.TABLESPACE_NAME like 'UNDOTBS%'
union all
select a.TABLESPACE_NAME,FILE_NAME,a.bytes/1024/1024/1024 size_gb
  from DBA_TEMP_FILES a) order by TABLESPACE_NAME,FILE_NAME;
 
 
select 'alter database datafile ''' || a.file_name || ''' resize 30G;'
  from dba_data_files a  where a.TABLESPACE_NAME like 'UNDOTBS%';
 

 
select 'alter database datafile ''' || a.file_name || ''' autoextend off;'
  from dba_data_files a, dba_tablespaces b
 where a.TABLESPACE_NAME = b.TABLESPACE_NAME
   and a.AUTOEXTENSIBLE = 'YES'
   and b.BIGFILE = 'NO'
union all
select 'alter database tempfile ''' || a.file_name || ''' autoextend off;'
  from DBA_TEMP_FILES a, dba_tablespaces b
 where a.TABLESPACE_NAME = b.TABLESPACE_NAME
   and a.AUTOEXTENSIBLE = 'YES'
   and b.BIGFILE = 'NO';


 set lines 132 pages 1000 
select 'alter database datafile ''' || a.file_name || ''' resize 30G;'
  from dba_data_files a, dba_tablespaces b
 where a.TABLESPACE_NAME = b.TABLESPACE_NAME
   and a.AUTOEXTENSIBLE = 'YES'
   and b.BIGFILE = 'NO'
union all
select 'alter database tempfile ''' || a.file_name || ''' resize 15G;'
  from DBA_TEMP_FILES a, dba_tablespaces b
 where a.TABLESPACE_NAME = b.TABLESPACE_NAME
   and a.AUTOEXTENSIBLE = 'YES'
   and b.BIGFILE = 'NO';



 set lines 132 pages 1000 
select  a.TABLESPACE_NAME,a.file_name 
  from dba_data_files a, dba_tablespaces b
 where a.TABLESPACE_NAME = b.TABLESPACE_NAME
   and a.AUTOEXTENSIBLE = 'YES'
   and b.BIGFILE = 'NO'
union all
select  a.TABLESPACE_NAME,a.file_name 
  from DBA_TEMP_FILES a, dba_tablespaces b
 where a.TABLESPACE_NAME = b.TABLESPACE_NAME
   and a.AUTOEXTENSIBLE = 'YES'
   and b.BIGFILE = 'NO';



-----回收站
select count(*) from dba_recyclebin;
 
 
------非系统用户对象存放在系统表空间中
select * from dba_segments 
where owner not in ('SYS','SYSTEM','OUTLN','LBACSYS') 
and tablespace_name='SYSTEM';
 

----SYSDBA权限检查

set linesize 300
col  SYSDBA format a10
col  SYSOPER format a10
select * from v$pwfile_users;


------审计检查
show parameter audit_trail;
col segment_name for a50
SELECT A.segment_name,
       a.bytes / 1024 / 1024,
       B.TABLESPACE_NAME,
       B.SEGMENT_SPACE_MANAGEMENT
  FROM dba_segments A, DBA_TABLESPACES B
 WHERE A.tablespace_name = B.TABLESPACE_NAME
   AND A.segment_name IN ('FGA_LOG$', 'AUD$');
   
   
-----redo check

select GROUP#, THREAD#, BYTES / 1024 / 1024 size_mb, MEMBERS,STATUS
  from v$log order by 2,1;


------headroom
  set line 500 pagesize 500
  col VERSION for a20
  col DATE_TIME for 25
  col CURRENT_SCN for 99999999999999999
  SELECT version,
         date_time,
         dbms_flashback.get_system_change_number current_scn ,
         indicator
    FROM ( SELECT version,
                 to_char (SYSDATE , 'YYYY/MM/DD HH24:MI:SS') DATE_TIME,
                 ((((((to_number (to_char (SYSDATE , 'YYYY')) - 1988 ) * 12 * 31 * 24 * 60 * 60) +
                 ((to_number (to_char (SYSDATE , 'MM')) - 1 ) * 31 * 24 * 60 * 60) +
                 (((to_number (to_char (SYSDATE , 'DD')) - 1 )) * 24 * 60 * 60) +
                 (to_number (to_char (SYSDATE , 'HH24')) * 60 * 60 ) +
                 (to_number (to_char (SYSDATE , 'MI')) * 60 ) +
                 (to_number (to_char (SYSDATE , 'SS')))) * ( 16 * 1024)) -
                 dbms_flashback.get_system_change_number ) /
                 (16 * 1024 * 60 * 60 * 24 )) indicator
            FROM v$instance ) ;

------controlfile
col NAME for a50
select  * from V$controlfile;

------------数据文件
ho df -h

col file_name for a70
select file_name from dba_data_files;


select file_name from dba_temp_files;


--------其他参数检查
show parameter db_files
show parameter undo_management
show parameter remote_login_passwordfile
show parameter REMOTE_OS_ROLES
show parameter max_dump_file_size
show parameter open_cursors
show parameter cursor_sharing




set linesize 1000 pagesize 800
col value for a30
col name for a30
SELECT NAME, VALUE
  FROM v$parameter t
 WHERE t.name IN
       ('memory_max_target', 'memory_target', 'sga_target', 'sga_max_size',
        'db_cache_size', 'shared_pool_size', 'pga_aggregate_target',
        'java_pool_size', 'large_pool_size', 'log_buffer', 'db_files',
        'control_files', 'undo_management', 'remote_login_passwordfile',
        'REMOTE_OS_ROLES', 'max_dump_file_size', 'open_cursors',
        'cursor_sharing', 'streams_pool_size', 'streams_pool_size',
        '_gc_policy_time', '_undo_autotune', 'deferred_segment_creation',
        '_in_memory_undo','_ktb_debug_flags','_optimizer_use_feedback');


 
 
vi $ORACLE_HOME/network/admin/listener.ora


SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = PLSExtProc)
      (ORACLE_HOME =/u01/app/oracle/product/11.2.0/dbhome_1)
      (PROGRAM = extproc)
    )
    (SID_DESC =
      (GLOBAL_DBNAME = btsa)
      (ORACLE_HOME = /u01/app/oracle/product/11.2.0/dbhome_1)
      (SID_NAME = btsa)
    )
  )


su - oracle

lsnrctl status


lsnrctl stop

lsnrctl start 

sqlplus / as sysdba

alter system register;

exit;

lsnrctl status




------------------------------------------sqlnet.ora中操作，涉及下面几项，集中修改，
双机信任ip 不进行加固（tcp.validnode_checking = yes
                       tcp.invited_nodes =(*.*.*.*) ）
--添加信任ip
--为数据库监听器（LISTENER）的关闭和启动设置密码。
--SQLNET.EXPIRE_TIME = 10’关键字
--sqlnet.encryption_server = requested’关键字

vi $ORACLE_HOME/network/admin/sqlnet.ora

--11g （非双机）
#for an quan jia gu  11g not HA
##do not write tns msg to alert.log
DIAG_ADR_ENABLED= OFF
#####jiagu
tcp.validnode_checking = yes
tcp.invited_nodes =(188.102.7.194,10.211.57.172,10.211.59.192,10.211.172.14,10.212.211.4,10.212.211.5,10.212.219.82,10.212.219.83*.*.*.*)
SQLNET.EXPIRE_TIME = 10
LOCAL_OS_AUTHENTICATION_LISTENER = OFF
PASSWORDS_LISTENER = 8A2F0E9477B85710
sqlnet.encryption_server = rejected
sqlnet.encryption_server = requested


--11g ha
##do not write tns msg to alert.log
DIAG_ADR_ENABLED= OFF
#for an quan jia gu
SQLNET.EXPIRE_TIME = 10
tcp.validnode_checking = yes
tcp.invited_nodes =(*.*.*.*)
LOCAL_OS_AUTHENTICATION_LISTENER = OFF
PASSWORDS_LISTENER = 8A2F0E9477B85710
sqlnet.encryption_server = rejected
sqlnet.encryption_server = requested


----监听
PASSWORDS_LISTENER =



---------------------Oracle软件账户的访问控制可遵循操作系统账户的安全策略，比如不要共享账户、强制定期修改密码、密码需要有一定的复杂度等。
--根据下面的提示进行修改root 下执行，不同操作系统修改不同项

AIX：手动修改/etc/security/user文件中histexpire值为13
HP： 手动修改/etc/default/security文件中PASSWORD_MAXDAYS值为90
RedHat：手动修改/etc/login.defs文件中PASS_MAX_DAYS值为90
SUSE：手动修改/etc/login.defs文件中PASS_MAX_DAYS值为90
Solaris: 手动修改/etc/default/passwd文件MAXWEEKS值为13"          




--------检查是否更改数据库默认帐号的密码
sqlplus / as sysdba
SELECT USERNAME
  FROM dba_users
 WHERE password IN
       ('DF02A496267DEE66' , '2BE6F80744E08FEB', '9793B3777CD3BD1A',
        'CE4A36B8E06CA59C', '9C30855E7E0CB02D' , '6399F3B38EDF3288',
        '66F4EF5650C20355', 'BFBA5A553FD9E28A' , '7C9BA362F8314299',
        '71E687F036AD56E5', 'anonymous' , '88D8364765FCE6AF',
        '73847B44A7F8AE70', '4A3BA55E08595C81' , 'D4C5016086B2DC6A',
        'D4DF7931AB130E37', 'E7B5D92911C831E1' , 'AC98877DE1297365',
        'AC9700FD3F1410EB', 'E066D214D5421CCC' , '24ABAB8B06281B4C',
        'C252E8FA117AF049', 'A7A32CD03D3CE8D5' , '3F9FBD883D787341',
        'F894844C34402B67', '3DF26A8B17D0F29F' , 'FA1D2B85B70213F3',
        '72E382A52E89575A', '8CDB9B662C4289FF' , '8136F9C3050F2358',
        '88A2B2C183431F00', '84B8CBCA4D477FA3' , '3FB8EF9DB538647C',
        '79DF7A1BD138CF11', 'F9DA8977092B7B81' , '9300C0977D7DC75E',
        'F25A184809D6458D', '8136F9C3050F2358' , '72979A94BAD2AF80',
        'A97282CE3D94E29E', '7EFA02EC7EA6B86F' );


set linesize 1000 pagesize 500 
select a.INST_ID, a.sid,'kill -9 '|| p.spid as cmd
  from v$access a, v$session s, V$process p
 where /*a.INST_ID = s.INST_ID
   and */a.sid = s.sid
  /* and s.INST_ID = p.inst_id*/
   and s.paddr = p.addr
   and a.object like '%AUD$%';

-----------------启动审计功能
set linesize 1000 pagesize 5000
show parameter audit_trail;
col segment_name for a50
SELECT A.segment_name,
       a.bytes / 1024 / 1024,
       B.TABLESPACE_NAME,
       B.SEGMENT_SPACE_MANAGEMENT
  FROM dba_segments A, DBA_TABLESPACES B
 WHERE A.tablespace_name = B.TABLESPACE_NAME
   AND A.segment_name IN ('FGA_LOG$', 'AUD$');
     
--可选参数os 或者 db,建议为db
alter system set audit_trail='DB' scope=spfile;
--重启实例后执行下面的操作
truncate table SYS.aud$;

--11g ，迁移到非系统表空间
------表空间查询
set linesize 1000 pagesize 500
col tablespace_name for a30
with free_space as (SELECT /*+ MATERIALIZED*/ tablespace_name,
               file_id,
               SUM(BYTES) BYTES,
               MAX(BYTES) maxbytes
          FROM dba_free_space
         where bytes > 1024 * 1024
         GROUP BY tablespace_name, file_id)
SELECT df.tablespace_name,
       COUNT(*) datafile_count,
       ROUND(SUM(df.BYTES) / 1048576 / 1024, 2) size_gb,
       ROUND(SUM(free.BYTES) / 1048576 / 1024, 2) free_gb,
       ROUND(SUM(df.BYTES) / 1048576 / 1024 -
             SUM(free.BYTES) / 1048576 / 1024,
             2) used_gb,
       ROUND(MAX(free.maxbytes) / 1048576 / 1024, 2) maxfree,
       100 - ROUND(100.0 * SUM(free.BYTES) / SUM(df.BYTES), 2) pct_used,
       ROUND(100.0 * SUM(free.BYTES) / SUM(df.BYTES), 2) pct_free
  FROM dba_data_files df,
       free_space free
 WHERE df.tablespace_name = free.tablespace_name(+)
   AND df.file_id = free.file_id(+)
 GROUP BY df.tablespace_name
 ORDER BY 8;



BEGIN
  DBMS_AUDIT_MGMT.set_audit_trail_location(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,
                                            --this moves table AUD$
                                           audit_trail_location_value => 'MGMT_TABLESPACE'); --AUD替换为系统中的ASSM表空间
END;
/


BEGIN
  DBMS_AUDIT_MGMT.set_audit_trail_location(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD,
                                            --this moves table FGA_LOG$
                                           audit_trail_location_value => 'INFOSYS'); --FGA替换为系统中的ASSM表空间
END;
/


--部署清理脚本，根据保留情况，修改下面的脚本
CREATE or replace PROCEDURE P_CLEAR_AUDIT AS
  LVC_SQL VARCHAR2(200);
BEGIN
  LVC_SQL := ' truncate table  SYS.AUD$  ';
  EXECUTE IMMEDIATE LVC_SQL;
  commit;
END;
/

CREATE or replace PROCEDURE P_DELETE_CLEAR_AUDIT AS
  LVC_SQL VARCHAR2(200);
BEGIN
  LVC_SQL := 'delete from sys.aud$ a where NTIMESTAMP#<= to_timestamp(sysdate-10)';
  EXECUTE IMMEDIATE LVC_SQL;
  commit;
END;
/




--部署job ,注意修该netxt_data时间为当前时间
DECLARE
  JOBS INT;
BEGIN

  SYS.DBMS_JOB.SUBMIT(JOB       => JOBS,
                      WHAT      => 'P_DELETE_CLEAR_AUDIT;',
                      NEXT_DATE => TO_DATE('2016-11-30 13:17:00',
                                           'YYYY-MM-DD HH24:MI:SS'),
                      INTERVAL  => 'SYSDATE+1');
  COMMIT;
END;
/

/*
DECLARE
  JOBS INT;
BEGIN
  SYS.DBMS_JOB.REMOVE(JOB       => 3);
  COMMIT;
END;
/
*/

--查询job 部署情况
  COL WHAT FOR A50
  COL INTERVAL FOR A30
  SET LINES 1000
  SELECT SCHEMA_USER,PRIV_USER,JOB,INTERVAL ,to_char(T.NEXT_DATE,'yyyy-mm-dd hh24:mi:ss') NEXT_DATE,WHAT  FROM DBA_JOBS T WHERE WHAT LIKE '%CLEAR_AUDIT%';


SELECT SCHEMA_USER,PRIV_USER,JOB,INTERVAL ,to_char(T.NEXT_DATE,'yyyy-mm-dd hh24:mi:ss') NEXT_DATE,WHAT  FROM DBA_JOBS T where SCHEMA_USER='XJMON'



---------------------限制具备数据库超级管理员（SYSDBA）权限的用户远程登录。  
show parameter remote_login_passwordfile
show parameter O7_DICTIONARY_ACCESSIBILITY      
--修改后需要重启数据库
alter system set remote_login_passwordfile=none scope=spfile sid='*';

----------------------启用数据字典保护，只有SYSDBA用户才能访问数据字典基础表
--如果返回TRUE，责将其修改为FALSE
alter system set O7_DICTIONARY_ACCESSIBILITY=false scope=spfile sid='*';  

















----------------------------加固方案：收回该用户的dba权限，REVOKE DBA FROM xxxx
------查询DBA的sql
SELECT a.username
  FROM dba_users a
  LEFT JOIN dba_role_privs b
    ON a.username = b.grantee
 WHERE granted_role = 'DBA'
   AND a.username NOT IN ('SYS' , 'SYSMAN', 'SYSTEM' , 'WKSYS', 'CTXSYS' );





----------------------------加固方案：创建role，并授权给某些用户，REVOKE DBA FROM xxxx
--该项如果回收完dba后不需要操作








--------------------------使用usermod命令将属于dba组的非oracle用户变更到其他组
--该项需要根据情况决定，需要与业务确认，如果11g grid 用户在的dba组中属于正常情况



--------------------数据库应配置日志功能，对用户登录进行记录，记录内容包括用户登录使用的账号、登录是否成功、登录时间以及远程登录时用户使用的IP地址

--创建表然 和触发器后

CREATE TABLE SYS.LOGON_TABLE
(
  USER_NAME   VARCHAR2(50 BYTE),
  LOGON_TIME  DATE
);

CREATE  TRIGGER SYS.TRI_LOGON
  AFTER LOGON ON DATABASE
BEGIN
  INSERT INTO LOGON_TABLE VALUES (SYS_CONTEXT('USERENV', 'SESSION_USER'),
SYSDATE);
delete from LOGON_TABLE where LOGON_TIME<sysdate -7;
END;    
/

exit;


  sqlplus / as sysdba

  exit;


--退出sqlplus 重新登录,确保表中有数据
sqlplus / as sysdba  

select count(*) from SYS.LOGON_TABLE;

--禁用触发器
alter trigger SYS.TRI_LOGON disable;








--------------------------------------profile相关加固
@?/rdbms/admin/utlpwdmg.sql    -----创建密码函数，会生成一下几个密码验证函数
ora12c_verify_function(oracle  database 12c)
ora12c_strong_verify_function(密码强度非常高 ,oracle  database 12c )
verify_function_11G (oracle  database 11g)
verify_function(oracle  database 10g)

--执行下面的sql     生成批量修改命令,然后执行命令
col cmd for a150
set line 1000 pagesize 500   
select 'alter profile ' || profile ||
       ' limit PASSWORD_VERIFY_FUNCTION VERIFY_FUNCTION;' as cmd
  from dba_profiles
 group by profile;

col cmd for a150
set line 1000 pagesize 500   
select 'alter profile ' || profile ||
       ' limit PASSWORD_VERIFY_FUNCTION VERIFY_FUNCTION;' as cmd
  from cdb_profiles
 group by profile;



--创建下面的规避  profile
/*
-----限制严格的profile
CREATE PROFILE app_guibi LIMIT
  FAILED_LOGIN_ATTEMPTS 6
   PASSWORD_LIFE_TIME 60
   PASSWORD_REUSE_TIME 60
   PASSWORD_REUSE_MAX 5
   PASSWORD_VERIFY_FUNCTION verify_function
   PASSWORD_LOCK_TIME 1/24
   PASSWORD_GRACE_TIME 90;
  */ 
  
CREATE PROFILE C##PROFILE LIMIT
  FAILED_LOGIN_ATTEMPTS UNLIMITED
   PASSWORD_LIFE_TIME UNLIMITED
   PASSWORD_REUSE_TIME UNLIMITED
   PASSWORD_REUSE_MAX UNLIMITED
   PASSWORD_VERIFY_FUNCTION verify_function
   PASSWORD_LOCK_TIME UNLIMITED
   PASSWORD_GRACE_TIME UNLIMITED
   COMPOSITE_LIMIT UNLIMITED
   CPU_PER_SESSION  UNLIMITED
   CPU_PER_CALL UNLIMITED
   LOGICAL_READS_PER_SESSION UNLIMITED
   LOGICAL_READS_PER_CALL UNLIMITED
   IDLE_TIME UNLIMITED
   CONNECT_TIME UNLIMITED
   PRIVATE_SGA UNLIMITED
   SESSIONS_PER_USER UNLIMITED 
   container=all;
   

CREATE PROFILE MONITORING_PROFILE  LIMIT
  FAILED_LOGIN_ATTEMPTS UNLIMITED
   PASSWORD_LIFE_TIME UNLIMITED
   PASSWORD_REUSE_TIME UNLIMITED
   PASSWORD_REUSE_MAX UNLIMITED
   PASSWORD_VERIFY_FUNCTION verify_function
   PASSWORD_LOCK_TIME UNLIMITED
   PASSWORD_GRACE_TIME UNLIMITED
   COMPOSITE_LIMIT UNLIMITED
   CPU_PER_SESSION  UNLIMITED
   CPU_PER_CALL UNLIMITED
   LOGICAL_READS_PER_SESSION UNLIMITED
   LOGICAL_READS_PER_CALL UNLIMITED
   IDLE_TIME UNLIMITED
   CONNECT_TIME UNLIMITED
   PRIVATE_SGA UNLIMITED
   SESSIONS_PER_USER UNLIMITED ;



-------创建业务profile

alter profile C##APP_USER LIMIT  
   FAILED_LOGIN_ATTEMPTS UNLIMITED
   PASSWORD_LIFE_TIME UNLIMITED
   PASSWORD_REUSE_TIME UNLIMITED
   PASSWORD_REUSE_MAX UNLIMITED
   PASSWORD_VERIFY_FUNCTION verify_function
   PASSWORD_LOCK_TIME UNLIMITED
   PASSWORD_GRACE_TIME UNLIMITED
   COMPOSITE_LIMIT UNLIMITED
   CPU_PER_SESSION  UNLIMITED
   CPU_PER_CALL UNLIMITED
   LOGICAL_READS_PER_SESSION UNLIMITED
   LOGICAL_READS_PER_CALL UNLIMITED
   IDLE_TIME UNLIMITED
   CONNECT_TIME UNLIMITED
   PRIVATE_SGA UNLIMITED
   SESSIONS_PER_USER UNLIMITED container=all  ; 


alter profile C##APP_USER  LIMIT  
   FAILED_LOGIN_ATTEMPTS 6
   PASSWORD_LIFE_TIME 60
   PASSWORD_REUSE_TIME UNLIMITED
   PASSWORD_REUSE_MAX 5
   PASSWORD_VERIFY_FUNCTION VERIFY_FUNCTION
   PASSWORD_LOCK_TIME UNLIMITED
   PASSWORD_GRACE_TIME UNLIMITED
   COMPOSITE_LIMIT UNLIMITED
   CPU_PER_SESSION  UNLIMITED
   CPU_PER_CALL UNLIMITED
   LOGICAL_READS_PER_SESSION UNLIMITED
   LOGICAL_READS_PER_CALL UNLIMITED
   IDLE_TIME UNLIMITED
   CONNECT_TIME UNLIMITED
   PRIVATE_SGA UNLIMITED
   SESSIONS_PER_USER UNLIMITED 
   container=all ;
  
     
------将相关用户放到没有限制的profile中，   迁移用户profile  
select 'alter user ' || username || ' profile MONITORING_PROFILE;'
  from dba_users
 where (ACCOUNT_STATUS = 'OPEN' or username in ('SYSTEM', 'SYS', 'DBSNMP'))
---   AND  profile = 'DEFAULT'
 group by username, profile;

alter user DVSYS profile c##paas container=all ;
alter user SYSTEM profile c##paas container=all ;
alter user DBSNMP profile c##paas container=all ;
alter user SYS profile c##paas container=all ;


select 'alter user ' || username || ' profile C##PROFILE;'
  from dba_users
 where (ACCOUNT_STATUS = 'OPEN' or username in ('SYSTEM', 'SYS', 'DBSNMP','DVSYS'))
---   AND  profile = 'DEFAULT'
 group by username, profile;
------创建规避用户
create user guibi identified by oracle$123 account lock  profile app_user;


-----------加固profile
--修改密码有效期：ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME 60;
--修改密码重复次数：ALTER PROFILE DEFAULT LIMIT PASSWORD_REUSE_MAX 5;              
--修改密码重复次数：ALTER PROFILE DEFAULT LIMIT FAILED_LOGIN_ATTEMPTS 6; 
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME 60 ;
ALTER PROFILE DEFAULT LIMIT FAILED_LOGIN_ATTEMPTS 6 ;
ALTER PROFILE DEFAULT LIMIT PASSWORD_REUSE_MAX 5 ;

set linesize 1000 pagesize 5000
SELECT  a.profile, a.resource_name,LIMIT
  FROM dba_profiles a
 WHERE a.PROFILE = 'DEFAULT';

set linesize 1000 pagesize 5000
col profile for a30

SELECT  a.profile, a.resource_name,LIMIT
  FROM dba_profiles a
 WHERE a.PROFILE in ( 'MONITORING_PROFILE','PAAS','DEFAULT','C##PROFILE')
 order by 1;


------检查用户
set linesize 1000 pagesize 5000
col USERNAME for a30
col CREATED for a20
col ACCOUNT_STATUS for a20
col  LOCK_DATE  for a20
col EXPIRY_DATE for a20
col DEFAULT_TABLESPACE for a20
col PROFILE for a20
SELECT USERNAME,
       ACCOUNT_STATUS,
       to_char(LOCK_DATE, 'yyyymmdd HH24:mi:ss') LOCK_DATE,
       to_char(EXPIRY_DATE, 'yyyymmdd HH24:mi:ss') EXPIRY_DATE,
       to_char(CREATED, 'yyyymmdd HH24:mi:ss') CREATED,
       PROFILE,
       DEFAULT_TABLESPACE
  FROM dba_users 
  --where  ACCOUNT_STATUS='OPEN'
 -- and USERNAME='DBSNMP'
 ORDER BY ACCOUNT_STATUS;


--确保非default 外的其他profile 密码有效期和错误登陆次数为无限制
select *
  from dba_profiles
 where resource_name in ('PASSWORD_LIFE_TIME', 'FAILED_LOGIN_ATTEMPTS')
   and PROFILE <> 'DEFAULT'
   and LIMIT <> 'UNLIMITED'
 order by profile;






--------------DVSYS
使用Oracle提供的虚拟私有数据库（VPD）和标签安全（OLS）来保护不同用户之间的数据交叉访问
--该项加固目前可以规避，采用如下方式
--1>首先确认 database valut 组件没有安装，如果安装了该组件则该项无法加固

--确认database valut 组件没有安装，结果为false,然后进行下面的操作
select 'Database_Vault',value from v$option where parameter like 'Oracle Database Vault%';



--以下操作都在sys下完成
--创建用户
create user dvsys identified by "Axyhj_!!@@@1234"   account lock  profile default;
--赋权
grant resource to dvsys;
--create table vpd
create table dvsys.vpd (id int);

--create function
create  function dvsys.f_aqjg_vpd(p_schema in varchar2,
                                 p_object in varchar2) return varchar2 is
  result varchar2(1000);
begin
  result := 'vpd not in (10)';
  return(result);
end f_aqjg_vpd;
/

--create policy
declare
begin
  dbms_rls.add_policy(object_schema   => 'dvsys', --数据表(或视图)所在的schema名称
                      object_name     => 'vpd', --数据表(或视图)的名称
                      policy_name     => 'p_aqjg_vpd', --policy的名称，主要用于将来对policy的管理
                      function_schema => 'dvsys', --返回where子句的函数所在schema名称
                      policy_function => 'f_aqjg_vpd', --返回where子句的函数名称
                      statement_types => 'select', -- dml类型，如 'select,insert,update,delete'
                      enable          => true --是否启用，值为'true'或'false'
                      );
end;
/

--生成数据
select count(*) from dvsys.vpd;

--查询数据
select count(*) from v$vpd_policy;


------Oracle 执行
vi home/oracle/yjb/anquanjiagu_for_vpd.sh
export ORACLE_HOME=
export ORACLE_SID=
sqlplus -S  "/as sysdba" <<EOF
select count(*),to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') sys_date  from dvsys.vpd;
exit;
EOF

chmod  a+x  home/oracle/yjb/anquanjiagu_for_vpd.sh


------root 执行
crontab  -e
#### for anquanjiagu vpd
*/1 * * * * su - oracle -c  /home/oracle/yjb/anquanjiagu_for_vpd.sh >>/home/oracle/yjb/vpd.log &  
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
