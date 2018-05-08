用户权限
系统权限分类：
DBA: 拥有全部特权，是系统最高权限，只有DBA才可以创建数据库结构。
RESOURCE:拥有Resource权限的用户只可以创建实体，不可以创建数据库结构。
CONNECT:拥有Connect权限的用户只可以登录Oracle，不可以创建实体，不可以创建数据库结构。
对于普通用户：授予connect, resource权限。
对于DBA管理用户：授予connect，resource, dba权限。
系统权限授权命令：grant connect, resource, dba to user_name [with admin option];
系统权限回收：系统权限只能由DBA用户回收
命令：SQL> Revoke connect, resource from user50;




实体权限分类：select, update, insert, alter, index, delete, all  //all包括所有权限
execute  //执行存储过程权限
将表的操作权限授予全体用户：
 grant all on product to public;  // public表示是所有的用户，这里的all权限不包括drop。
[实体权限数据字典]:
select owner, table_name from all_tables; // 用户可以查询的表
select table_name from user_tables;  // 用户创建的表
select grantor, table_schema, table_name, privilege from all_tab_privs; // 获权可以存取的表（被授权的）
select grantee, owner, table_name, privilege from user_tab_privs;   // 授出权限的表(授出的权限)
实体权限授权命令：grant select, update on product to user_name with grant option;
实体权限回收：Revoke select, update on product from user02;  //传递的权限将全部丢失。

------------------------------------------------创建用户：
Create User username
 Identified by password
 Default Tablespace tablespace
 Temporary Tablespace tablespace
 Profile profile_name
 Quota integer/unlimited on tablespace;

####范例
Create user lyong
 identified by acc01   // 如果密码是数字，请用双引号括起来
 default tablespace users
 temporary tablespace temp
 profile default
 quota 50m on users;


create user ygent   identified by oracle  account unlock   default tablespace users temporary tablespace TEMP;
grant dba to ygent;
修改用户：
Alter User 用户名
 Identified 口令
 Default Tablespace tablespace
 Temporary Tablespace tablespace
 Profile profile
 Quota integer/unlimited on tablespace;

#####范例：
修改口令字：
SQL>Alter user acc01 identified by "12345";
修改用户缺省表空间：
SQL> Alter user acc01 default tablespace users;
修改用户临时表空间
SQL> Alter user acc01 temporary tablespace temp_data;
强制用户修改口令字：
SQL> Alter user acc01 password expire;
将用户加锁
SQL> Alter user acc01 account lock;  // 加锁
SQL> Alter user acc01 account unlock;  // 解锁

#####删除用户
drop user 用户名;  //用户没有建任何实体
drop user 用户名 CASCADE;  // 将用户及其所建实体全部删除
监视用户：
查询用户会话信息：select username, sid, serial#, machine from v$session;
删除用户会话信息： Alter system kill session 'sid, serial#';
查询用户SQL语句： select user_name, sql_text from v$open_cursor;



set linesize 1000 pagesize 500
select PROFILE,RESOURCE_NAME,RESOURCE_TYPE,LIMIT from dba_profiles order by PROFILE,RESOURCE_NAME;

set linesize 1000 pagesize 5000
col LIMIT_cmd for a70
SELECT 'ALTER PROFILE ' || a.profile || ' LIMIT ' || a.resource_name ||
       ' UNLIMITED;' LIMIT_cmd
  FROM dba_profiles a,
       (SELECT PROFILE FROM dba_users WHERE ACCOUNT_STATUS = 'OPEN' group by PROFILE) b
 WHERE a.PROFILE = b.profile
   AND a.resource_name IN ('PASSWORD_LIFE_TIME', 'FAILED_LOGIN_ATTEMPTS')
   AND a.limit NOT IN ('UNLIMITED', 'DEFAULT')
 ORDER BY a.profile;



set linesize 1000 pagesize 5000
col USERNAME for a30
col CREATED for a20
col ACCOUNT_STATUS for a20
col  LOCK_DATE  for a20
col EXPIRY_DATE for a20
col PROFILE for a25
col DEFAULT_TABLESPACE for a20
col TEMPORARY_TABLESPACE for a20
col PROFILE for a20
SELECT --CON_ID,
USERNAME,
       ACCOUNT_STATUS,
       to_char(LOCK_DATE, 'yyyymmdd HH24:mi:ss') LOCK_DATE,
       to_char(EXPIRY_DATE, 'yyyymmdd HH24:mi:ss') EXPIRY_DATE,
       to_char(CREATED, 'yyyymmdd HH24:mi:ss') CREATED,
       PROFILE,
       DEFAULT_TABLESPACE,
       TEMPORARY_TABLESPACE
  FROM dba_users
where 1=1
--and ACCOUNT_STATUS='OPEN'
--and  USER_ID=170
--and USERNAME in ('XJMON')
 ORDER BY ACCOUNT_STATUS,USERNAME--,CON_ID
 ;


select SCHEMANAME,count(*)  from XJMON.TAB_XJ_COLLECT_SESSION group by SCHEMANAME;

select distinct a.OWNER, a.DATA_TYPE
  from ALL_TAB_COLUMNS a
  join dba_users b
    on a.OWNER = b.USERNAME
 where b.ACCOUNT_STATUS = 'OPEN'
   and b.USERNAME not like 'SYS%'
   order by a.OWNER, a.DATA_TYPE;


select distinct  a.DATA_TYPE
  from ALL_TAB_COLUMNS a
  join dba_users b
    on a.OWNER = b.USERNAME
 where b.ACCOUNT_STATUS = 'OPEN'
   and b.USERNAME not like 'SYS%'
   order by a.DATA_TYPE;



set linesize 1000 pagesize 5000
col USERNAME for a30
col CREATED for a20
col STATUS for a15
col  LOCK_DATE  for a20
col PROFILE for a10
col COMMON for a15
SELECT a.CON_ID,
       b.name,
       a.COMMON,
       a.USERNAME,
       a.ACCOUNT_STATUS STATUS,
       to_char(a.LOCK_DATE, 'yyyymmdd HH24:mi:ss') LOCK_DATE,
       to_char(a.CREATED, 'yyyymmdd HH24:mi:ss') CREATED,
       a.PROFILE,
       a.DEFAULT_TABLESPACE
  FROM cdb_users a
  join v$containers b
    on a.CON_ID = b.CON_ID
 where ACCOUNT_STATUS not like  'EXPIRED%'
 --and  b.CON_ID > 4
 --and a.COMMON='NO'
 order by CON_ID;






set linesize 1000 pagesize 500
col username for a20
col account_status for a20
col default_tablespace for a20
col temporary_tablespace for a20
SELECT a.username,
       a.account_status,
       a.default_tablespace,
       a.temporary_tablespace
  FROM dba_users a
 WHERE a.account_status NOT like  ('EXPIRED%LOCKED')
   AND a.username NOT IN ('SYS', 'SYSTEM')
 ORDER BY 1;




COLUMN username                 format a10 heading User
COLUMN default_tablespace       format a12 heading Default
COLUMN temporary_tablespace     format a12 heading Temporary
COLUMN granted_role             format a25 heading Roles
COLUMN default_role             format a10 heading Default?
COLUMN admin_option             format a7  heading Admin?
COLUMN profile                  format a12 heading Profile

SELECT username,
       default_tablespace,
       temporary_tablespace,
       profile,
       granted_role,
       admin_option,
       default_role
  FROM sys.dba_users a, sys.dba_role_privs b
 WHERE a.username = b.grantee
 ORDER BY username,
          default_tablespace,
          temporary_tablespace,
          profile,
          granted_role;




----------------------------------------------角色权限

查询用户拥有哪里权限：
col GRANTEE for a30
col cmd for a80
col GRANTED_ROLE for a30
select a.GRANTEE,
       a.GRANTED_ROLE,
       a.ADMIN_OPTION,
       a.DEFAULT_ROLE,
       'grant ' || a.GRANTED_ROLE || ' to xjmon;' cmd
  from dba_role_privs a
 where a.GRANTEE = 'DBA';


col PRIVILEGE for a40
col cmd for a80
select a.GRANTEE,
       a.privilege,
       a.ADMIN_OPTION,
       'grant ' || a.privilege || ' to xjmon;' cmd
  from dba_sys_privs a
 where a.GRANTEE = 'DBA';

select a.grantee,
       a.owner,
       a.table_name,
       a.grantor,
       a.privilege,
       a.grantable,
       a.hierarchy,
       'grant ' || a.privilege || ' on ' || a.owner || '.' || a.table_name ||
       ' to xjmon;' cmd
  from DBA_TAB_PRIVS a
 where a.GRANTEE = 'XJMON';

select * from role_sys_privs ;
DBA_ROLE_PRIVS
DBA_SYS_PRIVS
DBA_TAB_PRIVS
ROLE_ROLE_PRIVS
ROLE_SYS_PRIVS
ROLE_TAB_PRIVS
------查询用户权限
col GRANTEE for a30
col GRANTED_ROLE for a30
SELECT * FROM dba_role_privs WHERE GRANTEE IN (upper('hosts'), upper('configs'), upper('syslog')) ORDER BY GRANTEE;
SELECT * FROM dba_sys_privs WHERE GRANTEE IN  (upper('C##BASIC')) ORDER BY GRANTEE;



grant EXECUTE ANY PROCEDURE,ALTER ANY PROCEDURE,DEBUG ANY PROCEDURE,debug connect session  to NHM;

select grantee,privilege from dba_sys_privs where grantee='TEST'    ;  
select grantee,granted_role from dba_role_privs where grantee='TEST'    ;
--查一个用户、角色关于表的权限(OWNER权限所有者)
SELECT DISTINCT GRANTEE, OWNER, TABLE_NAME, PRIVILEGE
  FROM DBA_TAB_PRIVS
 WHERE GRANTEE <> OWNER
   AND OWNER = 'CONFIGS'
  -- AND PRIVILEGE IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT')
   --AND GRANTEE = 'XJ'
  -- AND TABLE_NAME = 'SA_SO_OPERATOR'
 ORDER BY 1,2,3;


set linesize 140  pagesize 8000;
SELECT grantee,
       granted_role || ' (role)' "privilege",
       admin_option "admin",
       (SELECT ACCOUNT_STATUS
          FROM sys.dba_users a
         WHERE a.username = b.GRANTEE) account_status
  FROM sys.dba_role_privs b
 WHERE grantee NOT IN
       ('SYS', 'SYSTEM', 'TSMSYS', 'OUTLN', 'DBSNMP', 'DIP', 'WMSYS',
        'AQ_ADMINISTRATOR_ROLE', 'DBA', 'EXP_FULL_DATABASE',
        'IMP_FULL_DATABASE', 'OEM_ADVISOR', 'RECOVERY_CATALOG_OWNER',
        'REPADMIN', 'SCHEDULER_ADMIN', 'EXECUTE_CATALOG_ROLE', 'OEM_MONITOR',
        'LOGSTDBY_ADMINISTRATOR', 'SELECT_CATALOG_ROLE', 'CTXSYS', 'DMSYS',
        'EXFSYS', 'MDSYS', 'OLAPSYS', 'ORDSYS', 'XDB')
 GROUP BY grantee, granted_role || ' (role)', admin_option
UNION ALL
SELECT GRANTEE,
       PRIVILEGE,
       ADMIN_OPTION,
       (SELECT ACCOUNT_STATUS
          FROM sys.dba_users c
         WHERE c.username = d.GRANTEE)
  FROM sys.dba_sys_privs d
 WHERE grantee NOT IN
       ('SYS', 'SYSTEM', 'TSMSYS', 'OUTLN', 'DBSNMP', 'DIP', 'WMSYS',
        'AQ_ADMINISTRATOR_ROLE', 'DBA', 'EXP_FULL_DATABASE',
        'IMP_FULL_DATABASE', 'OEM_ADVISOR', 'RECOVERY_CATALOG_OWNER',
        'REPADMIN', 'SCHEDULER_ADMIN', 'EXECUTE_CATALOG_ROLE', 'OEM_MONITOR',
        'LOGSTDBY_ADMINISTRATOR', 'SELECT_CATALOG_ROLE', 'CTXSYS', 'DMSYS',
        'EXFSYS', 'MDSYS', 'OLAPSYS', 'ORDSYS', 'XDB')
 ORDER BY 4 DESC, 1, 2;


系统预定义角色：
#####CONNECT,/RESOURCE, DBA
这些预定义角色主要是为了向后兼容。其主要是用于数据库管理。oracle建议用户自己设计数据库管理和安全的权限规划，而不要简单的使用这些预定角色。将来的版本中这些角色可能不会作为预定义角色。
 
##DELETE_CATALOG_ROLE/EXECUTE_CATALOG_ROLE/SELECT_CATALOG_ROLE
这些角色主要用于访问数据字典视图和包。
 
##EXP_FULL_DATABASE/IMP_FULL_DATABASE
这两个角色用于数据导入导出工具的使用。

视图：role_sys_privs

角色管理：
建一个角色：create role role1;
授权给角色：grant create any table,create procedure to role1;
授予角色给用户：grant role1 to user1;
查看角色所包含的权限：select * from role_sys_privs;
创建带有口令以角色(在生效带有口令的角色时必须提供口令)：
create role role1 identified by password1;
修改角色：是否需要口令
alter role role1 not identified;
alter role role1 identified by password1;
修改指定用户，设置其默认角色：
alter user user1 default role role1;
alter user user1 default role all except role1;

删除角色：drop role role1;
角色删除后，原来拥用该角色的用户就不再拥有该角色了，相应的权限也就没有了。
说明:
1、无法使用WITH GRANT OPTION为角色授予对象权限
2、可以使用WITH ADMIN OPTION 为角色授予系统权限,取消时不是级联

alter user xjmon  Default Tablespace MGMT_TABLESPACE Temporary Tablespace temp;




SELECT 'alter user ' || username || ' profile app_user;'
  FROM dba_users
 WHERE profile = 'DEFAULT'
   AND ACCOUNT_STATUS = 'OPEN'
 GROUP BY username, profile;


----profile  

select * from dba_profiles where PROFILE='DEFAULT';
select * from dba_profiles where PROFILE='PROFILE_MONITOR';
-------profile相关参数说明



-------创建profile
create PROFILE app_user LIMIT
  FAILED_LOGIN_ATTEMPTS unlimited
   PASSWORD_LIFE_TIME unlimited
   PASSWORD_REUSE_TIME unlimited
   PASSWORD_REUSE_MAX unlimited
   PASSWORD_LOCK_TIME unlimited
   PASSWORD_GRACE_TIME unlimited;

set linesize 1000 pagesize 500

select PROFILE,RESOURCE_NAME,RESOURCE_TYPE,LIMIT from dba_profiles order by PROFILE,RESOURCE_NAME;

set linesize 1000 pagesize 5000
col LIMIT_cmd for a70
SELECT 'ALTER PROFILE ' || a.profile || ' LIMIT ' || a.resource_name ||
       ' UNLIMITED;' LIMIT_cmd
  FROM dba_profiles a,
       (SELECT PROFILE FROM dba_users WHERE ACCOUNT_STATUS = 'OPEN' group by PROFILE) b
 WHERE a.PROFILE = b.profile
   AND a.resource_name IN ('PASSWORD_LIFE_TIME', 'FAILED_LOGIN_ATTEMPTS')
   AND a.limit NOT IN ('UNLIMITED', 'DEFAULT')
 ORDER BY a.profile;


-----创建密码强度函数
@?/rdbms/admin/utlpwdmg.sql    -----创建密码函数，会生成一下几个密码验证函数
ora12c_verify_function(oracle  database 12c)
ora12c_strong_verify_function(密码强度非常高,oracle  database 12c)
verify_function_11G (oracle  database 11g)
verify_function(oracle  database 10g)


--------设置密码不区分大小写
sec_case_sensitive_logon=false



------设置数据库资源限制参数
resource_limit=true


-----------------------输出用户对象的依赖关系
UNDEFINE owner
SET LINESIZE 132 PAGESIZE 0 VERIFY OFF FEEDBACK OFF TIMING OFF
SPO dep_dyn_&&owner..sql
SELECT 'SPO dep_dyn_&&owner..txt' FROM DUAL;
--
SELECT 'PROMPT ' || '_____________________________' || CHR(10) || 'PROMPT ' ||
       object_type || ': ' || object_name || CHR(10) || 'SELECT ' || '''' || '+' || '''' || ' ' ||
       '|| LPAD(' || '''' || ' ' || '''' || ',level+3)' || CHR(10) ||
       ' || type || ' || '''' || ' ' || '''' || ' || owner || ' || '''' || '.' || '''' ||
       ' || name' || CHR(10) || ' FROM dba_dependencies ' || CHR(10) ||
       ' CONNECT BY PRIOR owner = referenced_owner AND prior name = referenced_name ' ||
       CHR(10) || ' AND prior type = referenced_type ' || CHR(10) ||
       ' START WITH referenced_owner = ' || '''' || UPPER('&&owner') || '''' ||
       CHR(10) || ' AND referenced_name = ' || '''' || object_name || '''' ||
       CHR(10) || ' AND owner IS NOT NULL;'
  FROM dba_objects
 WHERE owner = UPPER('&&owner')
   AND object_type NOT IN ('INDEX', 'INDEX PARTITION', 'TABLE PARTITION');
--
SELECT 'SPO OFF' FROM dual;
SPO OFF
SET VERIFY ON LINESIZE 80 FEEDBACK ON





---------------用户错误登陆记录，开启审计有效
set linesize 500 pagesize 500
col  username  for a20
col  os_username for a20
col    CLIENT_ID for a20
col USERHOST for a20
col client_id for a10

SELECT username,
       os_username,
       userhost,
       client_id,
       to_char(TIMESTAMP,'yyyy-mm-dd hh24:mi') TIMESTAMP,
       COUNT(*) failed_logins
  FROM dba_audit_trail
 WHERE returncode = 1017
   AND --1017 is invalid username/password
       TIMESTAMP > SYSDATE - 1
 GROUP BY username, os_username, userhost, client_id, to_char(TIMESTAMP,'yyyy-mm-dd hh24:mi')
 --having COUNT(*)>30
 ORDER BY TIMESTAMP DESC;


------------系统用户
用户 密码 关键性 作用 
system manager YES 为DBA创建的SYSTEM用户 
sys cHAnge_on_install YES 拥有数据字典表和视图的SYS用户 
scott tiger NO 检测模式，ORACLE参考模式 
internal oracle YES SYS的别称，并非真正用户 
DEMO DEMO NO 检测模式，ORACLE参考模式 
dbsnmp dbsnmp no 企业管理器的管理人员你 
OUTLN OUTLN YES 存储行输出 
MISSYS MISSYS NO 由ORACLE SERVICE 使用 
AURORA... N/A YES 数据库注册 
ORdplugins ordplugins no 供ORACLE 使用的内部媒体 
CTXSYS CTXSYS NO 供ORACLE 使用的内部媒体 
ORDSYS ORDSYS NO 供ORACLE 使用的内部媒体 
MDSYS MDSYS NO 供ORACLE 使用的内部媒体

