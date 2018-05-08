----------查询表索引情况
set linesize 1000 pagesize 500
col table_name for a20
col column_name for a30
col TABLE_OWNER for a20
col index_name for a40
col CLUSTERING_FACTOR for 99999999999
col TYPE_desc for a15
col INDEX_OWNER for a15
col DEGREE for a10
col b_leaf_num_dist for a30
col LAST_ANALYZED for a20
col LAST_DDL_TIME for a20
SELECT DISTINCT a.index_owner,
                a.table_name,
                a.TABLE_OWNER,
                a.index_name,
                b.STATUS,
                b.INDEX_TYPE||'/'|| a.DESCEND TYPE_desc,
                a.column_name,
                a.COLUMN_POSITION,
                b.BLEVEL,b.LEAF_BLOCKS, b.NUM_ROWS,b.DISTINCT_KEYS ,
                b.CLUSTERING_FACTOR,
                to_char(b.LAST_ANALYZED, 'yyyy-mm-dd hh24:mi') LAST_ANALYZED
  FROM dba_ind_columns a, dba_indexes b
 WHERE b.owner = a.table_owner
   AND a.index_name = b.index_name
   AND a.table_name = b.table_name
      AND a.table_owner = 'HICANO_POS'
 AND a.table_name in  ('E_CPHPDA')
 --and a.index_name in ('IDX_ORDER_CUR_STATE_GID')
  /* AND a.column_name IN
( 'ENTITYTYPE_ID')*/
--and  b.STATUS <>'VALID'
 ORDER BY a.TABLE_OWNER, a.TABLE_NAME,a.index_name, a.COLUMN_POSITION,status;

select a.INDEX_OWNER,
       a.INDEX_NAME,
       a.PARTITION_NAME,
       a.SUBPARTITION_COUNT,
       to_char(a.LAST_ANALYZED, 'yyyy-mm-dd hh24:mi:ss') LAST_ANALYZED,
       a.COMPRESSION,
       a.BLEVEL,
       a.LEAF_BLOCKS,
       a.NUM_ROWS,
       a.DISTINCT_KEYS
  from dba_ind_partitions a
  join dba_indexes b
    on a.INDEX_OWNER = b.OWNER
       and a.INDEX_NAME = b.INDEX_NAME
 where b.table_name in ('TBL_DTL_HISMO20160517', 'TBL_DTL_HISMT20160517')
 order by INDEX_NAME;


set linesize 1000 pagesize 500
col table_name for a25
col column_name for a20
col TABLE_OWNER for a20
col index_name for a40
col CLUSTERING_FACTOR for 99999999
col INDEX_TYPE for a25
col INDEX_OWNER for a15
col DEGREE for a10
col LAST_ANALYZED for a20
col LAST_DDL_TIME for a20
SELECT DISTINCT a.index_owner,
                a.table_name,
                a.TABLE_OWNER,
                a.index_name,
                b.INDEX_TYPE,
                a.column_name,
                a.COLUMN_POSITION,
                GLOBAL_STATS，
                to_char(b.LAST_ANALYZED, 'yyyy-mm-dd hh24:mi') LAST_ANALYZED
  FROM dba_ind_columns a, dba_indexes b
 WHERE b.owner = a.table_owner
   AND a.index_name = b.index_name
   AND a.table_name = b.table_name
      /* AND a.table_owner = 'IRM'*/
   AND a.table_name IN
       ('PON_ORDER_CUR_STATE')
/*    and a.index_name in ('CPQA_OPERATETIME','CP_CREATETIME_IDX')*/
/*   AND a.column_name IN
('PORTCATEGORY', 'ENTITYTYPE_ID', 'ID', 'DEVICE_ID')*/
 ORDER BY a.TABLE_OWNER, a.TABLE_NAME,a.index_name, a.COLUMN_POSITION;


--------同一获得执行计划相关表的索引情况
set linesize 1000 pagesize 500
col table_name for a25
col column_name for a20
col TABLE_OWNER for a20
col index_name for a40
col CLUSTERING_FACTOR for 99999999999
col INDEX_TYPE for a25
col INDEX_OWNER for a15
col DEGREE for a10
col LAST_ANALYZED for a20
col LAST_DDL_TIME for a20
with plan_obj as
 (select a.OBJECT_OWNER as owner,
         decode(a.OPERATION,
                'INDEX',
                b.table_name,
                'TABLE ACCESS',
                a.OBJECT_NAME) as table_name
    from gv$sql_plan a
    left join dba_indexes b
      on a.OBJECT_OWNER = b.owner
     and a.OBJECT_NAME = b.index_name
   where a.OPERATION in ('TABLE ACCESS', 'INDEX')
     and a.SQL_ID = 'gzdb0av7rnzcu'
  /*and a.CHILD_NUMBER = 41*/
  )
SELECT DISTINCT a.index_owner,
                a.table_name,
                a.TABLE_OWNER,
                a.index_name,
                b.INDEX_TYPE,
                a.column_name,
                a.COLUMN_POSITION,
                b.GLOBAL_STATS,
                to_char(b.LAST_ANALYZED, 'yyyy-mm-dd hh24:mi') LAST_ANALYZED
  FROM dba_ind_columns a, dba_indexes b, plan_obj c
 WHERE c.owner = b.TABLE_OWNER
   and c.table_name = b.TABLE_NAME
   and b.TABLE_OWNER = a.table_owner
   AND a.index_name = b.index_name
   AND a.table_name = b.table_name
 ORDER BY a.TABLE_OWNER, a.TABLE_NAME, a.index_name, a.COLUMN_POSITION;

--------------索引DDL时间
set linesize 1000 pagesize 500
col index_name for a40
col table_name for a30
col INDEX_TYPE for a25
col OWNER for a15
col LAST_DDL_TIME for a20
SELECT DISTINCT b.owner,
                b.table_name,
                b.index_name,
                b.INDEX_TYPE,
                to_char(c.LAST_DDL_TIME, 'yyyy-mm-dd HH24:mi:ss') LAST_DDL_TIME
  FROM dba_indexes b, dba_objects c
 WHERE c.owner = b.owner
   AND b.index_name = c.OBJECT_NAME
   AND c.OBJECT_TYPE LIKE 'INDEX%'
      /* AND b.table_owner = 'IRM'*/
   AND b.table_name IN (upper('tbl_cp_create'))
/*      and b.index_name in ('IDX_CIRCUIT_ENTITYTYPE_IDX','IDX_CCIRCUIT_NAME')*/
 ORDER BY b.owner, b.table_name, b.index_name;
