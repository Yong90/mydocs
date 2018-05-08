#####查看spfilelocation(show parameter pfile/spfile;)
show parameter spfile

######从 spfile获取pfile
Sqlplus  / nolog
connect / as sysdba
create pfile='/directory_name1/pfilesid.ora' from '/directory_name2/spfile';
create pfile='/directory_name1/pfilesid.ora' from spfile='/directory_name2/spfile';

sqlplus / nolog
connect / as sysdba
create pfile='/directory_name1/pfilesid.ora'  from spfile;
create pfile='/directory_name1/pfilesid.ora' from  spfile='/directory_name2/spfile';

#####从 pfile获取spfile
Shutdown immediate
create '/directory_name1/spfile'  from pfile='/directory_name2/pfile';
create spfile='/directory_name1/spfile' from pfile='/directory_name2/pfile';

shutdown immediate
create '/directory_name1/spfile'  from pfile='/directory_name2/pfile';
create spfile='/directory_name1/spfile' from pfile='/directory_name2/pfile';

######动态修改参数
alter   system    set parameter_name=value scope=spfile|both|memory



show spparameter timed_statistics

-----数据库内存参数查询
set linesize 1000 pagesize 500
col name for a30
col value for a30
SELECT a.INST_ID,a.NAME, a.TYPE, a.VALUE
  FROM gv$parameter a
 WHERE a.NAME IN
       ('memory_max_target', 'memory_target', 'sga_target', 'sga_max_size',
        'db_cache_size', 'shared_pool_size', 'pga_aggregate_target',
        'java_pool_size', 'large_pool_size', 'log_buffer', 'db_files',
        'control_files', 'undo_management', 'remote_login_passwordfile',
        'remote_os_roles', 'max_dump_file_size', 'open_cursors',
        'cursor_sharing');


--重要内存参数
col value for a30
select name, round(value/1024/1024/1024,2) size_gb
  from v$parameter t
 where t.name in ('sga_max_size',
                  'sga_target',
                  'db_cache_size',
                  'shared_pool_size',
                  'memory_max_target',
                  'memory_target',
                  'process',
                  'session_cached_cursors',
                  'large_pool_size');


select a.ksppinm, b.ksppstvl
  from sys.xj_v_xksppi a, sys.xj_v_xksppcv b
 where a.indx = b.indx
       and a.ksppinm in ('memory_max_target', 'memory_target', 'sga_target', 'sga_max_size',
        'db_cache_size', 'shared_pool_size', 'pga_aggregate_target',
        'java_pool_size', 'large_pool_size', 'log_buffer', 'db_files',
        'control_files', 'undo_management', 'remote_login_passwordfile',
        'remote_os_roles', 'max_dump_file_size', 'open_cursors',
        'cursor_sharing', 'streams_pool_size', 'streams_pool_size',
        '_gc_policy_time', '_undo_autotune', 'deferred_segment_creation',
        '_in_memory_undo');

create view  sys.xj_v_xksppi as select * from sys.x$ksppi;
create view  sys.xj_v_xksppcv as select * from sys.x$ksppcv;
grant select on sys.xj_v_xksppi to system;
grant select on sys.xj_v_xksppcv to system;


set linesize 2000 pagesize 500
col ksppinm for a50
col ksppstvl for a30
select a.ksppinm, b.ksppstvl
  from sys.x$ksppi a, sys.x$ksppcv b
 where a.indx = b.indx
   and a.ksppinm in  ('_datafile_write_errors_crash_instance','_enable_pdb_close_abort','_enable_pdb_close_noarchivelog');








select a.ksppinm, b.ksppstvl
  from sys.x$ksppi a, sys.x$ksppcv b
 where a.indx = b.indx
   and a.ksppinm in ('_entry_size',
'_bct_public_dba_buffer_size',
'_bct_buffer_allocation_max');




set linesize 1000 pagesize 800
col value for a30
col name for a30
SELECT NAME, VALUE
  FROM v$parameter t
 WHERE t.name IN ('memory_max_target',
                  'memory_target',
                  'sga_target',
                  'sga_max_size',
                  'db_cache_size',
                  'shared_pool_size',
                  'pga_aggregate_target',
                  'java_pool_size',
                  'large_pool_size',
                  'log_buffer',
                  'db_files',
                  'control_files',
                  'undo_management',
                  'remote_login_passwordfile',
                  'remote_os_roles',
                  'max_dump_file_size',
                  'open_cursors',
                  'o7_dictionary_accessibility',
                  'cursor_sharing',
                  'streams_pool_size',
                  'streams_pool_size',
                  '_gc_policy_time',
                  'audit_trail',
                  '_ktb_debug_flags',
                  '_optimizer_use_feedback')









-------参数查询
col name for a30
col value for a30
SELECT a.NAME, a.TYPE, a.VALUE
  FROM v$parameter a
 WHERE a.NAME IN
       ('sga_max_size', 'sga_target', 'db_cache_size', 'shared_pool_size',
        'pga_aggregate_target', 'java_pool_size', 'large_pool_size',
        'streams_pool_size','spfile');

--------查询隐含参数
col ksppinm for a30
col ksppstvl for a30
select a.ksppinm, b.ksppstvl
  from sys.x$ksppi a, sys.x$ksppcv b
 where a.indx = b.indx
   and a.ksppinm in ('_gc_policy_time',
                     '_optimizer_use_feedback',
                     '_optimizer_use_feedback',
                     '_ktb_debug_flags');
alter system set "_undo_autotune" = false;

alter system set memory_target=0 scope=spfile sid='2';




------查询trace文件路径
select dst || '/' || lower(dbname) || '_ora_' || process || '.trc'
  from (select (select value from v$parameter where name = 'user_dump_dest') dst,
               (select name from v$database where rownum = 1) dbname,
               p.spid process
          from v$process p, v$session s
         where p.addr = s.PADDR
           and s.sid in (select sid from v$mystat where rownum = 1));


------解析命中率
SELECT SUM(pinhits) / SUM(pins) * 100 FROM v$librarycache;
SELECT SUM(gets), SUM(getmisses), 100 * SUM(gets - getmisses) / SUM(gets)
  FROM v$rowcache
 WHERE gets > 0;


-------修改shared pool 步骤
首先增大sga_target再次更改sga_max_size 最后更改shared_pool_size
Alter system set sga_target=500M  scope=both

查看执行计划
Select * from  table(dbms_xplan.display_cursor('sql的id'));

设置shared_pool的大小
SELECT shared_pool_size_for_estimate SP,
estd_lc_size                  EL,
estd_lc_memory_objects        ELM,
estd_lc_time_saved            ELT,
estd_lc_time_saved_factor     ELTS,
estd_lc_memory_object_hits    ELMO
  FROM v$shared_pool_advice;

--------不同share_pool尺寸下，具体的响应时间
SELECT 'Shared Pool' component,
       shared_pool_size_for_estimate estd_sp_size,
       estd_lc_time_saved_factor parse_time_factor,
       CASE
         WHEN current_parse_time_elapsed_s + adjustment_s < 0 THEN
          0
         ELSE
          current_parse_time_elapsed_s + adjustment_s
       END response_time
  FROM (SELECT a.shared_pool_size_for_estimate,
               a.shared_pool_size_factor,
               a.estd_lc_time_saved_factor,
               a.estd_lc_time_saved,
               e.value / 100 current_parse_time_elapsed_s,
               c.estd_lc_time_saved - a.estd_lc_time_saved adjustment_s
          FROM v$shared_pool_advice a,
               (SELECT * FROM v$sysstat WHERE NAME = 'parse time elapsed') e,
               (SELECT estd_lc_time_saved
                  FROM v$shared_pool_advice
                 WHERE shared_pool_size_factor = 1) c) d



----在不适用trace的情况下查找大的内存或硬盘读取
SELECT a.SQL_TEXT,
       a.SQL_ID,
       a.DISK_READS,
       a.BUFFER_GETS,
       a.OPTIMIZER_MODE,
       a.OPTIMIZER_COST
  FROM v$sqlarea a
 WHERE a.DISK_READS > 1000
   AND a.BUFFER_GETS > 1000
 ORDER BY a.DISK_READS DESC; -------磁盘和内存读取都大于1000的sql



我们可以通过查询v$db_object_cache来显示library cache中有哪些对象被缓存，以及这些对象的大小尺寸。比如，我们可以用下面的SQL语句来显示每个namespace中，大小尺寸排在前3名的对象： 
SELECT *
  FROM (SELECT row_number() over(PARTITION BY namespace ORDER BY sharable_mem DESC) size_rank,
               namespace,
               sharable_mem,
               substr(NAME, 1, 50) NAME
          FROM v$db_object_cache
         ORDER BY sharable_mem DESC)
 WHERE size_rank <= 3
 ORDER BY namespace, size_rank;




通过dbms_shared_pool.keep来将较高指标（x$ksmlru.ksmlrsiz、count(X$KSMLRU.KSMLRHON)、X$KSMLRU.KSMLRnum）或者java类固定到shared_pool中，以及使用共享SQL、PL/SQL和java源代码，可以修改参数cursor_sharing使用强制SQL共享。
----共享池碎片化
-----查找争用和碎片化
SELECT ksmlrhon, ksmlrsiz, ksmlrses
  FROM x$ksmlru
 WHERE ksmlrsiz > 1000
 ORDER BY ksmlrsizDESC;
SELECT SUM(ksmchsiz) / 1024 / 1024 || 'Mb' "tot_sp_mem" FROM x$ksmsp;
------共享池碎片化
SELECT ksmchcls"chnkclass",
       SUM(ksmchsiz) "sumchunktypemem",
       MAX(ksmchsiz) "largstofchksthistyp",
       COUNT(1) "numofchksthistyp",
       round((SUM(ksmchsiz) / tot_sp_mem.totspmem), 2) * 100 || '%' "PctTotSPMem"
  FROM x$ksmsp, (SELECTSUM(ksmchsiz) totspmemFROMx$ksmsp) tot_sp_mem
 GROUP BY ksmchcls, tot_sp_mem.totspmem
 ORDER BY SUM(ksmchsiz);

-----共享池空闲内存
SELECT  *  from  v$sgastat  where  name = 'free memory'   and  pool = 'shared pool';
------java池空闲内存
SELECT  *  from  v$sgastat   where   name = 'free memory'   and  pool = 'java pool';

----库缓存命中率和缓存重载率
SELECT  --a.NAMESPACE,
 round((SUM(a.PINHITS) / SUM(a.PINS)), 4) * 100 || '%' "row cache hit ratio"
   FROM v$librarycache  a
 ORDER BY a.NAMESPACE;

SELECT a.NAMESPACE,
----round((SUM(a.PINHITS) / SUM(a.PINS)), 4) * 100 || '%' "row cache hit ratio",
round(decode(a.PINS, 0, 0, a.RELOADS / a.PINS), 4) * 100 || '%' "Reload ratio"   FROM  v$librarycache  a  ORDER BY a.NAMESPACE;

-------硬解析
SELECT  a.VALUE"total_num",
       b.VALUE"hard_num",
       round(b.VALUE / a.VALUE, 4) * 100 || '%' "hardparseratio"
  FROM v$sysstata, v$sysstatb
 WHERE a.NAME = 'parse count (total)'
   AND b.NAME = 'parse count (hard)';

SELECT   a.SQL_TEXT, a.PARSE_CALLS, a.EXECUTIONS
  FROM v $sqlarea  a
 WHERE  a.PARSE_CALLS > 100
   AND a.KEPT_VERSIONS = 0
   AND a.EXECUTIONS < 2 * a.PARSE_CALLS;










具体db_cache_size建议大小可以使用下列语句查询：
SELECT a.SIZE_FOR_ESTIMATE  cache_size,
       a.SIZE_FACTOR,
a.BUFFERS_FOR_ESTIMATE   BUFFERS,
       a.ESTD_PHYSICAL_READ_FACTOR  P_READ_FACTOR,
       a.ESTD_PHYSICAL_READS    P_READS,
       a.ESTD_PHYSICAL_READ_TIME   P_READ_TIME
  FROM v$db_cache_advice a
 WHERE a.NAME = 'DEFAULT'
   AND a.BLOCK_SIZE =
       (SELECT VALUE FROM v$parameter WHERE NAME = 'db_block_size');





------查看数据库对象对buffer cache 的使用状态
SELECT b.OWNER || '.' || b.OBJECT_NAME, a.STATUS, COUNT(*) blocks
  FROM v$bh a, dba_objects b
 WHERE a.OBJD = b.DATA_OBJECT_ID
 GROUP BY b.OWNER || '.' || b.OBJECT_NAME, a.STATUS
 ORDER BY blocks DESC;
------清空buffer_cache
alter system flush buffer_cache;



-------段延迟分配11gR2
参数deferred_segment_creation  默认true
可以在建表时加参数立即分配段
 create table tbl_seg(
 reg_id number,
 reg_name varchar2(200))
segment creation immediate;







直接路径读取的隐含参数.
KSPPINM                        KSPPSTVL            KSPPDESC
 _small_table_threshold        2869        l          ower threshold level of table size for direct reads
 _serial_direct_read        FALSE          enable direct read in serial
