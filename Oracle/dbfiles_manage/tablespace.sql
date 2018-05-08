/**************************************************/
表空间及数据文件
/**********************************************/


-----相关参数
dba_create_file_dest
dba_create_online_log_dest_n
dba_recovery_file_dest


create temporary tablespace TEMP_ZMCC tempfile '/112db_oradata01/hz112db/TEMP_ZMCC.dbf'size 10G autoextend off;



----------创建表空间
create bigfile tablespace test2 datafile '/oradata/anixfs/test2.dbf' size 50M   extent    management local  segment space management auto;
create temporary tablespace test4 datafile '/oradata/anixfs/test2.dbf'size50M reuse extent    management local uniform size 8M;
create  tablespace  test1  datafile '+YONG_DG' size 5G AUTOEXTEND off  extent    management local;
create undo tablespace test2 datafile  '/oradata/anixfs/test2.dbf' size 50M reuse  extent    management local;

------表空间压缩
create  tablespace  dbmon datafile '/ldata/datafile/lymon/dbmon01.dbf' size 5G   compress for OLTP;  ----11g压缩表空间
create  tablespace  dbmon datafile '/ldata/datafile/lymon/dbmon01.dbf' size 5G  default row store compress advanced;  ----12c压缩表空间
alter tablespace tbs_name default row store compress advanced;
alter tablespace tbs_name default compress basic; ----压缩程度为basic
alter tablespace tbs_name default nocompress ;  -----禁用压缩

-------重命名表空间
alter tablespace tbs_old_name rename to tbs_new_name;


--------增加数据文件
alter tablespace test1 add datafile '/opt/oracle/oradata/rcountdb/rcountdb03.dbf' size 8000M;
alter tablespace TBS_ODS_201007 add datafile '+CDRDG' size 32767M autoextend off; 
alter tablespace TBS_ODS_201007 add datafile '+CDRDG' size 10239M autoextend on next 64M;
alter tablespace TBS_ODS_201008 add datafile '+ODSNDMCDG' size 32767M,'+ODSNDMCDG' size 32767M autoextend off; 
-------重命名表空间
alter tablespace test rename to test1;
-------重命名数据文件
SQL> alter database rename file '/oradata/datafile/anix/test02.dbf ' To '/oradata/datafile/anix/test03.dbf ';

-------修改数据文件大小
alter database datafile '/opt/oracle/oradata/rcountdb/rcountdb02.dbf' resize  15G;
------数据文件状态
alter tablespace test1 offline; 
alter tablespace test1 online; 
alter database datafile '/oradata/datafile/anix/test01.dbf' offline|online;
注：非归档模式只能先offline表空间之后才能offline数据文件
------删除数据文件
alter database datafile '/oradata/datafile/anix/test02.dbf' offline  drop;
------删除表空间
drop  tablespace YONG_UNFORM including contents and datafiles cascade constraints;
--删除空的表空间，但是不包含物理文件
drop tablespace tablespace_name;
--删除非空表空间，但是不包含物理文件
drop tablespace tablespace_name including contents;
--删除空表空间，包含物理文件
drop tablespace tablespace_name including datafiles;
--删除非空表空间，包含物理文件
drop tablespace tablespace_name including contents and datafiles;
--如果其他表空间中的表有外键等约束关联到了本表空间中的表的字段，就要加上CASCADE CONSTRAINTS
drop tablespace YONG_UNFORM including contents and datafiles CASCADE CONSTRAINTS;

---------移动数据文件
RMAN> sql "alter tablespace dlm  offline";
RMAN> copy datafile '/archive/dlm/dlm_data.dbf' to '+dlm_data/dlm/datafile/DLM.268.873998453';
SQL> alter database rename file '/archive/dlm/dlm_data.dbf' to '+dlm_data/dlm/datafile/DLM.268.873998453';
SQL> sql " alter tablespace dlm online ";

alter database move  datafile 'old_datafile_name' to 'new_datafile_name'  [keep|reuse] ;   -----12c在线移动数据文件



-------如果我们需要对某个datafile进行resize，那么必须大于HWMSIZE值
SELECT *
     FROM (SELECT /*+ ordered use_hash(a,b,c) */
            a.file_id,
            a.file_name,
            a.filesize,
            b.freesize,
            (a.filesize - b.freesize) usedsize,
            c.hwmsize,
            c.hwmsize - (a.filesize - b.freesize) unsedsize_belowhwm,
            a.filesize - c.hwmsize canshrinksize
             FROM (SELECT file_id,
                          file_name,
                          round(bytes / 1024 / 1024) filesize
                     FROM dba_data_files) a,
                  (SELECT file_id, round(SUM(dfs.bytes) / 1024 / 1024) freesize
                     FROM dba_free_space dfs
                    GROUP BY file_id) b,
                  (SELECT file_id, round(MAX(block_id) * 8 / 1024) HWMsize
                     FROM dba_extents
                    GROUP BY file_id) c
            WHERE a.file_id = b.file_id
              AND a.file_id = c.file_id
            ORDER BY unsedsize_belowhwm DESC)
    WHERE file_id IN (SELECT file_id
                        FROM dba_data_files
                       WHERE tablespace_name = 'DMSB_TS01')
    ORDER BY file_id;

===========================下面的方法也可以===============================

select file_name,
       ceil( (nvl(hwm,1)*&&blksize)/1024/1024 ) smallest,
       ceil( blocks*&&blksize/1024/1024) currsize,
       ceil( blocks*&&blksize/1024/1024) -
       ceil( (nvl(hwm,1)*&&blksize)/1024/1024 ) savings
from dba_data_files a,
     ( select file_id, max(block_id+blocks-1) hwm
         from dba_extents
        group by file_id ) b
where a.file_id = b.file_id(+) and a.file_id=2;







/********************扩容操作*************************/
echo $ORACLE_SID
export OTACLE_SID=orcl
echo $ORACLE_SID


set linesize 1000 pagesize 500
col file_name for a150
col TABLESPACE_NAME for a30
select tablespace_name,
FILE_ID,
      -- STATUS,
       bytes / 1024 / 1024  size_mb,
      -- ONLINE_STATUS,
       file_name
  from dba_data_files
 where  tablespace_name in ('TBS_SY','TBS_CRM','TBS_CHANGCHUN')
 --and file_name like '/opt/oracle/oradata3%'
 order by tablespace_name,FILE_ID, file_name;

set linesize 500 pagesize 500
col file_name for a70
col cmd for a150

SELECT 'alter tablespace ' || tablespace_name || ' add datafile ' || '''' ||
       '/data03/pmsdb132/pmsdb_' || tablespace_name ||
       '11.dbf'||''''||' size 16G autoextend off;' cmd
  FROM dba_tablespaces a
-- WHERE   tablespace_name like 'DWTBS0%'
--AND file_name LIKE '/opt/oracle/oradata7/dmtbs%'
--  AND (BYTES / 1024 / 1024 / 1024) < 30
-- and file_name like '/data02/pmsdb132/%'
 group by tablespace_name
 ORDER BY tablespace_name;




select TABLESPACE_NAME, STATUS,CONTENTS from cdb_tablespaces where TABLESPACE_NAME='ZJMONITORV2_NEW';
select TABLESPACE_NAME,FILE_NAME,bytes/1024/1024 size_m from dba_temp_files;








SELECT tablespace_name, SUM(BYTES) BYTES, MAX(BYTES) maxbytes
   FROM dba_free_space
 --where bytes > 1024 * 1024
  GROUP BY tablespace_name;

-----------表空间查询慢，收集统计信息
select * from table(dbms_xplan.display_cursor(null,null,'allstats +alias +outline'));
execute dbms_stats.gather_fixed_objects_stats;

execute dbms_stats.gather_table_stats(ownname=>'SYS',tabname=>'RECYCLEBIN$');

-------妥协做法，表空间查询
select a.TABLESPACE_NAME, a.tbs_mb, b.used_mb, a.tbs_mb - b.used_mb free_mb, a.cnt_df, round((b.used_mb /
              a.tbs_mb)*100,
              2) user_pct
  from (select TABLESPACE_NAME, round(sum(BYTES) / 1024 / 1024, 2) tbs_mb, count(*) cnt_df
           from dba_data_files
          group by TABLESPACE_NAME) a
  join (select tablespace_name, round(sum(a.BYTES) / 1024 / 1024, 2) used_mb
          from dba_segments a
         group by tablespace_name) b
    on a.TABLESPACE_NAME = b.TABLESPACE_NAME
    order by user_pct  desc;



USE_HASH(@"SEL$4" "U"@"SEL$4")

set linesize 1000 pagesize 500
col tablespace_name for a30



with free_space as
 (SELECT /*+ materialize */
   tablespace_name, file_id, SUM(BYTES) BYTES
    FROM dba_free_space
  --where bytes > 1024 * 1024
   GROUP BY tablespace_name, file_id)
SELECT df.tablespace_name,
       COUNT(*) dnt,
       ROUND(SUM(df.BYTES) / 1048576 / 1024, 2) size_gb,
       ROUND(SUM(free.BYTES) / 1048576 / 1024, 2) free_gb,
       ROUND(SUM(df.BYTES) / 1048576 / 1024 -
             SUM(free.BYTES) / 1048576 / 1024,
             2) used_gb,
       100 - ROUND(100.0 * SUM(free.BYTES) / SUM(df.BYTES), 2) pct_used,
       ROUND(100.0 * SUM(free.BYTES) / SUM(df.BYTES), 2) pct_free
  FROM dba_data_files df, free_space free
 WHERE df.tablespace_name = free.tablespace_name(+)
   AND df.file_id = free.file_id(+)
--and df.tablespace_name like 'IRM_DATA%'
 GROUP BY df.tablespace_name
 ORDER BY pct_free;
          
select * from table(dbms_xplan.display_cursor(null,null,'allstats +alias +outline'));


SELECT 
   tablespace_name, SUM(BYTES) BYTES 
    FROM dba_free_space
  --where bytes > 1024 * 1024
   GROUP BY tablespace_name;
select * from table(dbms_xplan.display_cursor(null,null,'allstats +alias +outline'));


set linesize 500 pagesize 500
col file_name for a70
SELECT a.tablespace_name,
       a.BYTES / 1024 / 1024 / 1024 size_gb,
       a.file_name
  FROM dba_data_files a
 WHERE a.tablespace_name like 'SYSAUX%'
--AND file_name LIKE '/opt/oracle/oradata7/dmtbs%'
--  AND (BYTES / 1024 / 1024 / 1024) < 30
--and file_name like '/data03/pmsdb132/dmtbs%'
 ORDER BY 1, 3;
 





-----------12C 表空间查询语句
with tbs as
 (select t.CON_ID,
         t.TABLESPACE_NAME,
         t.EXTENT_MANAGEMENT || '/' || t.SEGMENT_SPACE_MANAGEMENT seg_status,
         t.LOGGING || '/' || t.FORCE_LOGGING log_status,
         t.BIGFILE || '/' || f1.file_cnt file_num,
         f1.size_BYTEs
    from cdb_tablespaces t
    join (select f.CON_ID,
                f.TABLESPACE_NAME,
                count(*) file_cnt,
                sum(f.BYTES) size_BYTEs
           from cdb_data_files f
          group by f.CON_ID, f.TABLESPACE_NAME) f1
      on t.CON_ID = f1.CON_ID
         and t.TABLESPACE_NAME = f1.TABLESPACE_NAME)
select s.CON_ID,
       s.TABLESPACE_NAME,
       max(tbs.seg_status) seg_status,
       max(tbs.log_status) log_status,
       max(tbs.file_num) file_num,
       max(size_BYTEs) / 1024 / 1024 size_mb,
       sum(s.BYTES) / 1024 / 1024 free_mb
  from cdb_free_space s
  join tbs
    on s.CON_ID = tbs.CON_ID
       and s.TABLESPACE_NAME = tbs.TABLESPACE_NAME
 group by s.CON_ID, s.TABLESPACE_NAME
 order by s.CON_ID, s.TABLESPACE_NAME




column gnum  format 999;
column gname format a12;
column au_mb format 9999;
column state format a10;
column type  format a10;
set lines 132 pages 1000;
SELECT group_number gnum,
       NAME gname,
       sector_size,
       block_size,
       allocation_unit_size / 1024 / 1024/1024 alloc_Gb,
       state,
       TYPE,
       total_mb/1024 total_GB,
       free_mb/1024 free_gb,
       required_mirror_free_mb/1024 rm_gb,
       usable_file_mb/1024 uf_gb,
       offline_disks
  FROM v$asm_diskgroup;








set linesize 1000 pagesize 500
col file_name for a50 
select tablespace_name, file_name, bytes / 1024 / 1024 / 1024 size_gb
  from dba_data_files
 where tablespace_name like  'BOCO3%'
 order by 1, 2;



set linesize 1000 pagesize 500
col SEGMENT_NAME for a30
col OWNER for a20
select *
  from (select *
          from (select OWNER, SEGMENT_NAME, sum(BYTES) / 1024 / 1024/1024 size_gb
                  from dba_segments a
                 where a.tablespace_name like  'BOCO%'
                       --and SEGMENT_NAME like ''
                      -- and owner='XJMON'
                 group by OWNER, SEGMENT_NAME )
        --where size_gb > 2
         order by size_gb desc)
 where rownum < 21;

select OWNER, SEGMENT_NAME, sum(BYTES) / 1024 / 1024 / 1024 size_gb
  from dba_segments a
 where a.tablespace_name like 'BOCO3%'
       and SEGMENT_NAME like 'T_OPER_2016_09%'
 group by OWNER, SEGMENT_NAME
 order by  SEGMENT_NAME;
 

select OWNER, substr(SEGMENT_NAME,1,14) SEGMENT_NAME, sum(BYTES) / 1024 / 1024 / 1024 size_gb
  from dba_segments a
 where a.tablespace_name like 'BOCO3%'
      and SEGMENT_NAME like 'T_OPER_201%'
      and OWNER='AUDITOR'
 group by OWNER, substr(SEGMENT_NAME,1,14)
 order by  substr(SEGMENT_NAME,1,14);
 
 
 
 
 
         
         
alter table ZC_TNMSPON.PON_WECHAT_IMAGE drop constraint PK_PON_WECHAT_IMAGE;
drop index ZC_TNMSPON.PK_PON_WECHAT_IMAGE;
create unique  index ZC_TNMSPON.PK_PON_WECHAT_IMAGE on ZC_TNMSPON.PON_WECHAT_IMAGE(DRAFTID,LOCALID)   tablespace ITMS_DATA;
alter table ZC_TNMSPON.PON_WECHAT_IMAGE
    add constraint PK_PON_WECHAT_IMAGE primary key (DRAFTID,LOCALID)
   using index ZC_TNMSPON.PK_PON_WECHAT_IMAGE
   tablespace ITMS_DATA;
  
  
  


set linesize 1000 pagesize 500
col SEGMENT_NAME for a30
col OWNER for a20
select *
  from (select *
          from (select OWNER, SEGMENT_NAME, sum(BYTES) / 1024 / 1024/1024 size_gb
                  from dba_segments a
                 where a.tablespace_name like  'SYSTEM%'
                       --and SEGMENT_NAME<'T_OPER_2015_05_20'
                      -- and owner='XJMON'
                 group by OWNER, SEGMENT_NAME )        where size_gb > 2
         order by size_gb desc)
;



select *
  from (select OWNER, SEGMENT_NAME, sum(BYTES) / 1024 / 1024 / 1024 size_gb
          from dba_segments a
         where a.tablespace_name like 'SYSAUX%'
        --and SEGMENT_NAME<'T_OPER_2015_05_20'
        -- and owner='XJMON'
         group by OWNER, SEGMENT_NAME
         order by size_gb desc)
 where rownum < 20










-------------------存在问题待改写
set linesize 10000 pagesize 5000
col TABLESPACE_NAME for a20
col IS_BIG for a15
col TBS_GB for a15
with tbs_free_msg as
 (SELECT a.tablespace_name,
         SUM(a.BYTES) / 1024 free_size_kb,
         MAX(a.BYTES) / 1024 max_free_kb
    FROM dba_free_space a
  --where a.bytes > 1024 * 1024
   GROUP BY a.tablespace_name),
tbs_dbf_msg as
 (select c.NAME TABLESPACE_NAME,
         sum(b.BYTES) / 1024 alloc_ize_kb,
         max(b.CHECKPOINT_TIME) last_alloc_time,
         min(b.CHECKPOINT_TIME) tbs_alloc_time,
         count(*) dbf_cnt
    from  v$datafile b, v$tablespace c
   where b.TS# = c.TS#
   group by c.NAME)
select f.TABLESPACE_NAME,
       f.STATUS || '/' || f.EXTENT_MANAGEMENT tbs_status,
       f.LOGGING || '/' || f.FORCE_LOGGING log_statux,
       f.BIGFILE || '/' || h.dbf_cnt is_big,
       round(h.alloc_ize_kb / 1024 / 1024, 2) || '/' ||
       round(g.free_size_kb / 1024 / 1024, 2) tbs_gb,
       round((1 - g.free_size_kb / h.alloc_ize_kb) * 100, 2) pct_used,
       g.max_free_kb,
       to_char(h.tbs_alloc_time, 'yy-mm-dd hh24:mi:ss') alloc_time,
       to_char(h.last_alloc_time, 'yy-mm-dd hh24:mi:ss') last_alloc_time
  from dba_tablespaces f, tbs_free_msg g, tbs_dbf_msg h
 where g.TABLESPACE_NAME = h.TABLESPACE_NAME
       and h.TABLESPACE_NAME = f.TABLESPACE_NAME
 order by pct_used desc;
 
 
 
 
SELECT tablespace_name,
       SUM(BYTES) / 1024 / 1024 / 1024 BYTES,
       MAX(BYTES) maxbytes
  FROM dba_free_space
--where bytes > 1024 * 1024
 GROUP BY tablespace_name

SELECT tablespace_name, SUM(BYTES)/1024/1024/1024 size_gb 
  FROM dba_data_files
--where bytes > 1024 * 1024
 GROUP BY tablespace_name;


alter tablespace DATA_NB add datafile '/opt/oracle/oradata6/pmsdb/pmsdb_DATA_NB01.dbf' size 580000M autoextend off;
alter tablespace DATA_QZ add datafile '/opt/oracle/oradata6/pmsdb/pmsdb_DATA_QZ01.dbf' size 200000M autoextend off;




-------表空间增长情况
select b.name,
       a.rtime,
       round(a.tablespace_usedsize*8/1024/1024,2) used_gb,
       round(a.tablespace_size*8/1024/1024,2) size_gb,
       round(100 * a.tablespace_usedsize / a.tablespace_size,2) used_percent
  from dba_hist_tbspc_space_usage a,
       (select t2.name, max(rtime) rtime, min(tablespace_id) tablespace_id
          from dba_hist_tbspc_space_usage t1
         inner join v$tablespace t2
            on t1.tablespace_id = t2.TS#
         where t2.NAME = upper('UNDOTBS2')
         group by name, substr(rtime, 1, 10)) b
 where a.tablespace_id = b.tablespace_id
   and a.rtime = b.rtime
 order by to_date(a.rtime,'mm/dd/yyyy hh24:mi:ss');








select b.name,
       a.rtime,
       round(a.tablespace_usedsize*8/1024/1024,2) used_gb,
       round(a.tablespace_size*8/1024/1024,2) size_gb,
       round(100 * a.tablespace_usedsize / a.tablespace_size,2) used_percent
  from dba_hist_tbspc_space_usage a,
       (select t2.name, max(rtime) rtime, min(tablespace_id) tablespace_id
          from dba_hist_tbspc_space_usage t1
         inner join v$tablespace t2
            on t1.tablespace_id = t2.TS#
         where t2.NAME = upper('CACHETBS')
         group by name, substr(rtime, 1, 10)) b
 where a.tablespace_id = b.tablespace_id
   and a.rtime = b.rtime
 order by to_date(a.rtime,'mm/dd/yyyy hh24:mi:ss');



select b.name,
       a.rtime,
       round(a.tablespace_usedsize * 8 / 1024 / 1024, 2) used_gb,
       round(a.tablespace_size * 8 / 1024 / 1024, 2) size_gb,
       round(100 * a.tablespace_usedsize / a.tablespace_size, 2) used_percent
  from dba_hist_tbspc_space_usage a, v$tablespace b
 where a.tablespace_id = b.TS#
 and name ='USERS'
 order by rtime;






set linesize 1000 pagesize 500
col SEGMENT_NAME for a30
col OWNER for a20
select * from (
select *
  from (select OWNER,
               SEGMENT_NAME,
               sum(BYTES) / 1024 / 1024 size_Mb
          from dba_segments a
         where a.tablespace_name = 'SYSTEM'
         group by OWNER, SEGMENT_NAME)
--where size_gb > 1
 order by 3 desc) where rownum <11;



set linesize 1000 pagesize 500
col SEGMENT_NAME for a30
select *
  from (select OWNER,
               SEGMENT_NAME,PARTITION_NAME，
               sum(BYTES) / 1024 / 1024/1024 size_gb
          from dba_segments a
         where a.tablespace_name like 'ZZ_MALS71%'
         group by OWNER, SEGMENT_NAME，PARTITION_NAME order by size_gb desc )
where rownum <21;



select OWNER,
               SEGMENT_NAME,
               sum(BYTES) / 1024 / 1024/1024 size_gb
          from dba_segments a
         where a.tablespace_name = 'ZC_CCMS'
         group by OWNER, SEGMENT_NAME order by size_gb desc


show parameter audit_trail;

set linesize 300 pagesize 500
col segment_name for a50
SELECT a.owner,A.segment_name,
       a.bytes / 1024 / 1024,
       B.TABLESPACE_NAME,
       B.SEGMENT_SPACE_MANAGEMENT
  FROM dba_segments A, DBA_TABLESPACES B
 WHERE A.tablespace_name = B.TABLESPACE_NAME
   AND A.segment_name IN ('FGA_LOG$', 'AUD$');

BEGIN
  DBMS_AUDIT_MGMT.set_audit_trail_location(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,
                                            --this moves table AUD$
                                           audit_trail_location_value => 'DMTBS'); --AUD替换为系统中的ASSM表空间
END;
/

BEGIN
  DBMS_AUDIT_MGMT.set_audit_trail_location(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD,
                                            --this moves table FGA_LOG$
                                           audit_trail_location_value => 'DMTBS'); --FGA替换为系统中的ASSM表空间
END;
/












--------------paas  DIRECTORIES 查询
col OWNER for a20
col DIRECTORY_NAME for a30
col DIRECTORY_PATH for a70
set linesize 1000 pagesize 5000
select * from DBA_DIRECTORIES where DIRECTORY_PATH like '%/archive/dumpdir/zc_bmdp%';


--------------查询数据文件路径
set linesize 1000 pagesize 500
col file_name for a50 
select tablespace_name, file_name, bytes / 1024 / 1024 / 1024 size_gb
  from dba_data_files
 where tablespace_name like  'MDWH'
 order by 1, 2;

alter tablespace BOCO3 add datafile '+DATA_DG' size 30G  autoextend off; 


sqlplus -S  "/as sysdba" <<EOF
alter tablespace ZZ_MALS71 add datafile '/oradata02/zz_lbs4/mals34.dbf' size 30G  autoextend off;

alter tablespace ZZ_MALS71 add datafile '/oradata02/zz_lbs4/mals12.dbf' size 30G  autoextend off;

alter tablespace ZZ_MALS71 add datafile '/oradata02/zz_lbs4/mals13.dbf' size 30G  autoextend off;

alter tablespace ZZ_MALS71 add datafile '/oradata02/zz_lbs4/mals14.dbf' size 30G  autoextend off;

alter tablespace ZZ_MALS71 add datafile '/oradata02/zz_lbs4/mals15.dbf' size 30G  autoextend off;

alter tablespace ZZ_MALS71 add datafile '/oradata02/zz_lbs4/mals16.dbf' size 30G  autoextend off;

exit;
EOF



---------------------------------------PAAS 查询特定用户表空间使用情况
set linesize 1000 pagesize 500
col tablespace_name for a30
with free_space as (SELECT  tablespace_name,
               file_id,
               SUM(BYTES) BYTES,
               MAX(BYTES) maxbytes
          FROM dba_free_space
         where bytes > 1024 * 1024
         GROUP BY tablespace_name, file_id),
tablespace_name as ( select distinct  TABLESPACE_NAME from dba_segments where OWNER in ('ZC_TNMSPON','ZC_TNMSPONBAK'))
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
       free_space free,
       tablespace_name tbs_name
 WHERE df.tablespace_name = free.tablespace_name(+)
   AND df.file_id = free.file_id(+)
   and tbs_name.tablespace_name=df.tablespace_name
 GROUP BY df.tablespace_name
 ORDER BY 8;

-------查看pdb表空间或数据文件信息
set linesize  1000 pagesize 500
col FILE_NAME for a70
select con.con_id,
       con.DBID,
       con.name,
       con.OPEN_MODE,
       tbs.TABLESPACE_NAME,
       tbs.STATUS          tbs_status,
       dbf.STATUS          dbf_STATUS,
       dbf.FILE_NAME
  from cdb_data_files dbf, cdb_tablespaces tbs, v$containers con
 where con.CON_ID = tbs.CON_ID
   and tbs.CON_ID = dbf.CON_ID
   and tbs.TABLESPACE_NAME = dbf.TABLESPACE_NAME
   and con.name=''
 order by con_id, TABLESPACE_NAME, FILE_NAME;








select OWNER, count(*)
  from dba_segments
 where TABLESPACE_NAME in ('SYSTEM', 'SYSAUX')
 group by OWNER
 order by 2 desc;

select *
  from (select OWNER, SEGMENT_NAME, sum(BYTES) / 1024 / 1024 / 1024 size_gb
          from dba_segments
         where TABLESPACE_NAME in ('SYSTEM', 'SYSAUX')
         group by OWNER, SEGMENT_NAME
         order by 3 desc)
 where rownum < 21;



--------------paas  DIRECTORIES 查询
col OWNER for a20
col DIRECTORY_NAME for a30
col DIRECTORY_PATH for a70
set linesize 1000 pagesize 5000
select * from DBA_DIRECTORIES where DIRECTORY_PATH like '%/archive/dumpdir/zc_bmdp%';


--------------查询数据文件路径
set linesize 1000 pagesize 500
col file_name for a50 
select tablespace_name, file_name, bytes / 1024 / 1024 / 1024 size_gb
  from dba_data_files
 where tablespace_name in ('UNDOTBS1', 'UNDOTBS2','UNDOTBS3')
 order by 1, 2;

DBA_DIRECTORIES

set linesize 1000 pagesize 500
col file_name for a50 
col tablespace_name for a15
select tablespace_name,FILE_ID, file_name, bytes / 1024 / 1024 / 1024 size_gb,STATUS
  from dba_data_files
 where file_name    like  '/u01%'
 order by 1, 2;


set linesize 1000 pagesize 500
col file_name for a50 
select tablespace_name,FILE_ID, file_name, bytes / 1024 / 1024 / 1024 size_gb
  from dba_data_files
 where file_name = trim(file_name)
 order by 1, 2;



set linesize 1000 pagesize 500
col file_name for a50 
select ''''|| file_name||''''
  from dba_data_files
 where file_name    like  '/u01%'
 order by 1, 2;








with d as
 (SELECT /*+ MATERIALIZED*/  TABLESPACE_NAME,
         SUM(BYTES) SPACE,
         SUM(BLOCKS) BLOCKS
    FROM DBA_DATA_FILES
   GROUP BY TABLESPACE_NAME),
f as
 (SELECT   TABLESPACE_NAME, SUM(BYTES) FREE_SPACE
    FROM DBA_FREE_SPACE
   GROUP BY TABLESPACE_NAME)
select a.TABLESPACE_NAME "TBNAME",
       a.USED_RATE       "GetTableSizePused",
       b.contents        "GetTablesType",
       a.size_gb           "GetTableSizeTotal",
       a.USED_SPACE      "GetTableSizeUsed",
       a.FREE_SPACE      "GetTableFreeSize"
  from (SELECT D.TABLESPACE_NAME,
               SPACE/1024/1024/1024 size_gb,
               BLOCKS SUM_BLOCKS,
               (SPACE - NVL(FREE_SPACE, 2))/1024/1024/1024 "USED_SPACE",
               ROUND((SPACE - NVL(FREE_SPACE, 0) / SPACE) * 100, 2) "USED_RATE",
               FREE_SPACE "FREE_SPACE"
          FROM D, F
         WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
         ORDER BY "USED_RATE" DESC) a,
       dba_tablespaces b
 where a.tablespace_name = b.tablespace_name;



-------------查询表空间  from toad
SELECT ts.tablespace_name,
       ts.status,
       ts.contents,
       ts.extent_management,
       ts.bigfile,
       size_info.megs_alloc_gb,
       size_info.megs_free_gb,
       size_info.megs_used_gb,
       size_info.pct_free,
       size_info.pct_used,
       size_info.max
  FROM (SELECT a.tablespace_name,
               round(a.bytes_alloc / 1024 / 1024/1024) megs_alloc_gb,
               round(nvl(b.bytes_free, 0) / 1024 / 1024/1024) megs_free_gb,
               round((a.bytes_alloc - nvl(b.bytes_free, 0)) / 1024 / 1024/1024) megs_used_gb,
               round((nvl(b.bytes_free, 0) / a.bytes_alloc) * 100) Pct_Free,
               100 - round((nvl(b.bytes_free, 0) / a.bytes_alloc) * 100) Pct_used,
               round(maxbytes / 1048576) MAX
          FROM (SELECT f.tablespace_name,
                       SUM(f.bytes) bytes_alloc,
                       SUM(decode(f.autoextensible, 'YES', f.maxbytes, 'NO',
                                  f.bytes)) maxbytes
                  FROM dba_data_files f
                 GROUP BY tablespace_name) a,
               (SELECT f.tablespace_name, SUM(f.bytes) bytes_free
                  FROM dba_free_space f
                 GROUP BY tablespace_name) b
         WHERE a.tablespace_name = b.tablespace_name(+)
        UNION ALL
        SELECT h.tablespace_name,
               round(SUM(h.bytes_free + h.bytes_used) / 1048576) megs_alloc,
               round(SUM((h.bytes_free + h.bytes_used) -
                         nvl(p.bytes_used, 0)) / 1048576) megs_free,
               round(SUM(nvl(p.bytes_used, 0)) / 1048576) megs_used,
               round((SUM((h.bytes_free + h.bytes_used) -
                          nvl(p.bytes_used, 0)) /
                     SUM(h.bytes_used + h.bytes_free)) * 100) Pct_Free,
               100 - round((SUM((h.bytes_free + h.bytes_used) -
                                nvl(p.bytes_used, 0)) /
                           SUM(h.bytes_used + h.bytes_free)) * 100) pct_used,
               round(SUM(f.maxbytes) / 1048576) MAX
          FROM sys.v_$TEMP_SPACE_HEADER h,
               sys.v_$Temp_extent_pool  p,
               dba_temp_files           f
         WHERE p.file_id(+) = h.file_id
           AND p.tablespace_name(+) = h.tablespace_name
           AND f.file_id = h.file_id
           AND f.tablespace_name = h.tablespace_name
         GROUP BY h.tablespace_name) size_info,
       sys.dba_tablespaces ts
 WHERE ts.tablespace_name = size_info.tablespace_name
 ORDER BY tablespace_name;


-------------------------12c表空间
set linesize 1000 pagesize 500
col tablespace_name for a25
col name for a20
with free_size as
 (SELECT CON_ID, tablespace_name, SUM(BYTES) BYTES, MAX(BYTES) maxbytes
    FROM cdb_free_space free
   GROUP BY CON_ID, tablespace_name),
total_size as
 (select CON_ID, TABLESPACE_NAME, sum(BYTES) BYTES
    from cdb_data_files a
   group by CON_ID, TABLESPACE_NAME)
select t.con_id,
       c.name,
       t.tablespace_name,
       round(t.BYTES / 1024 / 1024 / 1024, 2) total_gb,
       ROUND(f.BYTES / 1024 / 1024 / 1024, 4) free_gb,
       round((t.BYTES - f.BYTES) / 1024 / 1024 / 1024, 2) used_gb,
       ROUND(f.maxbytes / 1024 / 1024, 2) maxfree_mb,
       100 - ROUND(100.0 * f.BYTES / t.BYTES, 2) pct_used
  from total_size t
  join free_size f
    on t.CON_ID = f.CON_ID
       and t.TABLESPACE_NAME = f.TABLESPACE_NAME
  left join v$containers c
    on t.CON_ID = c.CON_ID
 order by con_id, pct_used desc;
 

----Script – Tablespace free space and fragmentation

set linesize 150
column tablespace_name format a20 heading 'Tablespace'
column sumb format 999,999,999
column extents format 9999
column bytes format 999,999,999,999
column largest format 999,999,999,999
column Tot_Size format 999,999 Heading 'Total| Size(Mb)'
column Tot_Free format 999,999,999 heading 'Total Free(MB)'
column Pct_Free format 999.99 heading '% Free'
column Chunks_Free format 9999 heading 'No Of Ext.'
column Max_Free format 999,999,999 heading 'Max Free(Kb)'
set echo off
PROMPT  FREE SPACE AVAILABLE IN TABLESPACES
SELECT a.tablespace_name,
       SUM(a.tots / 1048576) Tot_Size,
       SUM(a.sumb / 1048576) Tot_Free,
       SUM(a.sumb) * 100 / SUM(a.tots) Pct_Free,
       SUM(a.largest / 1024) Max_Free,
       SUM(a.chunks) Chunks_Free
  FROM (SELECT tablespace_name,
               0 tots,
               SUM(bytes) sumb,
               MAX(bytes) largest,
               COUNT(*) chunks
          FROM dba_free_space a
         GROUP BY tablespace_name
        UNION
        SELECT tablespace_name, SUM(bytes) tots, 0, 0, 0
          FROM dba_data_files
         GROUP BY tablespace_name) a
 GROUP BY a.tablespace_name
 ORDER BY pct_free;


List all tablespaces with free space < 10%
set pagesize 300
set linesize 100
column tablespace_name format a15 heading 'Tablespace'
column sumb format 999,999,999
column extents format 9999
column bytes format 999,999,999,999
column largest format 999,999,999,999
column Tot_Size format 999,999 Heading 'Total Size(Mb)'
column Tot_Free format 999,999,999 heading 'Total Free(Kb)'
column Pct_Free format 999.99 heading '% Free'
column Max_Free format 999,999,999 heading 'Max Free(Kb)'
column Min_Add format 999,999,999 heading 'Min space add (MB)'

ttitle center 'Tablespaces With Less Than 10% Free Space' skip 2
set echo off

SELECT a.tablespace_name,
       SUM(a.tots / 1048576) Tot_Size,
       SUM(a.sumb / 1024) Tot_Free,
       SUM(a.sumb) * 100 / SUM(a.tots) Pct_Free,
       ceil((((SUM(a.tots) * 15) - (SUM(a.sumb) * 100)) / 85) / 1048576) Min_Add
  FROM (SELECT tablespace_name, 0 tots, SUM(bytes) sumb
          FROM dba_free_space a
         GROUP BY tablespace_name
        UNION
        SELECT tablespace_name, SUM(bytes) tots, 0
          FROM dba_data_files
         GROUP BY tablespace_name) a
 GROUP BY a.tablespace_name
HAVING SUM(a.sumb) * 100 / SUM(a.tots) < 10
 ORDER BY pct_free;


---------------计算表空间中的大表
set linesize 500 pagesize 500
col segment_name for a35
col owner for a20
col partition_name for a35
select * from(
SELECT a.owner,
       a.segment_name,
       SUM(a.BYTES) / 1024 / 1024 / 1024 size_gb
  FROM dba_segments a
 WHERE /*a.segment_name
 -- LIKE 'TABLE_T%'
IN ('TBL_PROCESS_DRAFT')
--and owner='IRM'*/
TABLESPACE_NAME='SYSTEM'
 GROUP BY a.owner, a.segment_name
 order by 3 desc) where rownum <10;


---------迁移升级表到业务表空间
BEGIN
  DBMS_AUDIT_MGMT.set_audit_trail_location(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,
                                            --this moves table AUD$
                                           audit_trail_location_value => 'NHM'); --AUD替换为系统中的ASSM表空间
END;
/

BEGIN
  DBMS_AUDIT_MGMT.set_audit_trail_location(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD,
                                            --this moves table FGA_LOG$
                                           audit_trail_location_value => 'NHM'); --FGA替换为系统中的ASSM表空间
END;
/
-------创建升级audit清理job
CREATE PROCEDURE P_CLEAR_AUDIT AS

  LVC_SQL VARCHAR2(200);
BEGIN

  LVC_SQL := 'TRUNCATE TABLE SYS.AUD$';
  EXECUTE IMMEDIATE LVC_SQL;

END;
/
---------定job
DECLARE
  JOBS INT;
BEGIN

  SYS.DBMS_JOB.SUBMIT(JOB       => JOBS,
                      WHAT      => 'P_CLEAR_AUDIT;',
                      NEXT_DATE => TO_DATE('2015-10-21 23:59:00',
                                           'YYYY-MM-DD HH24:MI:SS'),
                      INTERVAL  => 'SYSDATE+2');
  COMMIT;
END;
/


/****************************************************************/
                          扩容操作
/***************************************************************/

set linesize 500 pagesize 500
col file_name for a70
SELECT a.tablespace_name,
       a.BYTES / 1024 / 1024 / 1024 size_gb,
       a.file_name
  FROM dba_data_files a
 WHERE a.tablespace_name like 'ZC_TNMSPONBAK%'
--AND file_name LIKE '/opt/oracle/oradata7/dmtbs%'
--  AND (BYTES / 1024 / 1024 / 1024) < 30
-- and file_name like '/data02/pmsdb132/%'
 ORDER BY 1, 3;


set linesize 500 pagesize 500
col cmd for a150
SELECT distinct 'alter tablespace ' || a.tablespace_name || ' add datafile ' || '''' ||
       '/opt/oracle/oradata1/pmsdb/pmsdb_datafile' || a.tablespace_name ||
       '17.dbf' || '''' || ' size 8G autoextend off ;' as cmd 
  FROM dba_data_files a
 WHERE a.tablespace_name=upper('10.211.106.136')
   --AND file_name LIKE '/opt/oracle/oradata7/dmtbs%'
--  AND (BYTES / 1024 / 1024 / 1024) < 30
-- and file_name like '/data02/pmsdb132/%'
 ORDER BY 1;





--------------表空间检查
set linesize 500 pagesize 500
col file_name for a70
SELECT tablespace_name,
       BYTES / 1024 / 1024 / 1024 size_gb,
       'alter database datafile ' || '''' || file_name || '''' ||
       ' resize 30G; ' file_name
  FROM dba_data_files
 WHERE tablespace_name LIKE 'DWTBS0%'
   AND (file_name LIKE '/data02/pmsdb132/dwtbs__05.dbf' OR
       file_name LIKE '/data02/pmsdb132/dwtbs__06.dbf')
   AND (BYTES / 1024 / 1024 / 1024) < 30
 ORDER BY 1 DESC, 2;

-------查询表空间空间
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
 
 
-----检查ASM磁盘组剩余空间
column gnum  format 999;
column gname format a12;
column au_mb format 9999;
column state format a10;
column type  format a10;
set lines 132 pages 1000;
SELECT group_number gnum,
       NAME gname,
       sector_size,
       block_size,
       allocation_unit_size / 1024 / 1024/1024 alloc_Gb,
       state,
       TYPE,
       total_mb/1024 total_GB,
       free_mb/1024 free_gb,
       required_mirror_free_mb/1024 rm_gb,
       usable_file_mb/1024 uf_gb,
       offline_disks
  FROM v$asm_diskgroup;
  

---------表空间数据文件查询
set linesize 1000 pagesize 500
col file_name for a50
select tablespace_name,file_name,BYTES/1024/1024/1024 size_gb from dba_data_files where tablespace_name='BOCO3';
alter tablespace BOCO3 add datafile '+DATA_DG' size 30G autoextend off;

----扩容操作
select tablespace_name, sum(BYTES) / 1024 / 1024 / 1024 size_gb
  from dba_data_files
 where tablespace_name like 'DMTBS01%'
 group by tablespace_name
 order by 1;

col file_name for a50
select tablespace_name, file_name, BYTES / 1024 / 1024 / 1024 size_gb
  from dba_data_files
 where tablespace_name like 'DMTBS01%'
 order by 1, 2;

col TABLESPACE_NAME for a20
col file_name for a40
col cmd for a80
select tablespace_name, file_name, BYTES / 1024 / 1024 / 1024 size_gb,'alter database datafile '||''''||file_name||'''' ||' resize 30G; '   cmd
  from dba_data_files
 where tablespace_name like 'ZZ_MALS71%'
   and (file_name like '%15%' or file_name like '%14%')
   and file_name like '/opt/oracle/oradata7/dmtbs0%'
 order by 1, 2;




alter tablespace DMTBS01 add datafile  '/data03/pmsdb132/dmtbs0103' size 16G autoextend off;
alter tablespace DMTBS08 add datafile  '/data03/pmsdb132/dmtbs0803' size 16G autoextend off;
alter tablespace DMTBS03 add datafile  '/data03/pmsdb132/dmtbs0303' size 16G autoextend off;
alter tablespace DMTBS04 add datafile  '/data03/pmsdb132/dmtbs0403' size 16G autoextend off;
alter tablespace DMTBS05 add datafile  '/data03/pmsdb132/dmtbs0503' size 16G autoextend off;
alter tablespace DMTBS06 add datafile  '/data03/pmsdb132/dmtbs0603' size 16G autoextend off;
alter tablespace DMTBS07 add datafile  '/data03/pmsdb132/dmtbs0703' size 16G autoextend off;




---wap 网关触发器问题TRI_LOGON
set linesize 1000 pagesize 500
col TEXT for a50
col  OWNER for a15 
col  NAME for a20
col  TYPE for a10
select  OWNER,NAME,TYPE,TEXT from DBA_SOURCE where text like '%LOGON_TABLE%';

alter  trigger TRI_LOGON disable;
select OWNER,SEGMENT_NAME ,sum(BYTES)/1024/1024 size_mb from dba_segments where TABLESPACE_NAME='ZZ_MALS71' group by OWNER,SEGMENT_NAME;
truncate table  sys.LOG$INFORMATION;


alter tablespace RCOUNTDB add datafile '/opt/oracle/oradata/rcountdb/rcountdb03.dbf' size 8000M;





/*计算表空间使用情况(考虑了数据文件自动增长情况)*/
SELECT UPPER(F.TABLESPACE_NAME) AS tablespace_name,
       ROUND(D.AVAILB_BYTES, 2) AS size_gb,
       ROUND(D.MAX_BYTES, 2) AS max_size_gb,
       ROUND((D.AVAILB_BYTES - F.USED_BYTES), 2) AS used_size_gb,
       TO_CHAR(ROUND((D.AVAILB_BYTES - F.USED_BYTES) / D.AVAILB_BYTES * 100,
                     2),
               '999.99') AS pct_used,
       ROUND(F.USED_BYTES, 6) AS free_size_gb,
       F.MAX_BYTES AS max_block_size_mb
  FROM (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024 * 1024), 6) USED_BYTES,
               ROUND(MAX(BYTES) / (1024 * 1024 * 1024), 6) MAX_BYTES
          FROM SYS.DBA_FREE_SPACE
         GROUP BY TABLESPACE_NAME) F,
       (SELECT DD.TABLESPACE_NAME,
               ROUND(SUM(DD.BYTES) / (1024 * 1024 * 1024), 6) AVAILB_BYTES,
               ROUND(SUM(DECODE(DD.MAXBYTES, 0, DD.BYTES, DD.MAXBYTES)) /
                     (1024 * 1024 * 1024),
                     6) MAX_BYTES
          FROM SYS.DBA_DATA_FILES DD
         GROUP BY DD.TABLESPACE_NAME) D
 WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME
 ORDER BY 4 DESC;
 
---------表空间数据文件使用明细
SET PAGESIZE 1000 LINES 1320 ECHO OFF VERIFY OFF FEEDB OFF SPACE 1 TRIMSP ON
COMPUTE SUM OF a_byt t_byt f_byt ON REPORT
BREAK ON REPORT ON tablespace_name ON pf
COL tablespace_name FOR A17   TRU HEAD 'Tablespace|Name'
COL file_name       FOR A70   TRU HEAD 'Filename'
COL a_byt           FOR 9,990.999 HEAD 'Allocated|GB'
COL t_byt           FOR 9,990.999 HEAD 'Current|Used GB'
COL f_byt           FOR 9,990.999 HEAD 'Current|Free GB'
COL pct_free        FOR 990.0     HEAD 'File %|Free'
COL pf              FOR 990.0     HEAD 'Tbsp %|Free'
COL seq NOPRINT
DEFINE b_div=1073741824
--
SELECT 1 seq,
       b.tablespace_name,
       nvl(x.fs, 0) / y.ap * 100 pf,
       b.file_name file_name,
       b.bytes / &&b_div a_byt,
       NVL((b.bytes - SUM(f.bytes)) / &&b_div, b.bytes / &&b_div) t_byt,
       NVL(SUM(f.bytes) / &&b_div, 0) f_byt,
       NVL(SUM(f.bytes) / b.bytes * 100, 0) pct_free
  FROM dba_free_space f,
       dba_data_files b,
       (SELECT y.tablespace_name, SUM(y.bytes) fs
          FROM dba_free_space y
         GROUP BY y.tablespace_name) x,
       (SELECT x.tablespace_name, SUM(x.bytes) ap
          FROM dba_data_files x
         GROUP BY x.tablespace_name) y
 WHERE f.file_id(+) = b.file_id
   AND x.tablespace_name(+) = y.tablespace_name
   AND y.tablespace_name = b.tablespace_name
   AND f.tablespace_name(+) = b.tablespace_name
 GROUP BY b.tablespace_name,
          nvl(x.fs, 0) / y.ap * 100,
          b.file_name,
          b.bytes
UNION
SELECT 2 seq,
       tablespace_name,
       j.bf / k.bb * 100 pf,
       b.name file_name,
       b.bytes / &&b_div a_byt,
       a.bytes_used / &&b_div t_byt,
       a.bytes_free / &&b_div f_byt,
       a.bytes_free / b.bytes * 100 pct_free
  FROM v$temp_space_header a,
       v$tempfile b,
       (SELECT SUM(bytes_free) bf FROM v$temp_space_header) j,
       (SELECT SUM(bytes) bb FROM v$tempfile) k
 WHERE a.file_id = b.file#
 ORDER BY 1, 2, 4, 3;




---------------查看段在快照期间内的空间变化情况
column owner format a16
column object_name format a36
column start_day format a11
column block_increase format 9999999999

SELECT obj.owner,
       obj.object_name,
       to_char(sn.BEGIN_INTERVAL_TIME, 'RRRR-MON-DD') start_day,
       SUM(a.db_block_changes_delta) block_increase
  FROM dba_hist_seg_stat a, dba_hist_snapshot sn, dba_objects obj
 WHERE sn.snap_id = a.snap_id
   AND obj.object_id = a.obj#
   AND obj.owner NOT IN ('SYS', 'SYSTEM')
   AND end_interval_time BETWEEN to_timestamp('01-JAN-2000', 'DD-MON-RRRR') AND
       to_timestamp('02-FEB-2013', 'DD-MON-RRRR')
 GROUP BY obj.owner,
          obj.object_name,
          to_char(sn.BEGIN_INTERVAL_TIME, 'RRRR-MON-DD')
 ORDER BY obj.owner, obj.object_name ;






#####创建表空间
create    tablespace test1
logging|nologging--建立表空间时是否有重做日记
datafile   '/oradata/anixfs/test1.dbf' size 50M
extent management local autoallocate| uniform size  1M-----本地管理（建议uniform）
segment  space   management   auto|manual----自动|手动段管理
block   size  8K---数据块大小
AUTOEXTEND ON NEXT 100M MAXSIZE 10000M;--表空间自动扩展


create    tablespace test1
datafile   '/oradata/anixfs/test1.dbf' size 50M
extent management local  uniform size  1M
segment  space   management   auto
AUTOEXTEND off;








-----检查当前各表空间的数据文件，确认对应表空间使用的ASM磁盘组
SET LINES 200 PAGES 1000
COL tablespace_name FORMAT a21;
COL file#           FORMAT 999;
COL file_name       FORMAT a68;
COL status          FORMAT a9;
COL auex            FORMAT a4;
COL size(mb)        FORMAT 9999999;
SELECT TABLESPACE_NAME,
       FILE_ID "FILE#",
       FILE_NAME,
       ROUND(BYTES / 1024 / 1024) "SIZE(MB)",
       ROUND(MAXBYTES / 1024 / 1024) "MAXSIZE(MB)",
       --BLOCKS, 
       STATUS,
       AUTOEXTENSIBLE "AUEX"
  FROM DBA_DATA_FILES
 ORDER BY TABLESPACE_NAME, FILE_ID;


-----检查ASM磁盘组剩余空间
column gnum  format 999;
column gname format a12;
column au_mb format 9999;
column state format a10;
column type  format a10;
set lines 132 pages 1000;
SELECT group_number gnum,
       NAME gname,
       sector_size,
       block_size,
       allocation_unit_size / 1024 / 1024/1024 alloc_Gb,
       state,
       TYPE,
       total_mb/1024 total_GB,
       free_mb/1024 free_gb,
       required_mirror_free_mb/1024 rm_gb,
       usable_file_mb/1024 uf_gb,
       offline_disks
  FROM v$asm_diskgroup;
---
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
       a.FREE_MB / 1024 free_gb,
       trunc(a.FREE_MB/a.TOTAL_MB *100,2) pct_free
  FROM v$asm_diskgroup a order by  6;
------
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


set linesize 1000 pagesize 500
col path for a40
SELECT b.PATH
  FROM v$asm_disk b, v$asm_diskgroup a
 WHERE a.GROUP_NUMBER = b.GROUP_NUMBER
 ORDER BY 1;





set linesize 1000 pagesize 500
col chang_the_disk for a60
SELECT *
  FROM (SELECT 'chmod 660 ' || b.PATH chang_the_disk
          FROM v$asm_disk b, v$asm_diskgroup a
         WHERE a.GROUP_NUMBER = b.GROUP_NUMBER
        UNION
        SELECT 'chown grid:asmadmin ' || b.PATH chang_the_disk
          FROM v$asm_disk b, v$asm_diskgroup a
         WHERE a.GROUP_NUMBER = b.GROUP_NUMBER)
 ORDER BY 1 desc;







-----查询表空间数据文件
set linesize 1000 pagesize 500
col file_name for a60
SELECT TABLESPACE_NAME,
       file_name,
       BYTES / 1024 / 1024 / 1024 size_gb,
       status,
       ONLINE_STATUS,
       AUTOEXTENSIBLE
  FROM dba_data_files
/* WHERE  TABLESPACE_NAME = 'TBS_DTLDATA'
AND   a.AUTOEXTENSIBLE = 'YES'*/
 ORDER BY 1, 2;
------------数据库文件
SELECT NAME, VALUE FROM v$parameter WHERE NAME = 'db_files';

SELECT 'TABLESPACE', COUNT(*)
  FROM dba_tablespaces
UNION
SELECT 'DATAFILE', SUM(a.c1 + b.c2)
  FROM (SELECT COUNT(file_id) c1 FROM dba_data_files) a,
       (SELECT COUNT(file_id) c2 FROM dba_temp_files) bUNION
SELECT 'CONTROLFILE', COUNT(*)
  FROM v$controlfile;
-----数据文件自动增长检查
--for 10g and over
set linesize 300
set linesize 300
col file_name for a50
SELECT file_id,
       file_name,
       tablespace_name,
       status,
       online_status,
       autoextensible,
       (SELECT d.BIGFILE
          FROM dba_tablespaces d
         WHERE d.TABLESPACE_NAME = t.TABLESPACE_NAME
           AND rownum = 1) bigfile
  FROM dba_data_files t
 WHERE autoextensible <> 'NO'
UNION ALL
SELECT file_id,
       file_name,
       tablespace_name,
       status,
       '' online_status,
       autoextensible,
       (SELECT d.BIGFILE
          FROM dba_tablespaces d
         WHERE d.TABLESPACE_NAME = t.TABLESPACE_NAME
           AND rownum = 1) bigfile
  FROM dba_temp_files t
 WHERE autoextensible <> 'NO';


-------关闭数据文件自动扩展
set lines 132 pages 1000 
select 'alter database datafile '''||a.file_name ||''' autoextend off;' from dba_data_files a,dba_tablespaces b where a.TABLESPACE_NAME=b.TABLESPACE_NAME and a.AUTOEXTENSIBLE='YES' and b.BIGFILE='NO'
union all
select 'alter database tempfile '''||a.file_name ||''' autoextend off;' from DBA_TEMP_FILES a,dba_tablespaces b where a.TABLESPACE_NAME=b.TABLESPACE_NAME and a.AUTOEXTENSIBLE='YES' and b.BIGFILE='NO';




set lines 132 pages 1000 
select 'alter database datafile '''||a.file_name ||''' autoextend off;' from cdb_data_files a,dba_tablespaces b where a.TABLESPACE_NAME=b.TABLESPACE_NAME and a.AUTOEXTENSIBLE='YES' and b.BIGFILE='NO'
union all
select 'alter database tempfile '''||a.file_name ||''' autoextend off;' from cdb_TEMP_FILES a,dba_tablespaces b where a.TABLESPACE_NAME=b.TABLESPACE_NAME and a.AUTOEXTENSIBLE='YES' and b.BIGFILE='NO';




select t.TABLESPACE_NAME,sum(t.BYTES)/1024/1024/1024  from dba_temp_files t  group by t.TABLESPACE_NAME;
col FILE_NAME for a70
col TABLESPACE_NAME for a30
select  TABLESPACE_NAME,FILE_NAME,BYTES/1024/1024/1024 size_gb from dba_data_files where TABLESPACE_NAME='IDX_TS_ABIS_HZ';

select file_name  from dba_data_files a  where  a.AUTOEXTENSIBLE='YES' ;



---------移动数据文件
RMAN> sql "alter tablespace dlm  offline";
RMAN> copy datafile '/archive/dlm/dlm_data.dbf' to '+dlm_data/dlm/datafile/DLM.268.873998453';
SQL> alter database rename file '/archive/dlm/dlm_data.dbf' to '+dlm_data/dlm/datafile/DLM.268.873998453';
SQL> sql " alter tablespace dlm online ";


-----------数据文件自动扩展检查
set lines 132 pages 1000 
SELECT 'alter database datafile ''' || a.file_name || ''' autoextend off;'
  FROM dba_data_files a, dba_tablespaces b
 WHERE a.TABLESPACE_NAME = b.TABLESPACE_NAME
   AND a.AUTOEXTENSIBLE = 'YES'
   AND b.BIGFILE = 'NO'
UNION ALL
SELECT 'alter database  tempfile ''' || a.file_name || ''' autoextend off;'
  FROM DBA_TEMP_FILES a, dba_tablespaces b
 WHERE a.TABLESPACE_NAME = b.TABLESPACE_NAME
   AND a.AUTOEXTENSIBLE = 'YES'
   AND b.BIGFILE = 'NO';



-------获得表空间ddl语句
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('TABLESPACE', tablespace_name)
FROM   dba_tablespaces
WHERE  tablespace_name = DECODE(UPPER('&1'), 'ALL', tablespace_name, UPPER('&1'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON







----------------删除数据文件	
Restrictions for Dropping Datafiles : 
The following are restrictions for dropping datafiles and tempfiles: 
+ The database must be open. 
+ If a datafile is not empty, it cannot be dropped. 
+ You cannot drop the first or only datafile in a tablespace. 
+ This means that DROP DATAFILE cannot be used with a bigfile tablespace. 
+ You cannot drop datafiles in a read-only tablespace. 
+ You cannot drop datafiles in the SYSTEM tablespace. 
+ If a datafile in a locally managed tablespace is offline, it cannot be dropped. 
If you must remove a datafile that is not empty and that cannot be made empty by dropping schema objects, you must drop the tablespace that contains the datafile. 
for detail, please refer to DROP Datafile And Its Restrictions ( Doc ID 781225.1 ) 





-------创建语法：
CREATE [UNDO]  TABLESPACE tablespace_name          
[DATAFILE datefile_spec1 [,datefile_spec2] ......   
[{MININUM EXTENT integer [k|m]   
|BLOCKSIZE integer [k]   
|logging clause | FORCE LOGGING   
|DEFAULT {data_segment_compression} storage_clause   
|[online|offline]   
|[PERMANENT|TEMPORARY]   
|extent_manager_clause   
|segment_manager_clause}]




------查询表空间一周的增长
SELECT C.tablespace_name,
       D."Total(MB)",
       D."Used(MB)" - C."Used(MB)" AS "Increment(MB)",
       to_char(next_day(trunc(SYSDATE), 2) - 7, 'yyyy/mm/dd') || '--' ||
       to_char(next_day(trunc(SYSDATE), 2) - 7, 'yyyy/mm/dd') "TIME"
  FROM (SELECT B.name tablespace_name,
               CASE
                 WHEN B.name NOT LIKE 'UNDO%' THEN
                  round(A.tablespace_size * 8 / 1024)
                 WHEN B.name LIKE 'UNDO%' THEN
                  round(A.tablespace_size * 8 / 1024 / 2)
               END AS "Total(MB)",
               round(A.tablespace_usedsize * 8 / 1024) "Used(MB)",
               A.rtime
          FROM DBA_HIST_TBSPC_SPACE_USAGE A, v$tablespace B
         WHERE A.tablespace_id = B.TS#
           AND to_char(to_date(REPLACE(rtime, '/', NULL),
                               'mmddyyyy hh24:mi:ss'), 'yyyymmdd hh24:mi') =
               to_char(next_day(trunc(SYSDATE), 2) - 14, 'yyyymmdd hh24:mi')) C,
       (SELECT B.name tablespace_name,
               CASE
                 WHEN B.name NOT LIKE 'UNDO%' THEN
                  round(A.tablespace_size * 8 / 1024)
                 WHEN B.name LIKE 'UNDO%' THEN
                  round(A.tablespace_size * 8 / 1024 / 2)
               END AS "Total(MB)",
               round(A.tablespace_usedsize * 8 / 1024) "Used(MB)",
               A.rtime
          FROM DBA_HIST_TBSPC_SPACE_USAGE A, v$tablespace B
         WHERE A.tablespace_id = B.TS#
           AND to_char(to_date(REPLACE(rtime, '/', NULL),
                               'mmddyyyy hh24:mi:ss'), 'yyyymmdd hh24:mi') =
               to_char(next_day(trunc(SYSDATE), 2) - 7, 'yyyymmdd hh24:mi')) D
 WHERE C.tablespace_name = D.tablespace_name;



/********************************************************************/
                       空间增长监控
/********************************************************************/
-- Create table
create table TAB_SNAP_TABLESPACE_DAY
(
  tablespace_name VARCHAR2(30),
  datafile_count  NUMBER,
  size_gb         NUMBER,
  free_gb         NUMBER,
  used_gb         NUMBER,
  maxfree         NUMBER,
  pct_used        NUMBER,
  pct_free        NUMBER,
  snap_time       DATE
)
tablespace INDEXTS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );



CREATE OR REPLACE PROCEDURE p_snap_kongjian_day AS
BEGIN
  INSERT INTO tab_snap_segment_day
    SELECT owner,
           segment_name,
           partition_name,
           segment_type,
           tablespace_name,
           bytes,
           SYSDATE
      FROM dba_segments;
  COMMIT;

  INSERT INTO tab_snap_lob_day
    SELECT owner,
           table_name,
           column_name,
           segment_name,
           tablespace_name,
           index_name,
           SYSDATE
      FROM dba_lobs;
  COMMIT;

  INSERT INTO tab_snap_tablespace_day
    SELECT df.tablespace_name,
           COUNT(*) datafile_count,
           ROUND(SUM(df.BYTES) / 1048576 / 1024, 2) size_gb,
           ROUND(SUM(free.BYTES) / 1048576 / 1024, 2) free_gb,
           ROUND(SUM(df.BYTES) / 1048576 / 1024 -
                 SUM(free.BYTES) / 1048576 / 1024,
                 2) used_gb,
           ROUND(MAX(free.maxbytes) / 1048576 / 1024, 2) maxfree,
           100 - ROUND(100.0 * SUM(free.BYTES) / SUM(df.BYTES), 2) pct_used,
           ROUND(100.0 * SUM(free.BYTES) / SUM(df.BYTES), 2) pct_free,
           SYSDATE
      FROM dba_data_files df,
           (SELECT tablespace_name,
                   file_id,
                   SUM(BYTES) BYTES,
                   MAX(BYTES) maxbytes
              FROM dba_free_space
             WHERE bytes > 1024 * 1024
             GROUP BY tablespace_name, file_id) free
     WHERE df.tablespace_name = free.tablespace_name(+)
       AND df.file_id = free.file_id(+)
     GROUP BY df.tablespace_name
     ORDER BY 8;
  COMMIT;
END;

 
 ---每个表空间每天空间增长
SELECT to_char(snap_time, 'yyyymmdd'),
       tablespace_name,
       free_gb,
       used_gb,
       used_gb - lag(used_gb, 1, used_gb) over(PARTITION BY tablespace_name ORDER BY snap_time) grow_byte
  FROM dbmon.tab_snap_tablespace_day
 ORDER BY 2, 1;

SELECT to_char(snap_time, 'yyyymmdd'),
       tablespace_name,
       free_gb,
       used_gb,
       used_gb - lag(used_gb, 1, used_gb) over(PARTITION BY tablespace_name ORDER BY snap_time) grow_byte
  FROM dbmon.tab_snap_tablespace_day a
 WHERE a.TABLESPACE_NAME = 'CDCP_DATA'
 ORDER BY 2, 1;


SELECT to_char(snap_time, 'yyyymmdd'),
       tablespace_name,
       free_gb,
       used_gb,
       used_gb - lag(used_gb, 1, used_gb) over(PARTITION BY tablespace_name ORDER BY snap_time) grow_byte
  FROM dbmon.tab_snap_tablespace_day a
 WHERE a.TABLESPACE_NAME = 'USERS'
 ORDER BY 2, 1;




---全库每天空间增长
SELECT date1,
       daybyte,
       a.daybyte - lag(a.daybyte, 1, a.daybyte) over(ORDER BY a.date1) grow_byte
  FROM (SELECT to_char(snap_time, 'yyyymmdd') date1, SUM(used_gb) daybyte
          FROM dbmon.tab_snap_tablespace_day
         WHERE tablespace_name NOT LIKE '%UNDO%'
         GROUP BY to_char(snap_time, 'yyyymmdd')) a;


-----------小业务机器上的 查询表空间大小的语句
select host_name,target_name,sum(TABLESPACE_USED_SIZE)/1024/1024/1024 gb from MGMT$DB_TABLESPACES_ALL 
	where target_type in ('oracle_database','rac_database')
	and TABLESPACE_NAME not like '%TEMP%'
  and TABLESPACE_NAME not like '%UNDO%'
  and TABLESPACE_NAME not like '%SYS%'
  and TABLESPACE_NAME not like '%TMP%'
  and TABLESPACE_NAME not like '%USER%'
	group by host_name,target_name
  order by 3;






-------网管中心所有数据库表空间查询  -----小业务机


col host_name for a30
col host_name for a30
col COLUMN_LABEL for a30

select mt.host_name,
       mt.host_ip,
       M.COLUMN_LABEL,
       M1.KEY_VALUE,
       round(M1.VALUE_AVERAGE, 2) as usered_rate,
       round(M1.VALUE_AVERAGE, 2) -
       (select round(VALUE_AVERAGE, 2)
          from MGMT_METRICS_1DAY m2
         where m1.target_guid = m2.target_guid
           and m1.metric_guid = m2.metric_guid
           and m1.key_value = m2.key_value
           and m2.rollup_timestamp = trunc(sysdate - 7)) pct
  from sysman.MGMT_METRICS_1DAY M1,
       sysman.MGMT_METRICS      M,
       sysman.MGMT_TARGETS      T,
       sysman.MGMT_TARGET_TYPES TT,
       sysman.my_target         mt
 where M1.METRIC_GUID = M.METRIC_GUID
   and m1.target_guid = t.target_guid
   and TT.TARGET_TYPE = T.TARGET_TYPE
   and T.TARGET_TYPE = M.TARGET_TYPE
   and T.TYPE_META_VER = M.TYPE_META_VER
   AND (t.category_prop_1 = m.category_prop_1 OR m.category_prop_1 = ' ')
   AND (t.category_prop_2 = m.category_prop_2 OR m.category_prop_2 = ' ')
   AND (t.category_prop_3 = m.category_prop_3 OR m.category_prop_3 = ' ')
   AND (t.category_prop_4 = m.category_prop_4 OR m.category_prop_4 = ' ')
   and (T.CATEGORY_PROP_5 = M.CATEGORY_PROP_5 or M.CATEGORY_PROP_5 = ' ')
   and t.host_name = mt.host_name
   and M.COLUMN_LABEL in ('Tablespace Space Used (%)')
   and m1.key_value not like '%UNDO%'
   and m1.key_value not like '%TEMP%'
   and m1.rollup_timestamp = trunc(sysdate - 1)
   and mt.host_ip='10.212.170.48'
 order by 1, 2, 3;











/****************************************/
段自动顾问
/***********************************/


1、dbms_space.asa_recommendations
SELECT 'Segment Advice --------------------------' || chr(10) ||
       'TABLESPACE_NAME  : ' || tablespace_name || chr(10) ||
       'SEGMENT_OWNER    : ' || segment_owner || chr(10) ||
       'SEGMENT_NAME     : ' || segment_name || chr(10) ||
       'ALLOCATED_SPACE  : ' || allocated_space || chr(10) ||
       'RECLAIMABLE_SPACE: ' || reclaimable_space || chr(10) ||
       'RECOMMENDATIONS  : ' || recommendations || chr(10) ||
       'SOLUTION 1       : ' || c1 || chr(10) || 'SOLUTION 2       : ' || c2 ||
       chr(10) || 'SOLUTION 3       : ' || c3 Advice
  FROM TABLE(dbms_space.asa_recommendations('FALSE', 'FALSE', 'FALSE'));

SELECT 'Segment Advice --------------------------' || chr(10) ||
       'TABLESPACE_NAME  : ' || tablespace_name || chr(10) ||
       'SEGMENT_OWNER    : ' || segment_owner || chr(10) ||
       'SEGMENT_NAME     : ' || segment_name || chr(10) ||
       'ALLOCATED_SPACE  : ' || allocated_space || chr(10) ||
       'RECLAIMABLE_SPACE: ' || reclaimable_space || chr(10) ||
       'RECOMMENDATIONS  : ' || recommendations || chr(10) ||
       'SOLUTION 1       : ' || c1 || chr(10) || 'SOLUTION 2       : ' || c2 ||
       chr(10) || 'SOLUTION 3       : ' || c3 Advice
  FROM TABLE(dbms_space.asa_recommendations('TRUE', 'TRUE', 'FALSE'));



all_runs：为true则存储过程返回历次运行的结果，而为false则仅返回最近一次运行的结果。
show_manual：为true则存储过程返回手工执行段顾问的结果，为false则存储过程返回自动运行段顾问的结果。
show_findings：仅显示分析结果而不显示建议。


2、手动查询视图
SELECT 'Task Name        : ' || f.task_name || chr(10) ||
       'Start Run Time   : ' ||
       TO_CHAR(execution_start, 'dd-mon-yy hh24:mi') || chr(10) ||
       'Segment Name     : ' || o.attr2 || chr(10) || 'Segment Type     : ' ||
       o.type || chr(10) || 'Partition Name   : ' || o.attr3 || chr(10) ||
       'Message          : ' || f.message || chr(10) ||
       'More Info        : ' || f.more_info || chr(10) ||
       '------------------------------------------------------' Advice
  FROM dba_advisor_findings   f,
       dba_advisor_objects    o,
       dba_advisor_executions e
 WHERE o.task_id = f.task_id
   AND o.object_id = f.object_id
   AND f.task_id = e.task_id
   AND e. execution_start > SYSDATE - 1
   AND e.advisor_name = 'Segment Advisor'
 ORDER BY f.task_name;




3、手工生成段建议
执行包需要dbms_advisor权限： grant advisor to dbmon;

创建段顾问任务，指定create_task的advisor_name参数为“段顾问”。查询dba_advisor_definitions来获得所有有效的顾问列表。
select * from dba_advisor_definitions;  

DECLARE
  my_task_id   NUMBER;
  obj_id       NUMBER;
  my_task_name VARCHAR2(100);
  my_task_desc VARCHAR2(500);
BEGIN
  my_task_name := 'BIG_TABLE Advice';
  my_task_desc := 'Manual Segment Advisor Run';
  ---------  
  -- Step 1 创建一个任务  
  ---------  
  dbms_advisor.create_task(advisor_name => 'Segment Advisor',
                           task_id => my_task_id, 
                           task_name => my_task_name,
                           task_desc => my_task_desc);
  ---------  
  -- Step 2 为这个任务分配一个对象  
  ---------  
  dbms_advisor.create_object(task_name => my_task_name,
                             object_type => 'TABLE', 
                             attr1 => 'U1',
                             attr2 => 'BIG_TABLE', 
                             attr3 => NULL,
                             attr4 => NULL,
                              attr5 => NULL,
                             object_id => obj_id);
  ---------  
  -- Step 3 设置任务参数  
  ---------  
  dbms_advisor.set_task_parameter(task_name => my_task_name,
                                  parameter => 'recommend_all',
                                  VALUE => 'TRUE');
  ---------  
  -- Step 4 执行这个任务  
  ---------  
  dbms_advisor.execute_task(my_task_name);
END;
/


4、删除一个任务：
exec dbms_advisor.delete_task('BIG_TABLE Advice');  
  










----查询表空间的碎片程度
SELECT tablespace_name, COUNT(tablespace_name)
  FROM dba_free_space
 GROUP BY tablespace_name
HAVING COUNT(tablespace_name) > 10;
ALTER tablespace NAME coalesce;
ALTER TABLE NAME deallocate unused;
CREATE OR REPLACE view ts_blocks_v AS
  SELECT tablespace_name,
         block_id,
         bytes,
         blocks,
         'free space' segment_name
    FROM dba_free_space
  UNION ALL
  SELECT tablespace_name, block_id, bytes, blocks, segment_name
    FROM dba_extents;
SELECT * FROM ts_blocks_v;
SELECT tablespace_name, SUM(bytes), MAX(bytes), COUNT(block_id)
  FROM dba_free_space
 GROUP BY tablespace_name;


--------表空间碎片查询
column fsfi format 999,99 
SELECT tablespace_name,
       sqrt(MAX(blocks) / SUM(blocks)) * (100 / sqrt(sqrt(COUNT(blocks)))) fsfi
  FROM dba_free_space
 GROUP BY tablespace_name
 ORDER BY 1;
整理表空间碎片
1、自由范围的碎片整理 
---- （1）表空间的pctincrease值为非0 
---- 可以将表空间的缺省存储参数pctincrease改为非0。一般将其设为1，如：  
       alter tablespace temp default storage(pctincrease 1);
---- 这样smon便会将自由范围自动合并。也可以手工合并自由范围：  
       alter tablespace temp coalesce;
2、exp/imp


---------------------------查询表空间碎片
create table SPACE_TEMP (
 TABLESPACE_NAME        CHAR(30),
 CONTIGUOUS_BYTES       NUMBER)
/

declare
  cursor query is select *
          from dba_free_space
                  order by tablespace_name, block_id;
  this_row        query%rowtype;
  previous_row    query%rowtype;
total           number;

begin
  open query;
  fetch query into this_row;
  previous_row := this_row;
  total := previous_row.bytes;
  loop
 fetch query into this_row;
     exit when query%notfound;
     if this_row.block_id = previous_row.block_id + previous_row.blocks then
        total := total + this_row.bytes;
        insert into SPACE_TEMP (tablespace_name)
                  values (previous_row.tablespace_name);
     else
        insert into SPACE_TEMP values (previous_row.tablespace_name,
               total);
        total := this_row.bytes;
     end if;
previous_row := this_row;
  end loop;
  insert into SPACE_TEMP values (previous_row.tablespace_name,
                           total);
end;
.
/

set pagesize 60
set newpage 0
set echo off
ttitle center 'Contiguous Extents Report'  skip 3
break on "TABLESPACE NAME" skip page duplicate
spool contig_free_space.lis
rem
column "CONTIGUOUS BYTES"       format 999,999,999,999
column "COUNT"                  format 999
column "TOTAL BYTES"            format 999,999,999,999
column "TODAY"   noprint new_value new_today format a1
rem
select TABLESPACE_NAME  "TABLESPACE NAME",
       CONTIGUOUS_BYTES "CONTIGUOUS BYTES"
from SPACE_TEMP
where CONTIGUOUS_BYTES is not null
order by TABLESPACE_NAME, CONTIGUOUS_BYTES desc;

select tablespace_name, count(*) "# OF EXTENTS",
         sum(contiguous_bytes) "TOTAL BYTES"
from space_temp
group by tablespace_name;

spool off

drop table SPACE_TEMP
/











Script to Detect Tablespace Fragmentation (文档 ID 1020182.6)
========
Script : tfstsfgm
========
SET ECHO off 
REM NAME:TFSTSFRM.SQL 
REM USAGE:"@path/tfstsfgm" 
REM ------------------------------------------------------------------------ 
REM REQUIREMENTS: 
REM    SELECT ON DBA_FREE_SPACE 
REM ------------------------------------------------------------------------ 
REM PURPOSE: 
REM    The following is a script that will determine how many extents 
REM    of contiguous free space you have in Oracle as well as the  
REM total amount of free space you have in each tablespace. From  
REM    these results you can detect how fragmented your tablespace is.  
REM   
REM    The ideal situation is to have one large free extent in your  
REM    tablespace. The more extents of free space there are in the  
REM    tablespace, the more likely you  will run into fragmentation  
REM    problems. The size of the free extents is also  very important.  
REM    If you have a lot of small extents (too small for any next   
REM    extent size) but the total bytes of free space is large, then  
REM    you may want to consider defragmentation options.  
REM ------------------------------------------------------------------------ 
REM DISCLAIMER: 
REM    This script is provided for educational purposes only. It is NOT  
REM    supported by Oracle World Wide Technical Support. 
REM    The script has been tested and appears to work as intended. 
REM    You should always run new scripts on a test instance initially. 
REM ------------------------------------------------------------------------ 
REM Main text of script follows: 
 
create table SPACE_TEMP (   
 TABLESPACE_NAME        CHAR(30),   
 CONTIGUOUS_BYTES       NUMBER)   
/   
   
declare   
  cursor query is select *   
          from dba_free_space   
                  order by tablespace_name, block_id;   
  this_row        query%rowtype;   
  previous_row    query%rowtype;   
total           number;   
   
begin   
  open query;   
  fetch query into this_row;   
  previous_row := this_row;   
  total := previous_row.bytes;   
  loop   
 fetch query into this_row;   
     exit when query%notfound;   
     if this_row.block_id = previous_row.block_id + previous_row.blocks then   
        total := total + this_row.bytes;   
        insert into SPACE_TEMP (tablespace_name)   
                  values (previous_row.tablespace_name);   
     else   
        insert into SPACE_TEMP values (previous_row.tablespace_name,   
               total);   
        total := this_row.bytes;   
     end if;   
previous_row := this_row;   
  end loop;   
  insert into SPACE_TEMP values (previous_row.tablespace_name,   
                           total);   
end;   
.   
/   
   
set pagesize 60   
set newpage 0   
set echo off   
ttitle center 'Contiguous Extents Report'  skip 3   
break on "TABLESPACE NAME" skip page duplicate   
spool contig_free_space.lis   
rem   
column "CONTIGUOUS BYTES"       format 999,999,999   
column "COUNT"                  format 999   
column "TOTAL BYTES"            format 999,999,999   
column "TODAY"   noprint new_value new_today format a1   
rem   
select TABLESPACE_NAME  "TABLESPACE NAME",   
       CONTIGUOUS_BYTES "CONTIGUOUS BYTES"   
from SPACE_TEMP   
where CONTIGUOUS_BYTES is not null   
order by TABLESPACE_NAME, CONTIGUOUS_BYTES desc;   
   
select tablespace_name, count(*) "# OF EXTENTS",   
         sum(contiguous_bytes) "TOTAL BYTES"    
from space_temp   
group by tablespace_name;   
   
spool off   
   
drop table SPACE_TEMP   
/ 

Script to Report Tablespace Free and Fragmentation (文档 ID 1019709.6)
======= 
Script: 
======= 
 
SET ECHO off 
REM NAME:   TFSFSSUM.SQL 
REM USAGE:"@path/tfsfssum" 
REM ------------------------------------------------------------------------ 
REM REQUIREMENTS: 
REM  SELECT ON DBA_FREE_SPACE< DBA_DATA_FILES 
REM ------------------------------------------------------------------------ 
REM AUTHOR:  
REM    Cary Millsap,  Oracle  Corporation      
REM    (c)1994 Oracle Corporation      
REM ------------------------------------------------------------------------ 
REM PURPOSE: 
REM    Displays tablespace free space and fragmentation for each 
REM    tablespace,  Prints the total size, the amount of space available, 
REM    and a summary of freespace fragmentation in that tablespace. 
REM ------------------------------------------------------------------------ 
REM EXAMPLE: 
REM     
REM        Database Freespace Summary  
REM 
REM                       Free     Largest       Total      Available   Pct  
REM       Tablespace     Frags    Frag (KB)       (KB)         (KB)     Used 
REM    ---------------- -------- ------------ ------------ ------------ ----  
REM    DES2                    1       30,210    40,960       30,210     26 
REM    DES2_I                  1       22,848    30,720       22,848     26 
REM    RBS                    16       51,198    59,392       55,748      6 
REM    SYSTEM                  3        4,896    92,160        5,930     94 
REM    TEMP                    5          130       550          548      0  
REM    TOOLS                  10       76,358   117,760       87,402     26 
REM    USERS                   1           46     1,024           46     96 
REM                     --------              ------------ ------------ 
REM    sum                    37                342,566      202,732 
REM  
REM ------------------------------------------------------------------------ 
REM DISCLAIMER: 
REM    This script is provided for educational purposes only. It is NOT  
REM    supported by Oracle World Wide Technical Support. 
REM    The script has been tested and appears to work as intended. 
REM    You should always run new scripts on a test instance initially. 
REM ------------------------------------------------------------------------ 
REM Main text of script follows: 
 
ttitle - 
   center  'Database Freespace Summary'  skip 2 
 
comp sum of nfrags totsiz avasiz on report 
break on report 
 
col tsname  format         a16 justify c heading 'Tablespace' 
col nfrags  format     999,990 justify c heading 'Free|Frags' 
col mxfrag  format 999,999,990 justify c heading 'Largest|Frag (KB)' 
col totsiz  format 999,999,990 justify c heading 'Total|(KB)' 
col avasiz  format 999,999,990 justify c heading 'Available|(KB)' 
col pctusd  format         990 justify c heading 'Pct|Used' 
 
select 
  total.tablespace_name                       tsname, 
  count(free.bytes)                           nfrags, 
  nvl(max(free.bytes)/1024,0)                 mxfrag, 
  total.bytes/1024                            totsiz, 
  nvl(sum(free.bytes)/1024,0)                 avasiz, 
  (1-nvl(sum(free.bytes),0)/total.bytes)*100  pctusd 
from 
  dba_data_files  total, 
  dba_free_space  free 
where 
  total.tablespace_name = free.tablespace_name(+) 
  and total.file_id=free.file_id(+)
group by 
  total.tablespace_name, 
  total.bytes 
/ 








