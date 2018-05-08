
create table xj_tab_paas_amp_tbs as 
select trunc(sysdate) collect_date,
       b.dbname,
       decode(b.bmark, null, b.bname, b.bmark) bmark,
       a.MIN_CREATION_TIME  CREATION_TIME,
       a.HAVE_SEGS HAVE_SEGS,
       round(a.SIZE_KB / 1024 / 1024, 2) size_gb,
       round((a.SIZE_KB - a.FREE_KB) / 1024 / 1024, 2) used_gb
  from XJ_TAB_PAAS_TBS_NOW a, xjmon.XJ_TAB_PAAS_TBS b
 where a.DBNAME = upper(b.dbname)
       and a.TABLESPACE_NAME = b.tbs_name



delete from xj_tab_paas_amp_tbs where collect_date =trunc(sysdate);


df -h

cd /archive/dumpdir/

--建操作系统用户
# useradd zcdcpp -d /archive/dumpdir/zcdcpp_dir
# passwd zcdcpp


添加.bash_profile内容
cat /home/oracle/.bash_profile
$ su - zcdw
$ vi .bash_profile
#use for oracle
export ORACLE_BASE=/opt/oracle/db
export ORACLE_HOME=$ORACLE_BASE/product
export PATH=$PATH:$ORACLE_HOME/bin
export ORACLE_SID=bjpaasb3
export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
umask 022

cat /home/oracle/.bash_profile  >/archive/dumpdir/zcdcpp_dir/.bash_profile


$ source .bash_profile

修改用户主目录权限和属组
# cd /archive/dumpdir
# chown  zcdw:oinstall /ora/archive/zcdw
# chmod  775 /ora/archive/zcdw

--建数据文件目录（oracle用户执行，优先使用空闲率高的共享挂载点）
$ mkdir /ora/oradata01/zcdw_ccms
$ ll

--建service（主1备3）
$ srvctl add service -d xspaasa -s zcsjbc_srv  -r xspaasa2 -a xspaasa3 -P basic -m basic -z 10 -e select
$ srvctl start service -d xspaasa -s zcdw_ccms_srv
$ srvctl status service -d xspaasa -s zcdw_ccms_srv


srvctl modify service -d sqpaasb -s zc_ccms  -r sqpaasb2,sqpaasb3

srvctl add service -d sqpaasb -s zc_ccms1  -r sqpaasa2,sqpaasa3 -P basic -m basic -z 10 -e select

srvctl remove service -d sqpaasa -s zc_ccms -f
srvctl add service -d sqpaasa -s zc_ccms  -r sqpaasa2,sqpaasa3 -P basic -m basic -z 10 -e select
srvctl start service -d sqpaasa -s zc_ccms
srvctl status service -d sqpaasa -s zc_ccms

--建业务表空间
create tablespace zcdw_data  datafile '/oradata2/zzyw_yjshv/zz_yjshv_data01.dbf' size 30G autoextend off;
alter tablespace  zz_yjshv_data add datafile '/oradata2/zzyw_yjshv/zz_yjshv_data02.dbf' size 30G autoextend off;



sqlplus -S  "/as sysdba" <<EOF
select count(*) from dvsys.vpd;
exit;
EOF




iptvmem	Vtpimem_2012	iptvmem
create user iptvmem  identified by Vtpimem_2012  default tablespace iptvmem  quota unlimited on iptvmem  profile MONITORING_PROFILE;


--建数据库用户
create user zcdw_ccms  identified by "Ccms!234" default tablespace zzmbpay_CMCCPAY  quota unlimited on zzmbpay_CMCCPAY  profile paas;
create user zcdw_zznode  identified by "Zznode!234"  default tablespace zzmbpay_CMCCPAY  quota unlimited on zzmbpay_CMCCPAY  profile paas;


建directory
create directory dump_dir  as '/oradata/dump_dir';

grant basic to zzyw_yjshv;
grant all on directory dump_dir to public;


alter user zzyw_nlxh  quota unlimited on zznlxh_index;

zzmbpay_cmccpay、zzmbpay_posp、zzmbpay_UCMPPLAT、zzmbpay_UCMPFILE、zzmbpay_uposp、zzmbpay_mblpay、zzmbpay_mblusr

col OWNER for a20
col DIRECTORY_NAME for a30
col DIRECTORY_PATH for a70
set linesize 1000 pagesize 5000
select OWNER, DIRECTORY_NAME, DIRECTORY_PATH
  from DBA_DIRECTORIES
 where 1 = 1
       --and DIRECTORY_NAME = upper('yjshv_dir')
       --and DIRECTORY_PATH like '%/archive/dumpdir/zz_mbpay%'
       ;

create user ll identified by oracle account unlock ;
 


grant all on directory DLDGMBMS_DIR to dxjk;




sqlplus /nolog
conn zzyw_nlxh/"nlxh_2016"
conn hk_139site_tssite/"!QAZ2wsx"

[oracle@zjhz-bjpaasb3 ~]$ sqlplus /nolog
SQL*Plus: Release 11.2.0.4.0 Production on Wed Feb 24 13:06:14 2016
Copyright (c) 1982, 2013, Oracle.  All rights reserved.
SQL> conn hk_139site_tsmange/"!QAZ2wsx"
Connected.
SQL> conn hk_139site_tssite/"!QAZ2wsx"
Connected.
SQL> 






-------关闭数据文件自动扩展
set lines 132 pages 1000 
select 'alter database datafile '''||a.file_name ||''' autoextend off;' from cdb_data_files a,dba_tablespaces b where a.TABLESPACE_NAME=b.TABLESPACE_NAME and a.AUTOEXTENSIBLE='YES' and b.BIGFILE='NO'
union all
select 'alter database tempfile '''||a.file_name ||''' autoextend off;' from cdb_TEMP_FILES a,dba_tablespaces b where a.TABLESPACE_NAME=b.TABLESPACE_NAME and a.AUTOEXTENSIBLE='YES' and b.BIGFILE='NO';






create or replace view  c##xjmon.xj_v_paas_tbs_msg as 
select distinct tbs.*,f.free_kb,
                decode(s.tablespace_name, null, 'N/A', s.tablespace_name) have_segs
  from (select (select name as dbname from v$database) dbname,
               con.NAME as pdbname,
               con.CON_ID,
               a.TABLESPACE_NAME,
               min(b.CREATION_TIME) min_CREATION_TIME,
               max(b.CREATION_TIME) max_CREATION_TIME,
               sum(a.BYTES) / 1024 size_kb
          from cdb_data_files a
          join v$datafile b
            on a.FILE_ID = b.FILE#
               and a.CON_ID = b.CON_ID
          join v$containers con
            on a.CON_ID = con.CON_ID
         where a.tablespace_name not like '%UNDOTBS%'
         group by con.name, con.CON_ID, a.TABLESPACE_NAME) tbs
  join (select tablespace_name, CON_ID,sum(bytes) / 1024 free_kb
          from cdb_free_space
         group by tablespace_name, CON_ID) f
    on  tbs.tablespace_name = f.tablespace_name
       and tbs.CON_ID = f.CON_ID
  left join cdb_segments s
    on tbs.tablespace_name = s.tablespace_name
       and tbs.CON_ID = s.CON_ID;














create or replace view  xjmon.xj_v_paas_tbs_msg as 
select distinct tbs.*,
                f.free_kb,
                decode(s.tablespace_name, null, 'N/A', s.tablespace_name) have_segs
  from (select (select name as dbname from v$database) dbname,
               'N/A' as pdbname,
               a.TABLESPACE_NAME,
               min(b.CREATION_TIME) min_CREATION_TIME,
               max(b.CREATION_TIME) max_CREATION_TIME,
               sum(a.BYTES) / 1024 size_kb
          from dba_data_files a
          join v$datafile b
            on a.FILE_ID = b.FILE#
         where a.tablespace_name not like '%UNDOTBS%'
         group by a.TABLESPACE_NAME) tbs
  join (select tablespace_name, sum(bytes) / 1024 free_kb
          from dba_free_space
         group by tablespace_name) f
    on tbs.tablespace_name = f.tablespace_name
  left join dba_segments s
    on tbs.tablespace_name = s.tablespace_name;
    
select count(*)  from dba_segments s where s.tablespace_name='FCTAIS_DAT';

set timing on
set linesize 1000 pagesize 5000
select * from  xjmon.xj_v_paas_tbs_msg;  
    



CREATE MATERIALIZED VIEW xjmon.xj_mv_paas_tbs_msg_sqpd
REFRESH COMPLETE ON DEMAND
START WITH TO_DATE('02-03-2016 11:25:08', 'DD-MM-YYYY HH24:MI:SS') NEXT SYSDATE+1/6  
AS select * from c##xjmon.xj_v_paas_tbs_msg@xj_topaas_sqpd;




create or replace view xjmon.XJ_V_PAAS_TBS_MSG_all as 
 select dbname,
        pdbname,
        tablespace_name,
        min_creation_time,
        max_creation_time,
        size_kb,
        free_kb,
        have_segs
   from (select *
           from XJ_MV_PAAS_TBS_MSG_BJPA
         union all
         select *
           from XJ_MV_PAAS_TBS_MSG_BJPB
         union all
         select *
           from XJ_MV_PAAS_TBS_MSG_SQPA
         union all
         select *
           from XJ_MV_PAAS_TBS_MSG_SQPB
         union all
         select *
           from XJ_MV_PAAS_TBS_MSG_SQPC
         union all
         select dbname,
                pdbname,
                tablespace_name,
                min_creation_time,
                max_creation_time,
                size_kb,
                free_kb,
                have_segs
           from xj_mv_paas_tbs_msg_sqpd
         union all
         select *
           from XJ_MV_PAAS_TBS_MSG_SQPE);











/*数据库目标*/
10.212.211.5
service_name：emrep
sid：emrep
xjmon/xjmon_321
------------数据采集
select * from xjmon.XJ_V_PAAS_TBS_MSG_ALL;
select * from xjmon.XJ_V_PAAS_sysmetric_all


-----------Paas表空间数据库空间分配及利用情况
--5.1、总体空间使用率
select t.dbname,
       round(sum(t.size_kb) / 1024 / 1024) size_gb,
       round(sum(t.size_kb - t.free_kb) / 1024 / 1024) used_gb
  from xjmon.XJ_V_PAAS_TBS_MSG_ALL t
 group by t.dbname
 order by used_gb / size_gb desc;

------分业务空间利用情况
--5.2、各平台空间利用
select a.pname,
       a.sname,
       round(sum(b.size_kb) / 1024 / 1024) size_gb,
       round(sum(b.size_kb - b.free_kb) / 1024 / 1024) used_gb
  from (select distinct tbs_name, pname, sname
          from xjmon.XJ_T_PAAS_TBS_ALLOC) a,
       xjmon.XJ_V_PAAS_TBS_MSG_ALL b
 where a.tbs_name = b.tablespace_name
       and upper(a.pname) = b.dbname
       and a.pname not in ('BJPAASA1', 'SQPAASC', 'SQPAASE1','SQPAASD')
 group by a.pname, a.sname
 order by a.pname, (used_gb / size_gb) desc;


---------------表空间分配时间超过60天，使用率低于10%的表空间信息
--5.3低空间利用明细
select alloc.pname,
       alloc.sname,
       alloc.tbs_name,
       to_char(b.min_creation_time,'yyyy-mm-dd') creation_time,
       round(sum(b.size_kb) / 1024 ) size_mb,
       round(sum(b.size_kb - b.free_kb) / 1024 ) used_mb
  from (select distinct tbs_name, pname, sname
          from xjmon.XJ_T_PAAS_TBS_ALLOC) alloc,
       xjmon.XJ_V_PAAS_TBS_MSG_ALL b
 where alloc.tbs_name = b.tablespace_name
       and upper(alloc.pname) = b.dbname
       and b.min_creation_time <= sysdate - 60
       and (b.free_kb / b.size_kb) >= 0.9
       and alloc.pname not in ('BJPAASA1', 'SQPAASC', 'SQPAASE1','SQPAASD','BJPAASB','SQPAASA')
 group by alloc.pname, alloc.sname, alloc.tbs_name,min_creation_time
 order by sname,(used_mb/size_mb) ;
--低空间利用汇总
select alloc.pname,
       count(*) cnt,
       round(sum(b.size_kb) / 1024 / 1024) size_gb,
       round(sum(b.free_kb) / 1024 / 1024) free_gb
  from (select distinct tbs_name, pname, sname
          from xjmon.XJ_T_PAAS_TBS_ALLOC) alloc,
       xjmon.XJ_V_PAAS_TBS_MSG_ALL b
 where alloc.tbs_name = b.tablespace_name
       and upper(alloc.pname) = b.dbname
       and b.min_creation_time <= sysdate - 60
       and (b.free_kb / b.size_kb) >= 0.9
       and alloc.pname not in ('BJPAASA1', 'SQPAASC', 'SQPAASE1','SQPAASD','BJPAASB','SQPAASB')
 group by alloc.pname
 order by pname,(free_gb/size_gb) desc;


--------------表空间分配时间超过60天且未分配任何段的表空间信息
--5.4未分配段表空间明细
select --alloc.pname,
       alloc.sname,
       alloc.tbs_name,
       to_char(b.min_creation_time,'yyyy-mm-dd') creation_time,
       round(sum(b.size_kb) / 1024/1024) size_gb
  from (select distinct tbs_name, pname, sname
          from xjmon.XJ_T_PAAS_TBS_ALLOC) alloc,
       xjmon.XJ_V_PAAS_TBS_MSG_ALL b
 where alloc.tbs_name = b.tablespace_name
       and upper(alloc.pname) = b.dbname
       and b.have_segs = 'N/A'
       and b.min_creation_time <= sysdate - 60
       and alloc.pname not in ('BJPAASA1', 'SQPAASC', 'SQPAASE1','SQPAASD','BJPAASB','SQPAASA')
 group by alloc.pname, alloc.sname, alloc.tbs_name,min_creation_time
 order by alloc.sname;


------------------历史性能数据主要指标（I/O response from sequential read,Session Limit %,Process Limit %,Host CPU Utilization (%)）
----Session Limit %,Process Limit %,Host CPU Utilization (%)
select a.DBNAME,
       a.SNAP_ID,
       to_char(a.END_INTERVAL_TIME,'yymmddhh24mi') END_INTERVAL_TIME,
       max(case
             when a.METRIC_NAME = 'Host CPU Utilization (%)' then
              a.AVERAGE
             else
              null
           end) Host_CPU,
       max(case
             when a.METRIC_NAME = 'Session Limit %' then
              a.AVERAGE
             else
              null
           end) SLimit,
       max(case
             when a.METRIC_NAME = 'Process Limit %' then
              a.AVERAGE
             else
              null
           end) PLimit
  from xjmon.XJ_V_PAAS_sysmetric_all a   
 where a.METRIC_NAME in
       ('Host CPU Utilization (%)', 'Session Limit %', 'Process Limit %'，'I/O response from sequential read')
       and a.DBNAME = 'SQPAASA'
       and a.INSTANCE_NUMBER = 1
 group by a.DBNAME, a.SNAP_ID, a.END_INTERVAL_TIME
 order by SNAP_ID;

------数据库IO响应
select a.DBNAME,
       a.SNAP_ID,
       to_char(a.END_INTERVAL_TIME,'yymmddhh24mi') END_INTERVAL_TIME,
       max(case
             when a.INSTANCE_NUMBER = 1 then
              a.AVERAGE
             else
              null
           end) inst1_io,
       max(case
             when a.INSTANCE_NUMBER = 2 then
              a.AVERAGE
             else
              null
           end) inst2_io,
       max(case
             when a.INSTANCE_NUMBER = 3 then
              a.AVERAGE
             else
              null
           end) inst3_io
  from xjmon.XJ_V_PAAS_sysmetric_all a
 where a.METRIC_NAME in ('I/O response from sequential read')
       and a.DBNAME = 'SQPAASA'
--and a.INSTANCE_NUMBER = 3
 group by a.DBNAME, a.SNAP_ID, a.END_INTERVAL_TIME
 order by SNAP_ID;



select to_char(END_INTERVAL_TIME, 'yymmddhh24mi') END_INTERVAL_TIME,
       Host_CPU,
       SLimit,
       PLimit
  from (select a.DBNAME,
               a.SNAP_ID,
               a.END_INTERVAL_TIME,
               a.METRIC_NAME,
               a.AVERAGE
          from xjmon.XJ_V_PAAS_sysmetric_all a
         where a.METRIC_NAME in ('Host CPU Utilization (%)',
                                 'Session Limit %',
                                 'Process Limit %')
               and a.DBNAME = 'BJPAASB'
               and a.INSTANCE_NUMBER = 3)
pivot(max(AVERAGE)
   for METRIC_NAME in('Host CPU Utilization (%)' as Host_CPU,
                      'Session Limit %' as SLimit,
                      'Process Limit %' as PLimit))
 order by snap_id;


select to_char(END_INTERVAL_TIME, 'yymmddhh24mi') END_INTERVAL_TIME,
       inst1_io,
       inst2_io,
       inst3_io
  from (select a.DBNAME,
               a.SNAP_ID,
               a.END_INTERVAL_TIME,
               a.INSTANCE_NUMBER,
               a.AVERAGE
          from xjmon.XJ_V_PAAS_sysmetric_all a
         where a.METRIC_NAME in ('I/O response from sequential read')
               and a.DBNAME = 'BJPAASB'
               )
pivot(max(AVERAGE)
   for INSTANCE_NUMBER in('1' as inst1_io,
                      '2' as inst2_io,
                      '3' as inst3_io))
 order by snap_id;


















select date_formate
































-------------------------12c表空间
set linesize 1000 pagesize 500
col tablespace_name for a25
col name for a20
SELECT con.CON_ID,
       con.name,
       df.tablespace_name,
       COUNT(*) df_count,
       ROUND(SUM(df.BYTES) / 1048576 / 1024, 4) size_gb,
       ROUND(SUM(free.BYTES) / 1048576 / 1024, 4) free_gb,
       ROUND(SUM(df.BYTES) / 1048576 / 1024 -
             SUM(free.BYTES) / 1048576 / 1024,
             4) used_gb,
       ROUND(MAX(free.maxbytes) / 1048576 / 1024, 4) maxfree,
       100 - ROUND(100.0 * SUM(free.BYTES) / SUM(df.BYTES), 2) pct_used,
       ROUND(100.0 * SUM(free.BYTES) / SUM(df.BYTES), 2) pct_free
  FROM cdb_data_files df,
       (SELECT CON_ID,
               tablespace_name,
               SUM(BYTES) BYTES,
               MAX(BYTES) maxbytes
          FROM cdb_free_space
         WHERE bytes > 1024 * 1024
         GROUP BY CON_ID, tablespace_name) free,
       v$containers con
 WHERE df.tablespace_name = free.tablespace_name(+)
   AND df.CON_ID = free.CON_ID
   AND df.CON_ID = con.CON_ID
 GROUP BY con.CON_ID,con.name, df.tablespace_name
 ORDER BY 1, 9 desc;


--------------paas 表空间分配流水信息
XJ_T_PAAS_ALLOC_tbs


--------------paas用户分配流水信息
xj_t_paas_alloc_users




------通过GC查询主机性能数据
select *
  from (select collect_time, COLUMN_LABEL, VALUE_AVERAGE
          from (select to_char(M1.ROLLUP_TIMESTAMP, 'yyyy-mm-dd hh24:mi') collect_time,
                       M.COLUMN_LABEL,
                       round(M1.VALUE_AVERAGE, 2) VALUE_AVERAGE
                  from MGMT_METRICS_1HOUR M1,
                       MGMT_METRICS       M,
                       MGMT_TARGETS       T,
                       MGMT_TARGET_TYPES  TT
                 where M1.METRIC_GUID = M.METRIC_GUID
                   and m1.target_guid = t.target_guid
                   and TT.TARGET_TYPE = T.TARGET_TYPE
                   and T.TARGET_TYPE = M.TARGET_TYPE
                   and T.TYPE_META_VER = M.TYPE_META_VER
                   AND (t.category_prop_1 = m.category_prop_1 OR
                       m.category_prop_1 = ' ')
                   AND (t.category_prop_2 = m.category_prop_2 OR
                       m.category_prop_2 = ' ')
                   AND (t.category_prop_3 = m.category_prop_3 OR
                       m.category_prop_3 = ' ')
                   AND (t.category_prop_4 = m.category_prop_4 OR
                       m.category_prop_4 = ' ')
                   and (T.CATEGORY_PROP_5 = M.CATEGORY_PROP_5 or
                       M.CATEGORY_PROP_5 = ' ')
                   and t.host_name = 'zjhz-bjpaasb1'
                   and T.TARGET_TYPE in ('host', 'oracle_database')
                   and M.COLUMN_LABEL in
                       ('CPU Utilization (%)',
                        'Memory Utilization (%)',
                        'Process Limit Usage (%)',
                        'Session Limit Usage (%)')
                   and m1.rollup_timestamp >=
                       trunc(to_date('2016-01-01 00:00:00',
                                     'yyyy-mm-dd hh24:mi:ss'))))
pivot(sum(VALUE_AVERAGE)
   for COLUMN_LABEL in('CPU Utilization (%)' as cpu_used,
                       'Memory Utilization (%)' as mem_used,
                       'Process Limit Usage (%)' as proc_used,
                       'Session Limit Usage (%)' as sess_used))
 order by collect_time ;


DBA_HIST_SYSMETRIC_SUMMARY


 select * from DBA_HIST_METRIC_NAME a where a.metric_name like '%\%%' escape'\'


Session Limit %
Process Limit %
Host CPU Utilization (%)







--------------采集数据库cpu信息
select to_char(END_TIME, 'yyyy-mm-dd hh24:mi:ss') BEGIN_TIME,
       METRIC_NAME,
       round(MINVAL, 2),
       round(MAXVAL, 2),
       round(AVERAGE, 2)
  from dba_hist_sysmetric_summary
 where INSTANCE_NUMBER = 1
   and METRIC_NAME like 'Host CPU Utilization (%)'
   and BEGIN_TIME >=
       trunc(to_date('2016-01-13 00:00:00', 'yyyy-mm-dd hh24:mi:ss'))
 order by SNAP_ID;

V$SYSMETRIC
V$SYSMETRIC_HISTORY     DBA_HIST_SYSMETRIC_HISTORY
V$SYSMETRIC_SUMMARY     DBA_HIST_SYSMETRIC_SUMMARY

dba_hist_sysmetric_summary 




/*PaaS未分配任何段的表空间*/

create or replace view xjmon.xj_v_bjpb_noseg as 
select s.dbname,
       s.dbid,
       t.tablespace_name,
       t.CREATION_TIME,
       t.size_gb
  from (select name as dbname, dbid from v$database) s,
       (select distinct a.TABLESPACE_NAME,
                        min(b.CREATION_TIME) over(partition by a.TABLESPACE_NAME) CREATION_TIME,
                        round((sum(a.BYTES)
                               over(partition by a.TABLESPACE_NAME)) / 1024 / 1024 / 1024,
                              2) size_gb
          from dba_data_files a, v$datafile b
         where a.FILE_ID = b.FILE#) t
 where t.TABLESPACE_NAME not in (select tablespace_name from dba_segments)
   and t.TABLESPACE_NAME not in
       (select tablespace_name from dba_temp_files);




SELECT TABLESPACE_NAME, BYTES/1024
  FROM dba_free_space
 GROUP BY tablespace_name

set linesize 1000 pagesize 500
col TABLESPACE_NAME for a30
col DBNAME for a10
col SNAME for a30
select a.dbname,
       a.tablespace_name,
       to_char(a.creation_time, 'yyyy-mm-dd hh24:mi:ss') as creation_time,
       a.size_gb,
       alloc.sname
  from (select *
          from xjmon.xj_v_sqpa_noseg@xj_topaas_sqpa
        union all
        select *
          from xjmon.xj_v_sqpb_noseg@xj_topaas_sqpb
        union all
        select *
          from xjmon.xj_v_bjpb_noseg@xj_topaas_bjpb) a,
       xjmon.XJ_T_PAAS_TBS_ALLOC alloc
 where a.tablespace_name = alloc.tbs_name
   and a.dbname = alloc.pname
   and a.creation_time < sysdate - 60
 order by dbname, sname, size_gb desc;


/*统计石桥paasa、石桥paasb、滨江paasb 表空间分配时间超过60tian ，但是使用率低于15%的表空间信息*/

create or replace view xjmon.xj_v_bjpc_tbsstat as 
select s.dbname,
       s.dbid,
       s.tablespace_name,
       t.CREATION_TIME,
       t.size_gb,
       s.free_gb
  from (select a.dbname, a.dbid, b.TABLESPACE_NAME, b.free_gb
          from (SELECT TABLESPACE_NAME,
                       round(SUM(BYTES) / 1024 / 1024 / 1024, 2) free_gb
                  FROM dba_free_space
                 GROUP BY tablespace_name) b,
               (select name as dbname, dbid from v$database) a) s,
       (select distinct a.TABLESPACE_NAME,
                        min(b.CREATION_TIME) over(partition by a.TABLESPACE_NAME) CREATION_TIME,
                        round((sum(a.BYTES)
                               over(partition by a.TABLESPACE_NAME)) / 1024 / 1024 / 1024,
                              2) size_gb
          from dba_data_files a, v$datafile b
         where a.FILE_ID = b.FILE#) t
 where s.TABLESPACE_NAME = t.tablespace_name;

grant connect to xjmon;
grant resource to xjmon;
grant execute on dbms_flashback to xjmon;
grant select any table to xjmon;
grant create database link to xjmon;
grant UNLIMITED TABLESPACE to xjmon;
grant EXECUTE ANY PROCEDURE to xjmon;
grant SELECT ANY DICTIONARY to xjmon; 
grant  create view to xjmon;



set linesize 200
set pagesize 10000
col tablespace_name format a30
col dbname format a10
col free_gb format 9999.99
col size_gb  format 9999.99
col pct_free format 999.99
col creation_time for a25
col  sname for a30

select a.dbname,
       a.tablespace_name,
       to_char(a.creation_time, 'yyyy-mm-dd hh24:mi:ss') creation_time,
       a.size_gb,
       a.free_gb,
       round((a.free_gb / a.size_gb)*100,2) pct_free,
       alloc.sname
  from (select *
          from xjmon.xj_v_sqpa_tbsstat@xj_topaas_sqpa
        union all
        select *
          from xjmon.xj_v_sqpb_tbsstat@xj_topaas_sqpb
        union all
        select *
          from xjmon.xj_v_bjpb_tbsstat@xj_topaas_bjpb) a,
       xjmon.XJ_T_PAAS_TBS_ALLOC alloc
 where a.tablespace_name = alloc.tbs_name
   and a.dbname = alloc.pname
   and a.creation_time < sysdate - 60
   and (a.free_gb / a.size_gb) >= 0.9
 order by dbname, sname, size_gb desc;


with tab_temp as
 (select a.dbname,
         a.tablespace_name,
         to_char(a.creation_time, 'yyyy-mm-dd hh24:mi:ss') creation_time,
         a.size_gb,
         a.free_gb,
         round((a.free_gb / a.size_gb) * 100, 2) pct_free,
         alloc.sname
    from (select *
            from xjmon.xj_v_sqpa_tbsstat@xj_topaas_sqpa
          union all
          select *
            from xjmon.xj_v_sqpb_tbsstat@xj_topaas_sqpb
          union all
          select *
            from xjmon.xj_v_bjpb_tbsstat@xj_topaas_bjpb) a,
         xjmon.XJ_T_PAAS_TBS_ALLOC alloc
   where a.tablespace_name = alloc.tbs_name
     and a.dbname = alloc.pname
     and a.creation_time < sysdate - 60
     and (a.free_gb / a.size_gb) >= 0.9)
select distinct dbname,
       count(*) over(partition by dbname) cnt1,
       sum(size_gb) over(partition by dbname) size_gb,
       sum(free_gb) over(partition by dbname) free_gb
  from tab_temp;

/*统计PaaS数据库全库空间分配情况（基于空间流水资源表）*/
set linesize 1000 pagesize 200
col TARGET_NAME for a20
col target_type for  a20
col alloc_GB for 99999.99
col used_GB for 99999.99
select target_name,
       --target_type,
       round(sum(TABLESPACE_SIZE) / 1024 / 1024 / 1024, 2) alloc_GB,
       round(sum(TABLESPACE_USED_SIZE) / 1024 / 1024 / 1024, 2) used_GB
  from MGMT$DB_TABLESPACES_ALL a
 where a.target_name in
       (select distinct lower(pname) dbname
          from xjmon.XJ_T_PAAS_TBS_ALLOC)
          and target_name not in ('sqpaasd'/*,'sqpaase1','bjpaasa1','sqpaasc'*/)
 group by a.target_name, a.target_type
 order by 1;


select a.dbname,
       round(sum(a.size_kb) / 1024 / 1024, 2) alloc_GB,
       round(sum(a.size_kb - a.free_kb) / 1024 / 1024, 2) used_GB
  from xjmon.XJ_V_PAAS_TBS_MSG_ALL a
 group by a.dbname



/*分业务统计空间使用情况（需要实施更新资源分配流水表）*/
set linesize 1000 pagesize 500
col sname for a40
col db_name for a10
select db_name, sname, sum_gb, user_gb
  from (with tbs_temp as (select lower(a.pname) db_name,
                                 a.sname,
                                 a.tbs_name,
                                 sum(a.tbs_size) size_gb
                            from xjmon.XJ_T_PAAS_TBS_ALLOC a
                           where lower(a.pname) not in ('sqpaasd',
                                                  'sqpaase1',
                                                  'bjpaasa1',
                                                  'sqpaasc')
                           group by a.pname, a.sname, a.tbs_name)
         select a.db_name,
                a.sname,
                round(sum(b.TABLESPACE_SIZE), 2) / 1024 / 1024 / 1024 as sum_gb,
                round((sum(b.TABLESPACE_USED_SIZE) / 1024 / 1024 / 1024), 2) as user_gb,
                round((sum(b.TABLESPACE_USED_SIZE) / 1024 / 1024 / 1024), 2) /
                (round(sum(b.TABLESPACE_SIZE), 2) / 1024 / 1024 / 1024) pct_used
           from tbs_temp a, sysman.MGMT$DB_TABLESPACES_ALL b
          where a.db_name = b.target_name
            and a.tbs_name = b.tablespace_name
          group by a.db_name, a.sname)
          order by 1, pct_used desc;
          










---------------------------------------PAAS 查询特定用户表空间使用情况
set linesize 1000 pagesize 500
col tablespace_name for a30
with free_space as
 (SELECT tablespace_name, file_id, SUM(BYTES) BYTES, MAX(BYTES) maxbytes
    FROM dba_free_space
   where bytes > 1024 * 1024
   GROUP BY tablespace_name, file_id),
tablespace_name as
 (select distinct TABLESPACE_NAME
    from dba_segments
   where OWNER in ('UIMPDB',
                   'IWEB',
                   'ADMIN',
                   'ZQ_CYYW',
                   'HKJTCY_HOSTING_ADMIN',
                   'PORTA',
                   'hkjtcy_aepemcdb',
                   'hkjtcy_bfmdb',
                   'hkjtcy_bfmsso'))
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
  FROM dba_data_files df, free_space free, tablespace_name tbs_name
 WHERE df.tablespace_name = free.tablespace_name(+)
   AND df.file_id = free.file_id(+)
   and tbs_name.tablespace_name = df.tablespace_name
 GROUP BY df.tablespace_name
 ORDER BY 8;



-----表空间创建时间
set linesize 1000 pagesize 500
select distinct to_char(min(b.CREATION_TIME)
                        over(partition by a.TABLESPACE_NAME),
                        'yyyy-mm-dd') as CREATION_TIME,
                a.TABLESPACE_NAME,
                round((sum(a.BYTES) over(partition by a.TABLESPACE_NAME)) / 1024 / 1024 / 1024,
                      2) as size_gb
  from cdb_data_files a
  join v$datafile b
    on a.FILE_ID = b.FILE#
    and a.CON_ID=b.CON_ID
 where a.TABLESPACE_NAME not in ('SYSAUX',
                                 'SYSTEM',
                                 'UNDOTBS1',
                                 'UNDOTBS2',
                                 'UNDOTBS3',
                                 'USERS',
                                 'EXAMPLE')
 order by 1, 2;

select a.TABLESPACE_NAME,
       min(b.CREATION_TIME) over(partition by a.TABLESPACE_NAME) CREATION_TIME,
       round((sum(a.BYTES) over(partition by a.TABLESPACE_NAME)) / 1024 / 1024 / 1024,
             2) size_gb
  from dba_data_files a, v$datafile b
 where a.FILE_ID = b.FILE#
   and a.TABLESPACE_NAME not in ('SYSAUX',
                                 'SYSTEM',
                                 'UNDOTBS1',
                                 'UNDOTBS2',
                                 'UNDOTBS3',
                                 'USERS',
                                 'EXAMPLE');




 -----数据库drop表情况统计，半月粒度
 select *
   from (select OWNER, ORIGINAL_NAME, OPERATION, count(*)
           from dba_recyclebin
          where TYPE like 'Table%'
            and to_date(DROPTIME,'yyyy-mm-dd:hh24:mi:ss' )> sysdate - 15
          group by OWNER, ORIGINAL_NAME, OPERATION
          order by 4 desc)
  where rownum < 21;








--------------paas  DIRECTORIES 查询
col OWNER for a20
col DIRECTORY_NAME for a30
col DIRECTORY_PATH for a70
set linesize 1000 pagesize 5000
select * from DBA_DIRECTORIES where DIRECTORY_PATH like '%/archive/dumpdir/zc_bmdp%';

GRANT read, write ON DIRECTORY ZJMONITORV2_NEW  TO it_zjmonitorv2_test;



------------查询用户下的表空间
select distinct a.owner,a.tablespace_name from dba_segments a  where a.owner='WY_WIMPSE';


------查询表空间中的对象属于哪个用户
select distinct a.owner,a.tablespace_name from dba_segments a  where a.tablespace_name='';

select distinct a.owner
  from dba_segments a
 where a.tablespace_name in ('HKZSNJL_ZSMS_DATA','HKZSNJL_ZSMS_INDEX')
union
select USERNAME owner
  from dba_users
 where DEFAULT_TABLESPACE in ('HKZSNJL_ZSMS_DATA','HKZSNJL_ZSMS_INDEX');




------授权脚本,将 hkjtcy_hosting_admin 所有表的访问权限都给HKJTCY_REPORT用户
set linesize 1000 pagesize 5000
col cmd  for a100
select 'grant select on ' || a.owner || '.' || a.table_name ||
       ' to admin;' as cmd
  from dba_tables a
 where a.owner = upper('HKJTCY_HOSTING_ADMIN')
   and not exists (select 1
          from dba_tab_privs b
         where b.owner = a.owner
           and b.TABLE_NAME = a.TABLE_NAME
           and GRANTEE in ('ADMIN', 'PUBLIC'));












-----------用户信息
set linesize 1000 pagesize 5000
col USERNAME for a30
col CREATED for a30
col ACCOUNT_STATUS for a20
col  LOCK_DATE  for a30
SELECT USERNAME,
       ACCOUNT_STATUS,
       to_char(LOCK_DATE, 'yyyymmdd HH24:mi:ss') LOCK_DATE,
       to_char(EXPIRY_DATE, 'yyyymmdd HH24:mi:ss') EXPIRY_DATE,
       to_char(CREATED, 'yyyymmdd HH24:mi:ss') CREATED,
       PROFILE,
       DEFAULT_TABLESPACE
  FROM dba_users where  DEFAULT_TABLESPACE in ('IISS_DAT')
 ORDER BY ACCOUNT_STATUS;



select count(*) from dba_objects  where OWNER in ('ZC_BMDP')
; 




/*资源分配查询与更新，在石桥GC上*/

-----查询
set linesize 1000 pagesize 500
col BUSI_NAME for a25
col DB_NAME for a20
col DEP_NAME for a20
col SERVICE_NAME for a20
col TABLESPACE_NAME for a30
select DB_NAME,
       BUSI_NAME,
       DEP_NAME,
       SERVICE_NAME,
       TABLESPACE_NAME,
       CREATE_DATE
  from SYSMAN.PAAS_BUS_MAP
 order by CREATE_DATE, DB_NAME;



select DB_NAME,
       BUSI_NAME,
       DEP_NAME,
       SERVICE_NAME,
       TABLESPACE_NAME,
       CREATE_DATE
  from SYSMAN.PAAS_BUS_MAP
 order by DB_NAME, BUSI_NAME;


------插入资源分配信息
--红字分别为数据库名，业务名，所属科室名，服务名，表空间名，资源分配时间
INSERT INTO "SYSMAN"."PAAS_BUS_MAP"
  (DB_NAME,
   BUSI_NAME,
   DEP_NAME,
   SERVICE_NAME,
   TABLESPACE_NAME,
   CREATE_DATE)
VALUES
  (lower('bjpaasb'),
   '掌上运维平台',
   '支撑部',
   lower('zc_bmdp'),
   upper('ZC_BMDP'),
   '20151118');









----------------(双周周报)PAAS CPU&&&MEMORY查询，from 小业务
select   
sum(decode(T.TARGET_NAME,'sqpaasa1',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa1_CPU,  
sum(decode(T.TARGET_NAME,'sqpaasa2',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa2_CPU,  
sum(decode(T.TARGET_NAME,'sqpaasa3',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa3_CPU,  
sum(decode(T.TARGET_NAME,'sqpaasa1',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa1_MEM,  
sum(decode(T.TARGET_NAME,'sqpaasa2',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa2_MEM,  
sum(decode(T.TARGET_NAME,'sqpaasa3',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa3_MEM,  
sum(decode(T.TARGET_NAME,'sqpaasa_sqpaasa1',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa1_PROCESS, 
sum(decode(T.TARGET_NAME,'sqpaasa_sqpaasa2',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa2_PROCESS, 
sum(decode(T.TARGET_NAME,'sqpaasa_sqpaasa3',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa3_PROCESS, 
sum(decode(T.TARGET_NAME,'sqpaasa_sqpaasa1',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa1_SESSION, 
sum(decode(T.TARGET_NAME,'sqpaasa_sqpaasa2',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa2_SESSION, 
sum(decode(T.TARGET_NAME,'sqpaasa_sqpaasa3',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqa3_SESSION,  
sum(decode(T.TARGET_NAME,'sqpaasb1',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb1_CPU,  
sum(decode(T.TARGET_NAME,'sqpaasb2',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb2_CPU,  
sum(decode(T.TARGET_NAME,'sqpaasb3',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb3_CPU,  
sum(decode(T.TARGET_NAME,'sqpaasb1',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb1_MEM,  
sum(decode(T.TARGET_NAME,'sqpaasb2',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb2_MEM,  
sum(decode(T.TARGET_NAME,'sqpaasb3',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb3_MEM,  
sum(decode(T.TARGET_NAME,'sqpaasb_sqpaasb1',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb1_PROCESS, 
sum(decode(T.TARGET_NAME,'sqpaasb_sqpaasb2',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb2_PROCESS, 
sum(decode(T.TARGET_NAME,'sqpaasb_sqpaasb3',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb3_PROCESS, 
sum(decode(T.TARGET_NAME,'sqpaasb_sqpaasb1',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb1_SESSION, 
sum(decode(T.TARGET_NAME,'sqpaasb_sqpaasb2',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb2_SESSION, 
sum(decode(T.TARGET_NAME,'sqpaasb_sqpaasb3',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqb3_SESSION, 
sum(decode(T.TARGET_NAME,'sqpaasc1',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqc1_CPU,  
sum(decode(T.TARGET_NAME,'sqpaasc2',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqc2_CPU,  
sum(decode(T.TARGET_NAME,'sqpaasc1',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqc1_MEM,  
sum(decode(T.TARGET_NAME,'sqpaasc2',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqc2_MEM,  
sum(decode(T.TARGET_NAME,'sqpaasc_sqpaasc1',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqc1_PROCESS, 
sum(decode(T.TARGET_NAME,'sqpaasc_sqpaasc2',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqc2_PROCESS, 
sum(decode(T.TARGET_NAME,'sqpaasc_sqpaasc1',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqc1_SESSION, 
sum(decode(T.TARGET_NAME,'sqpaasc_sqpaasc2',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqc2_SESSION, 
sum(decode(T.TARGET_NAME,'sqpaase1',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqe1_CPU,  
sum(decode(T.TARGET_NAME,'sqpaase1',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqe1_MEM,  
sum(decode(T.TARGET_NAME,'sqpaase_sqpaase1',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqe1_PROCESS, 
sum(decode(T.TARGET_NAME,'sqpaase_sqpaase1',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) sqe1_SESSION, 
sum(decode(T.TARGET_NAME,'zjhz-bjpaasa1',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bja1_CPU,  
sum(decode(T.TARGET_NAME,'zjhz-bjpaasa1',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bja1_MEM,  
sum(decode(T.TARGET_NAME,'bjpaasa1',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bja1_PROCESS, 
sum(decode(T.TARGET_NAME,'bjpaasa1',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bja1_SESSION, 
sum(decode(T.TARGET_NAME,'zjhz-bjpaasb1',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb1_CPU,  
sum(decode(T.TARGET_NAME,'zjhz-bjpaasb2',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb2_CPU,  
sum(decode(T.TARGET_NAME,'zjhz-bjpaasb3',(decode(M.COLUMN_LABEL,'CPU Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb3_CPU,  
sum(decode(T.TARGET_NAME,'zjhz-bjpaasb1',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb1_MEM,  
sum(decode(T.TARGET_NAME,'zjhz-bjpaasb2',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb2_MEM,  
sum(decode(T.TARGET_NAME,'zjhz-bjpaasb3',(decode(M.COLUMN_LABEL,'Memory Utilization (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb3_MEM,  
sum(decode(T.TARGET_NAME,'bjpaasb_bjpaasb1',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb1_PROCESS, 
sum(decode(T.TARGET_NAME,'bjpaasb_bjpaasb2',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb2_PROCESS, 
sum(decode(T.TARGET_NAME,'bjpaasb_bjpaasb3',(decode(M.COLUMN_LABEL,'Process Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb3_PROCESS, 
sum(decode(T.TARGET_NAME,'bjpaasb_bjpaasb1',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb1_SESSION, 
sum(decode(T.TARGET_NAME,'bjpaasb_bjpaasb2',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb2_SESSION, 
sum(decode(T.TARGET_NAME,'bjpaasb_bjpaasb3',(decode(M.COLUMN_LABEL,'Session Limit Usage (%)',round(M1.VALUE_AVERAGE,2),0)),0)) bjb3_SESSION, 
(to_char(M1.ROLLUP_TIMESTAMP,'yyyymmdd hh24:mi')) collect_time  
from MGMT_METRICS_1HOUR M1,MGMT_METRICS M, MGMT_TARGETS T,MGMT_TARGET_TYPES TT ,my_target mt  
where M1.METRIC_GUID=M.METRIC_GUID   
  and m1.target_guid=t.target_guid  ;
  
  
  
  
  
--------------------(双周周报) 表空间数据
select host_name,
       target_name,
       TABLESPACE_NAME,
       target_type,
       TABLESPACE_SIZE / 1024 / 1024 / 1024 分配大小GB,
       round((NVL(TABLESPACE_USED_SIZE, 0) / 1024 / 1024 / 1024), 2) 使用大小GB,
       round((NVL(TABLESPACE_USED_SIZE, 0) / TABLESPACE_SIZE), 2) 使用率
  from MGMT$DB_TABLESPACES_ALL
 where host_name like '%paas%'
   and host_name in ('sqpaase_sqpaase1', 'zjhz-bjpaasa1', 'zjhz-bjpaasa1')
union all
select host_name,
       target_name,
       TABLESPACE_NAME,
       target_type,
       TABLESPACE_SIZE / 1024 / 1024 / 1024 分配大小GB,
       round((NVL(TABLESPACE_USED_SIZE, 0) / 1024 / 1024 / 1024), 2) 使用大小GB,
       round((NVL(TABLESPACE_USED_SIZE, 0) / TABLESPACE_SIZE), 2) 使用率
  from MGMT$DB_TABLESPACES_ALL
 where host_name like '%paas%'
   and target_type = 'rac_database';
  



          
            
--------------------(双周周报) 库大小  数据  
select host_name,target_name,target_type,round(sum(TABLESPACE_SIZE)/1024/1024/1024,2) 分配大小GB,round(sum(TABLESPACE_USED_SIZE)/1024/1024/1024,2) 使用大小GB  
from MGMT$DB_TABLESPACES_ALL  
where host_name like '%paas%'  
and host_name in ('sqpaase1','zjhz-bjpaasa1','zjhz-bjpaasa1')  
group by host_name, target_name, target_type  
union all  
(select host_name,target_name,target_type,round(sum(TABLESPACE_SIZE)/1024/1024/1024,2) 分配大小GB,round(sum(TABLESPACE_USED_SIZE)/1024/1024/1024,2) 使用大小GB  
from MGMT$DB_TABLESPACES_ALL  
where host_name like '%paas%'  
and target_type='rac_database' group by host_name, target_name, target_type) 
order by 2;



--------------------(双周周报) 业务空间数据
select ma.host_name,
       ma.target_name,
       pbm.busi_name,
       pbm.dep_name,
       sum(ma.TABLESPACE_SIZE) / 1024 / 1024 / 1024 sum_GB,
       round((sum(ma.TABLESPACE_USED_SIZE) / 1024 / 1024 / 1024), 3) used_GB,
       pbm.CREATE_DATE
  from MGMT$DB_TABLESPACES_ALL ma, paas_bus_map pbm
 where ma.TARGET_NAME = pbm.DB_NAME
   and pbm.TABLESPACE_NAME = 'ALL'
 group by pbm.busi_name,
          ma.host_name,
          ma.target_name,
          pbm.dep_name,
          pbm.CREATE_DATE
union all
select ma.host_name,
       ma.target_name,
       pbm.busi_name,
       pbm.dep_name,
       sum(ma.TABLESPACE_SIZE) / 1024 / 1024 / 1024 sum_GB,
       round((sum(ma.TABLESPACE_USED_SIZE) / 1024 / 1024 / 1024), 3) used_GB,
       pbm.CREATE_DATE
  from MGMT$DB_TABLESPACES_ALL ma, paas_bus_map pbm
 where ma.TARGET_NAME = pbm.DB_NAME
   and ma.TABLESPACE_NAME = pbm.TABLESPACE_NAME
 group by pbm.busi_name,
          ma.host_name,
          pbm.dep_name,
          ma.target_name,
          pbm.CREATE_DATE
 order by 2, 7;
  

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  



-------------CPU 使用情况
select to_char(END_INTERVAL_TIME, 'yy-mm-dd hh24:mi') END_TIME,
       pLimit,
       SLimit,
       cpuUti
  from (select t.SNAP_ID, t.END_INTERVAL_TIME, t.METRIC_NAME, t.AVERAGE
          from XJ_V_PAAS_SYSMETRIC_ALL t
         where t.DBNAME = 'SQPAASA'
               and t.INSTANCE_NUMBER = 1
               and t.METRIC_NAME in
               ('Process Limit %',
                    'Session Limit %',
                    'Host CPU Utilization (%)'))
pivot(max(AVERAGE)
   for METRIC_NAME in('Process Limit %' as pLimit,
                      'Session Limit %' as SLimit,
                      'Host CPU Utilization (%)' as cpuUti))
 order by SNAP_ID;

--------------IO 响应
select to_char(END_INTERVAL_TIME, 'yymmddhh24mi') END_TIME,
       io_res_1,
       io_res_2,
       io_res_3
  from (select t.SNAP_ID, t.END_INTERVAL_TIME, t.INSTANCE_NUMBER, t.AVERAGE
          from XJ_V_PAAS_SYSMETRIC_ALL t
         where t.DBNAME = 'BJPAASB'
               and t.METRIC_NAME in
               ('I/O response from sequential read'))
pivot(max(AVERAGE)
   for INSTANCE_NUMBER in('1' as io_res_1,
                      '2' as io_res_2,
                      '3' as io_res_3))
 order by SNAP_ID;
 
 /*数据库目标*/
10.212.211.5
service_name：emrep
sid：emrep
xjmon/xjmon_321

-----------Paas表空间数据库空间分配及利用情况
select t.dbname,
       round(sum(t.size_kb) / 1024 / 1024) size_gb,
       round(sum(t.size_kb - t.free_kb) / 1024 / 1024 ) used_gb
  from XJ_V_PAAS_TBS_MSG_ALL t
 group by t.dbname;

------分业务空间利用情况
select a.pname,
       a.sname,
       round(sum(b.size_kb) / 1024 / 1024) size_gb,
       round(sum(b.size_kb - b.free_kb) / 1024 / 1024) used_gb
  from (select distinct tbs_name, pname, sname
          from xjmon.XJ_T_PAAS_TBS_ALLOC) a,
       xjmon.XJ_V_PAAS_TBS_MSG_ALL b
 where a.tbs_name = b.tablespace_name
       and upper(a.pname) = b.dbname
       and a.pname in ('BJPAASB','SQPAASA','SQPAASB')
 group by a.pname, a.sname
 order by a.pname;


---------------表空间分配时间超过60天，使用率低于10%的表空间信息
select alloc.pname,
       alloc.sname,
       alloc.tbs_name,
       round(sum(b.size_kb) / 1024 / 1024) size_gb,
       round(sum(b.size_kb - b.free_kb) / 1024 / 1024) used_gb
  from (select distinct tbs_name, pname, sname
          from xjmon.XJ_T_PAAS_TBS_ALLOC) alloc,
       xjmon.XJ_V_PAAS_TBS_MSG_ALL b
 where alloc.tbs_name = b.tablespace_name
       and upper(alloc.pname) = b.dbname
       and b.min_creation_time <= sysdate - 60
       and (b.free_kb / b.size_kb) >= 0.9
 group by alloc.pname, alloc.sname, alloc.tbs_name
 order by alloc.pname;

select * from XJ_V_PAAS_TBS_MSG_ALL  a where a.dbname='SQPAASD'

--------------表空间分配时间超过30天且未分配任何段的表空间信息
select alloc.pname,
       alloc.sname,
       alloc.tbs_name,
       round(sum(b.size_kb) / 1024 / 1024) size_gb
  from (select distinct tbs_name, pname, sname
          from xjmon.XJ_T_PAAS_TBS_ALLOC) alloc,
       xjmon.XJ_V_PAAS_TBS_MSG_ALL b
 where alloc.tbs_name = b.tablespace_name
       and upper(alloc.pname) = b.dbname
       and b.min_creation_time <= sysdate - 30
       and b.have_segs = 'N/A'
 group by alloc.pname, alloc.sname, alloc.tbs_name
 order by  alloc.pname;


------------------历史性能数据主要指标（I/O response from sequential read,Session Limit %,Process Limit %,Host CPU Utilization (%)）
select a.DBNAME,
       a.SNAP_ID,
       a.END_INTERVAL_TIME,
       a.INSTANCE_NUMBER,
       a.AVERAGE
  from xjmon.XJ_V_PAAS_sysmetric_all a
where a.METRIC_NAME='Host CPU Utilization (%)'
and a.DBNAME='SQPAASB'；

