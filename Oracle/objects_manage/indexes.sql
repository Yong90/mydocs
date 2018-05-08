1、索引类型
二叉树           默认类型，适合用于基数（差异程度较高）较高的列，默认索引类型
IOT              大多数列包含在主键时使用可以增加性能
唯一索引         唯一性，经常用在唯一约束和主键约束，也可以不依赖约束
反向键索引       二叉树索引的一个类型，用于有许多连续插入操作的表均衡IO
压缩键索引       适用于初始列经常重复的索引，压缩叶块条目，可用于二叉树和IOT
降序索引         降序排列，无法将反向键索引降序排列，oracle会忽略对位图索引的降序设置
位图索引         列值基数较低，where中有很多and或or操作符的时候效果较佳，不适用于经常更新的OLTP表，无法创建唯一位图索引
位图连接         连接了事务表和堆表的星型查询操作
基于函数索引
虚拟列索引       可替代函数索引
虚拟索引         通过 create index  nosegment创建的索引  
隐含索引         invisible状态的索引
全局分区索引     可以跨越分区表和普通表中的所有分区，可以为二叉索引，但不能为位图索引
本地分区索引
域索引
二叉树聚簇索引 
散列聚簇索引




语法：
CREATE UNIUQE | BITMAP INDEX <schema>.<index_name>
      ON <schema>.<table_name>
           (<column_name> | <expression> ASC | DESC,
<column_name> | <expression> ASC | DESC,...)
   TABLESPACE <tablespace_name>
     STORAGE <storage_settings>
     LOGGING | NOLOGGING
    COMPUTE STATISTICS
     NOCOMPRESS | COMPRESS<nn>
     NOSORT | REVERSE       ------reverse  反向键索引
     PARTITION | GLOBAL PARTITION<partition_setting>
范例：
create index dept8_empid_idx on dept(employee_id)  
tablespace users   ------指定表空间
pctfree10
initrans2
maxtrans255
storage
(
initial  64K
next   1M
minextents 1
maxextents  unlimited
);

--------评估索引创建后段的大小
set serveroutput on
declare
  l_index_ddl       varchar2(1000);
  l_used_bytes      number;
  l_allocated_bytes number;
begin
  dbms_space.create_index_cost(ddl         => 'create index idx_t on sys.test_index_size(object_id) ',
                               used_bytes  => l_used_bytes,
                               alloc_bytes => l_allocated_bytes);
  dbms_output.put_line('used= ' || l_used_bytes || 'bytes' ||
                       '     allocated= ' || l_allocated_bytes || 'bytes');
end;
/

----或者11g新特性:Note raised when explain plan for create index
SQL> set linesize 200 pagesize 1400;
SQL>  explain plan for create index idx_t on sys.test_index_size(object_id) ;
Explained.
SQL> select * from table(dbms_xplan.display());
Note
-----
   - estimated index size: 2097K bytes
14 rows selected.




----------集群因子计算
select sum(case
             when block#1 = block#2 then
              0
             else
              1
           end) CLUSTERING_FACTOR
  from (select rowid,
               dbms_rowid.rowid_block_number(rowid) block#1,
               lead(dbms_rowid.rowid_block_number(rowid), 1, null) over(order by object_id) block#2,
               lead(rowid, 1, null) over(order by object_id) RID
          from scott.test
         where object_id is not null
         order by object_id) a




---创建复合索引。第一个叫做前导列
create   index   dept_lname_sal_idx on dept(last_name,annsal);

--删除索引
drop   index    dept_lname_sal_idx;

------使已存在索引不可视/可视
alter index index_name invisible/ visible

-------创建不可视的索引
create   index.......invisible

-----当存在不可视的索引的时候可以使用以下提示符强制使用不可视索引
select  /* +use_invisible_indexes */  *  from   table;


重建索引(可以同时使用存储子句和参数,不重建时也可直接使用)
alter index index_name rebuild tablespace tablespace_name nologging parallel 4;
alter index index_name no parallel;

关闭索引并发
set lines 132 pages 1000 
select 'alter index ' || owner || '.' || index_name || ' parallel 1;'
  from dba_indexes
 where degree > 1
   and degree <> 'DEFAULT';


在线重建索引.可以减少加锁时间,从而开放使用DML类型操作
alter  index index_name rebuild tablespace tablespace_name nologging online;

手动拓展索引的空间
alter index index_name allocate extent;

重命名
alter index  ind_old_name  rename  to  ind_new_name；

收回未用到的空间
alter index index_name deallocate unused;

索引碎片整理
alter index index_name coalesce;

标识索引是否使用过
alter index index_name monitoring usage;
查询:
select * from v$object_usage;

取消监控
alter index index_name nomonitoring usage;

索引压缩：
alter index index_name rebuild nologging online tablespace tablespace_name     compress;

标记索引不可用
alter index ind_name  unusable；----重新使用需要rebuild


--------------------------------------加快大的索引创建或重建
/*****************************************************************************************************************************/
SQL> select * from v$version;

BANNER
--------------------------------------------------------------------------------
Oracle Database 11g Enterprise Edition Release 11.2.0.2.0 - 64bit Production
PL/SQL Release 11.2.0.2.0 - Production
CORE    11.2.0.2.0      Production
TNS for Linux: Version 11.2.0.2.0 - Production
NLSRTL Version 11.2.0.2.0 - Production

SQL> select * from global_name;

GLOBAL_NAME
--------------------------------------------------------------------------------
www.askmaclean.com

-- Script Tested above 10g
﻿-- Create a new temporary segment tablespace specifically for creating the index.
-- CREATE TEMPORARY TABLESPACE tempindex tempfile 'filename' SIZE 20G ;
-- ALTER USER username TEMPORARY TABLESPACE tempindex;

REM PARALLEL_EXECUTION_MESSAGE_SIZE can be increased to improve throughput.
REM but need restart instance,and should be same in RAC environment
REM this doesn't make sense,unless high parallel degree

-- alter system set parallel_execution_message_size=65535 scope=spfile;

alter session set workarea_size_policy=MANUAL;
alter session set workarea_size_policy=MANUAL;

alter session set db_file_multiblock_read_count=512;
alter session set db_file_multiblock_read_count=512;

--In conclusion, in order to have the least amount of direct operations and
--have the maximum possible read/write batches these are the parameters to set:

alter session set events '10351 trace name context forever, level 128';

REM set sort_area_size to 700M or 1.6 * table_size
REM 10g bug need to set sort_area_size twice
REM remember large sort area size doesn't mean better performance
REM sometimes you should reduce below setting,and then sort may benefit from disk sort
REM and attention to avoid PGA swap

alter session set sort_area_size=734003200;
alter session set sort_area_size=734003200;

REM set sort area first,and then set SMRC for parallel slave
REM Setting this parameter can activate our previous setting of sort_area_size
REM and we can have large sort multiblock read counts.

alter session set "_sort_multiblock_read_count"=128;
alter session set "_sort_multiblock_read_count"=128;

alter session enable parallel ddl;

create [UNIQUE] index ...     [ONLINE] parallel [Np] nologging;

alter index .. logging;
alter index .. noparallel;

--TRY below underscore parameter while poor performance 

--alter session set "_shrunk_aggs_disable_threshold"=100; 

REM   _newsort_type=2 only works if the patch for bug:4655998 has been applied
REM   The fix for bug:4655998 has been included in the 10.2.0.4 patchset.
REM   got worse in most cases

--alter session set "_newsort_type" = 2; 
OR  
--alter session set "_newsort_enabled"=false;                        then use Sort V1 algorithm,got worse in most cases

rem !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!IMPORTANT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
rem If the performance of a query has degraded and the majority of the
rem time is spent in the function kghfrempty, and the function that called
rem kghfrempty was kxsfwa called from kksumc, then you may be encountering
rem this problem.
rem Workaround:
rem Reducing sort_area_size may help by reducing the amount of memory that
rem each sort allocates, particularly if the IO subsystem is underutilized.
rem The performance of some queries that involved large sorts degraded due
rem to the memory allocation pattern used by sort.
rem !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

REM setting below parameter only if you are loading data into new system
REM you should restore them after loading
--alter session set db_block_checking=false;
--alter system set db_block_checksum=false;




-----快速创建/重组
有的时候，索引实在太大，如几十个G的索引，创建一次或者重组一次需要耗费很长的时间，如果硬件条件许可，我们可以采用一些特殊的方法来提高速度，如采用大的排序区，并行操作等等。
SQL>alter session set sworkarea_size_policy=manaul;
SQL>alter session set sort_area_size=1073741824;
SQL>alter session set sort_area_retained_size=1073741824;
SQL>alter session set db_file_multiblock_read_count=128;
--parallel 2
SQL>alter index index_name rebuild online parallel 2 compute statistics;
然后，特别需要注意的是，在并行创建或者重组完成以后，一定要取消索引的并行度，否则，在OLTP环境中，可能会因为意外的使用并行而出现严重性能问题。
SQL>alter index index_name noparallel;






/****************************************************************************************************************/




索引查看：

select uc.TABLE_NAME,  
          uc.INDEX_NAME,  
          listagg(uc.COLUMN_NAME, ',') within group(order by uc.COLUMN_POSITION) as cols  
     from user_ind_columns uc  
    group by uc.TABLE_NAME, uc.INDEX_NAME  
 /  

select uc.TABLE_NAME,  
       uc.INDEX_NAME,  
       listagg(uc.COLUMN_NAME || ' ' || uc.DESCEND, ',') within group(order by uc.COLUMN_POSITION) as cols  
  from user_ind_columns uc  
 group by uc.TABLE_NAME, uc.INDEX_NAME; 

--索引相关信息
SELECT owner,
       index_name,
       table_name,
       tablespace_name,
       index_type,
       degree,
       status
  FROM dba_indexes where  table_name='GLC_LOCATION_MSG';

--索引列对照信息
select index_name,table_name,column_name,index_owner,table_owner From  dba_ind_columns;

--索引存储信息
SELECT index_name,
       pct_free,
       pct_increase,
       initial_extent,
       next_extent,
       min_extents,
       max_extents
  FROM dba_indexes;

分区索引创建：
--local索引
create index index_name on table_name(column) local

--- global索引
create index ix_custaddr_ global_id on custaddr(id) global;
create index i_id_global on PDBA(id) global
   partition by range(id)
   (partition p1 values less than (200),
   partition p2 values less than (maxvalue) );

分区索引重建：
对于分区索引，不能整体进行重建，只能对单个分区进行重建。语法如下:
Alter index idx_name rebuild partition index_partition_name [online nologging]
说明:
online:表示重建的时候不会锁表。 
nologging:表示建立索引的时候不生成日志，加快速度。
如果要重建分区索引，只能  drop  表原索引，在重新创建:
SQL>create index loc_xxxx_col on xxxx(col) local tablespace user;
这个操作要求较大的临时表空间和排序区。

注意：Oracle 会自动维护分区索引，对于全局索引，如果在对分区表操作时，没有指定 update index，则会导致全局索引失效，需要重建。
global和local信息不在同一个数据字典中;
global索引信息==>dba_indexes
local索引信息==>dba_ind_partitions/user_ind_partitions
*可以通过dba_indexes判断索引类型，如果status等于VALID或者UNUSABLE，索引类型是global;
status等于N/A，索引则是local索引。








------获取索引的ddl语句
SET echo OFF
SET heading OFF  
set long 999999
set linesize 10000 pagesize 5000
spool /tmp/wps_create_index_ddl.sql;
SELECT dbms_metadata.get_ddl('INDEX', a.INDEX_NAME, a.owner) || ';'
  FROM dba_indexes a
 WHERE owner IN
       ('WPS_SCASYSMSG', 'WPS_BPCMSG', 'WPS_COMMONDB', 'WPS_CEIMSG',
        'WPS_BSPACE', 'WPS_BPCOBS', 'WPS_CEIDB', 'WPS_SCAAPPMSG', 'WPS_BPCDB') order by INDEX_NAME;
spool OFF
SET heading ON
SET echo ON

col column_name for a32
col index_name for a30
col table_name for a30
col INDEX_TYPE for a30
col INDEX_OWNER for a30
SELECT a.index_name, a.table_name, b.INDEX_TYPE,a.column_name, a.index_owner
  FROM dba_ind_columns a, dba_indexes b
 WHERE b.owner = a.table_owner
   AND a.index_name = b.index_name
   AND a.table_name = b.table_name
   AND a.table_owner = 'IRM'
   AND a.table_name = 'C_CIRCUIT';


set linesize 1000 pagesize 500
col OWNER for a30
col TABLE_NAME for a30
col COLUMN_NAME for a30
SELECT OWNER, TABLE_NAME, COLUMN_NAME, HISTOGRAM
   FROM dba_tab_columns
  WHERE owner = 'IRM'
    AND table_name = 'C_CIRCUIT';	




-----查询索引列及统计信息
col COLUMN_NAME for a30
select b.TABLE_OWNER,
       b.TABLE_NAME,
       b.INDEX_NAME,
       b.COLUMN_NAME,
       a.num_distinct,
       a.num_nulls,
       a.last_analyzed
  from dba_ind_columns b, dba_tab_col_statistics a
 where a.owner = b.TABLE_OWNER
   and a.table_name = b.TABLE_NAME
   and a.column_name = b.COLUMN_NAME
   and b.TABLE_OWNER = 'IRM'
   and b.TABLE_NAME = 'RP_PER_DATA_1';







Script: To Report Information on Indexes (文档 ID 1019722.6)
========== 
Script #1: 
==========
 
SET ECHO off 
REM NAME:   TFSIFRAG.SQL 
REM USAGE:"@path/tfsifrag schema_name index_name" 
REM ------------------------------------------------------------------------ 
REM REQUIREMENTS: 
REM    SELECT on INDEX_STATS 
REM ------------------------------------------------------------------------ 
REM PURPOSE: 
REM    Reports index fragmentation statistics 
REM ------------------------------------------------------------------------ 
REM EXAMPLE: 
REM                     Index Fragmentation Statistic 
REM                 
REM    index name        S_EMP_USERID_UK 
REM    leaf rows deleted            0 
REM    leaf rows in use            25 
REM    index badness            0.000   
REM  
REM ------------------------------------------------------------------------ 
REM Main text of script follows: 
set verify off  
def ownr  = &&1  
def name  = &&2  
  
ttitle - 
  center 'Index Fragmentation Statistic'   skip 2 
  
set heading off  
  
col name                 newline  
col lf_blk_rows          newline  
col del_lf_rows          newline  
col ibadness newline   
  
validate index &ownr..&name;  
  
select  
  'index name        '||name,  
  'leaf rows deleted '||to_char(del_lf_rows,'999,999,990')  del_lf_rows,  
  'leaf rows in use  '||to_char(lf_rows-del_lf_rows,'999,999,990')  lf_blk_rows,    
  'index badness     '||to_char(del_lf_rows/(lf_rows+0.00001),'999,990.999') ibadness  
from  
  index_stats  
/  
  
undef ownr  
undef name  
set verify on
 
 
==============
Sample Output: 
==============
 
                         Index Fragmentation Statistic 
 
 
index name                   S_EMP_USERID_UK 
leaf rows deleted            0 
leaf rows in use             25 
index badness                0.000 
 
 
 
 
========== 
Script #2: 
==========
 
SET ECHO off 
REM NAME:   TFSISTAT.SQL 
REM USAGE:"@path/tfsistat schema_name index_name" 
REM ------------------------------------------------------------------------ 
REM REQUIREMENTS: 
REM    SELECT on INDEX_STATS 
REM ------------------------------------------------------------------------ 
REM PURPOSE: 
REM    Report index statistics. 
REM ------------------------------------------------------------------------ 
REM EXAMPLE: 
REM                                Index Statistics  
REM 
REM    S_EMP_USERID_UK  
REM    ----------------------------------------------------------  
REM    height                          1 
REM    blocks                          5 
REM    del_lf_rows                     0  
REM    del_lf_rows_len                 0 
REM    distinct_keys                  25 
REM    most_repeated_key               1  
REM    btree_space                 1,876 
REM    used_space                    447  
REM    pct_used                       24 
REM    rows_per_key                    1 
REM    blks_gets_per_access            2  
REM    lf_rows                        25            br_rows               0  
REM    lf_blks                         1            br_blks               0 
REM    lf_rows_len                   447            br_rows_len           0  
REM    lf_blk_len                  1,876            br_blk_len            0   
REM  
REM ------------------------------------------------------------------------ 
REM Main text of script follows: 
set verify off
def ownr        = &&1 
def name        = &&2 
 
ttitle - 
  center  'Index Statistics'  skip 2 
 
set heading off 
 
col name   newline 
col headsep              newline 
col height               newline 
col blocks               newline 
col lf_rows              newline 
col lf_blks          newline 
col lf_rows_len          newline 
col lf_blk_len           newline 
col br_rows              newline 
col br_blks              newline 
col br_rows_len          newline 
col br_blk_len           newline 
col del_lf_rows          newline 
col del_lf_rows_len      newline 
col distinct_keys        newline 
col most_repeated_key    newline 
col btree_space          newline 
col used_space       newline 
col pct_used             newline 
col rows_per_key         newline 
col blks_gets_per_access newline 
 
validate index &ownr..&name; 
 
select 
  name, 
  '----------------------------------------------------------'    headsep, 
  'height               '||to_char(height,     '999,999,990')     height, 
  'blocks               '||to_char(blocks,     '999,999,990')     blocks, 
  'del_lf_rows          '||to_char(del_lf_rows,'999,999,990')     del_lf_rows, 
  'del_lf_rows_len      '||to_char(del_lf_rows_len,'999,999,990') del_lf_rows_len, 
  'distinct_keys        '||to_char(distinct_keys,'999,999,990')   distinct_keys, 
  'most_repeated_key    '||to_char(most_repeated_key,'999,999,990') most_repeated_key, 
  'btree_space          '||to_char(btree_space,'999,999,990')       btree_space, 
  'used_space           '||to_char(used_space,'999,999,990')        used_space, 
  'pct_used                     '||to_char(pct_used,'990')          pct_used, 
  'rows_per_key         '||to_char(rows_per_key,'999,999,990')      rows_per_key, 
  'blks_gets_per_access '||to_char(blks_gets_per_access,'999,999,990') blks_gets_per_access, 
  'lf_rows      '||to_char(lf_rows,    '999,999,990')||'        '||+ 
  'br_rows      '||to_char(br_rows,    '999,999,990')                  br_rows, 
  'lf_blks      '||to_char(lf_blks,    '999,999,990')||'        '||+ 
  'br_blks      '||to_char(br_blks,    '999,999,990')                  br_blks, 
  'lf_rows_len  '||to_char(lf_rows_len,'999,999,990')||'        '||+ 
  'br_rows_len  '||to_char(br_rows_len,'999,999,990')                  br_rows_len, 
  'lf_blk_len   '||to_char(lf_blk_len, '999,999,990')||'        '||+ 
  'br_blk_len   '||to_char(br_blk_len, '999,999,990')                br_blk_len 
from 
  index_stats 
/ 
 
undef ownr 
undef name 
set verify on
 
 
==============
Sample Output: 
==============
 
                                Index Statistics                
S_EMP_USERID_UK 
----------------------------------------------------------  
height                          1  
blocks                          5  
del_lf_rows                     0  
del_lf_rows_len                 0   
distinct_keys                   25  
most_repeated_key               1  
btree_space                   1,876 
used_space                      447  
pct_used                        24  
rows_per_key                    1  
blks_gets_per_access            2  
lf_rows                   25         
br_rows                   0 
lf_blks       1         
br_blks                   0  
lf_rows_len               447         
br_rows_len               0  
lf_blk_len              1,876         
br_blk_len                0 
 
 
 
 
========== 
Script #3: 
==========  
 
SET ECHO off 
REM NAME:   TFSIKEYS.SQL 
REM USAGE:"@path/tfsikeys idx_owner table_name" 
REM ------------------------------------------------------------------------ 
REM REQUIREMENTS: 
REM    SELECT on DBA_IND_COLUMNS and DBA_INDEXES 
REM ------------------------------------------------------------------------ 
REM PURPOSE: 
REM Shows the index keys for a particular table. 
REM ------------------------------------------------------------------------ 
REM EXAMPLE: 
REM             Index Keys Summary 
REM 
REM    Uniqueness                Index Name                    Column Name 
REM    ---------- ----------------------------------------  ------------------ 
REM    UNIQUE                    SCOTT.S_EMP_ID_PK               ID  
REM 
REM    UNIQUE                    SCOTT.S_EMP_USERID_UK           USERID 
REM   
REM ------------------------------------------------------------------------ 
REM Main text of script follows: 
set verify off
def ixowner = &&1 
def tabname = &&2 
 
ttitle - 
   center  'Index Keys Summary'  skip 2 
 
col uniq    format a10 heading 'Uniqueness'  justify c trunc 
col indname format a40 heading 'Index Name'  justify c trunc 
col colname format a25 heading 'Column Name' justify c trunc 
 
break - 
  on indname skip 1 - 
  on uniq 
 
select 
  ind.uniqueness                  uniq, 
  ind.owner||'.'||col.index_name  indname, 
  col.column_name                 colname 
from 
  dba_ind_columns  col, 
  dba_indexes      ind 
where 
  ind.owner = upper('&ixowner') 
    and 
  ind.table_name = upper('&tabname') 
    and 
  col.index_owner = ind.owner  
    and 
  col.index_name = ind.index_name 
order by 
  col.index_name, 
  col.column_position 
/ 
 
undef ixowner 
undef tabname 
set verify on


==============
Sample Output: 
==============

 
         Index Keys Summary 
 
 
Uniqueness                Index Name                    Column Name 
---------- ---------------------------------------- ---------------------- 
UNIQUE                SCOTT.S_EMP_ID_PK                        ID 
                                                                       
UNIQUE                SCOTT.S_EMP_USERID_UK                    USERID


-------------------------------------------确定数据库中没有外键索引的约束
SELECT DISTINCT a.owner owner,
                a.constraint_name cons_name,
                a.table_name tab_name,
                b.column_name cons_column,
                NVL(c.column_name, '***Check index****') ind_column
  FROM dba_constraints a, dba_cons_columns b, dba_ind_columns c
 WHERE constraint_type = 'R'
   AND a.owner = UPPER('&&user_name')
   AND a.owner = b.owner
   AND a.constraint_name = b.constraint_name
   AND b.column_name = c.column_name(+)
   AND b.table_name = c.table_name(+)
   AND b.position = c.column_position(+)
 ORDER BY tab_name, ind_column;
--
SELECT CASE
         WHEN ind.index_name IS NOT NULL THEN
          CASE
            WHEN ind.index_type IN ('BITMAP') THEN
             '** Bitmp idx **'
            ELSE
             'indexed'
          END
         ELSE
          '** Check idx **'
       END checker,
       ind.index_type,
       cons.owner,
       cons.table_name,
       ind.index_name,
       cons.constraint_name,
       cons.cols
  FROM (SELECT c.owner,
               c.table_name,
               c.constraint_name,
               LISTAGG(cc.column_name, ',') WITHIN GROUP(ORDER BY cc.column_name) cols
          FROM dba_constraints c, dba_cons_columns cc
         WHERE c.owner = cc.owner
           AND c.owner = UPPER('&&schema')
           AND c.constraint_name = cc.constraint_name
           AND c.constraint_type = 'R'
         GROUP BY c.owner, c.table_name, c.constraint_name) cons
  LEFT OUTER JOIN (SELECT table_owner,
                          table_name,
                          index_name,
                          index_type,
                          cbr,
                          LISTAGG(column_name, ',') WITHIN GROUP(ORDER BY column_name) cols
                     FROM (SELECT ic.table_owner,
                                  ic.table_name,
                                  ic.index_name,
                                  ic.column_name,
                                  ic.column_position,
                                  i.index_type,
                                  CONNECT_BY_ROOT(ic.column_name) cbr
                             FROM dba_ind_columns ic, dba_indexes i
                            WHERE ic.table_owner = UPPER('&&schema')
                              AND ic.table_owner = i.table_owner
                              AND ic.table_name = i.table_name
                              AND ic.index_name = i.index_name
                           CONNECT BY PRIOR ic.column_position - 1 =
                                       ic.column_position
                                  AND PRIOR ic.index_name = ic.index_name)
                    GROUP BY table_owner,
                             table_name,
                             index_name,
                             index_type,
                             cbr) ind
    ON cons.cols = ind.cols
   AND cons.table_name = ind.table_name
   AND cons.owner = ind.table_owner
 ORDER BY checker, cons.owner, cons.table_name;

