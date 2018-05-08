------查询表大小情况
set linesize 500 pagesize 500
col segment_name for a35
col owner for a20
col partition_name for a35
SELECT a.owner,
       a.segment_name,TABLESPACE_NAME,
      /* a.partition_name,
       SEGMENT_TYPE,*/
       SUM(a.BYTES) / 1024 / 1024/1024  size_gb
  FROM dba_segments a
 WHERE a.segment_name
      --LIKE 'TBL_DTL_HISM%'
       IN ('PON_RADIUS_CUSTOMER','GH_DEPT')
--and owner='ZC_TNMSPONBAK'
 GROUP BY a.owner, a.segment_name,TABLESPACE_NAME/*, a.partition_name, SEGMENT_TYPE*/
 order by segment_name;

-------基于v$sql_plan查询相关SQL访问对象的基础信息
set linesize 1000 pagesize 5000
col OPERATION for a20
col OWNER for a20
col DEGREE for 99
with plan_obj as
 (select a.OBJECT_OWNER as owner,
         a.OBJECT_NAME as acess_obj,
         a.OPERATION as OPERATION,
         a.OBJECT_NAME,
         decode(a.OPERATION,
                'INDEX',
                b.table_name,
                'TABLE ACCESS',
                a.OBJECT_NAME) as table_name
    from v$sql_plan a
    left join dba_indexes b
      on a.OBJECT_OWNER = b.owner
     and a.OBJECT_NAME = b.index_name
   where a.OPERATION in ('TABLE ACCESS', 'INDEX')
     and a.SQL_ID = 'gzdb0av7rnzcu'
  /*and a.CHILD_NUMBER = 41*/
  ),
obj_seg as
 (select e.owner,
         e.segment_name as table_name,
         round(sum(e.BYTES) / 1024 / 1024 / 1024, 2) size_gb
    from dba_segments e, plan_obj f
   where e.owner = f.owner
     and e.segment_name = f.table_name
   group by e.owner, e.segment_name)
select *
  from (select c.owner,
               c.acess_obj,
               c.OPERATION,
               c.table_name,
               d.PARTITIONED,
               trunc(d.degree) DEGREE,
               to_char(d.LAST_ANALYZED, 'yyyy-mm-dd hh24:mi:ss') LAST_ANALYZED,
               d.NUM_ROWS,
               seg.size_gb,
               row_number() over(PARTITION BY c.table_name order by seg.size_gb) as row_num
          from plan_obj c, dba_tables d, obj_seg seg
         where c.owner = d.OWNER
           and c.table_name = d.TABLE_NAME
           and c.owner = seg.OWNER
           and c.table_name = seg.TABLE_NAME)
 where row_num = 1;
   
   



set linesize 500 pagesize 500
col segment_name for a35
col owner for a20
col partition_name for a35
SELECT a.owner, a.segment_name, SUM(a.BYTES) / 1024 / 1024 / 1024 size_gb
  FROM dba_segments a
 WHERE a.segment_name='TC_JOBINS_ITEM_TEMP_HISTORY'
 GROUP BY a.owner, a.segment_name;




select count(*) total
  from NETFORCE.tbl_treat_createorder c
  left join  NETFORCE.tbl_treat_query q q
    on q.draftid = c.draftid
 where 1 = 1
   and c.area like '%永嘉%'
   and c.createtime >= '2015-05-01 00:00:00'
   and c.createtime <= '2016-01-13 23:59:59'
   and c.draftid in (select distinct draftid
                       from NETFORCE.tbl_treat_status s
                      where s.stepname = '受理工单')
   and c.area like '%温州%';




TBL_DTL_HISMO*
TBL_DTL_HISMT*






with segments as
 (select distinct OWNER, TABLE_NAME segment_name
    from dba_tables
   where table_name = 'T_OPER_2015_05_14'
         and OWNER = 'AUDITOR'
  union all
  select distinct OWNER, INDEX_NAME segment_name
    from dba_indexes
   where table_name = 'T_OPER_2015_05_14'
         and OWNER = 'AUDITOR')
SELECT a.owner,
       a.segment_name,
       SEGMENT_TYPE,
       SUM(a.BYTES) / 1024 / 1024 size_Mb
  FROM dba_segments a
  join segments s
    on a.OWNER = s.OWNER
       and a.segment_name = s.segment_name
 GROUP BY a.owner, a.segment_name, SEGMENT_TYPE;

select b.owner, b.segment_name, SUM(b.BYTES) / 1024 / 1024 / 1024 size_gb
  from dba_tables a, dba_segments b
 where a.OWNER = 'SMSEXP'
       and a.LAST_ANALYZED is not null
       and b.OWNER = 'SMSEXP'
       and a.table_name = b.segment_name
 GROUP BY b.owner, b.segment_name;

set linesize 500 pagesize 500
col segment_name for a35
SELECT a.owner,
       a.segment_name,
       a.partition_name,
       a.segment_type,
       SUM(a.BYTES) / 1024 / 1024 / 1024 size_gb
  FROM dba_segments a
 WHERE a.segment_name like 'M_SMS_QUEUE' 
 --and a.owner='XJMON'   
 GROUP BY a.owner, a.segment_name, a.partition_name,a.segment_type
 ORDER BY a.owner, a.segment_name, a.partition_name;



------查询表信息
set linesize 1000 pagesize 5000
col TABLE_NAME for a30
col TABLESPACE_NAME for a30
col LAST_ANALYZED for a30
col LAST_DDL_TIME for a30
SELECT distinct a.OWNER,
       a.TABLE_NAME,
       b.OBJECT_TYPE ,
       SUBOBJECT_NAME,
       a.STATUS,
       a.TEMPORARY TEMPORARY,
       a.NUM_ROWS,
       TRIM(a.DEGREE) DEGREE,
       to_char(a.LAST_ANALYZED, 'yyyy-mm-dd HH24:mi:ss') LAST_ANALYZED,
       to_char(b.LAST_DDL_TIME,'yyyy-mm-dd HH24:mi:ss') LAST_DDL_TIME
  FROM dba_tables a,dba_objects b
 WHERE a.owner=b.owner
 and a.TABLE_NAME=b.OBJECT_NAME
 and b.OBJECT_TYPE like  'TABLE%'
 and a.OWNER='HK_139SITE_TSSITE'
 and a.TABLE_NAME IN
        (upper('PUSH_INFO'));


set serveroutput on
  declare
    a_low  dba_tab_columns.low_value%type;
    a_high dba_tab_columns.high_value%type;
    aa     NMOSDB.TFA_ALARM_CLR.EVENT_TIME%type;
  begin
    SELECT LOW_VALUE, HIGH_VALUE
      into a_low, a_high
      FROM dba_tab_columns
     WHERE owner = 'NMOSDB' ----用户名
           AND table_name in ('TFA_ALARM_CLR') ---表名
           and COLUMN_NAME in (upper('EVENT_TIME'));
  
    dbms_stats.convert_raw_value(a_low, aa);
    dbms_output.put_line(aa);
    dbms_stats.convert_raw_value(a_high, aa);
    dbms_output.put_line(aa);
  end;
   /


set linesize 1000 pagesize 5000
col TABLE_NAME for a30
col TABLESPACE_NAME for a30
col LAST_ANALYZED for a30
col LAST_DDL_TIME for a30
SELECT distinct a.TABLE_OWNER,
                a.TABLE_NAME,
                a.PARTITION_NAME,
                a.SUBPARTITION_COUNT,
                --a.HIGH_VALUE,
                a.NUM_ROWS,
                to_char(a.LAST_ANALYZED, 'yyyy-mm-dd HH24:mi:ss') LAST_ANALYZED,
                to_char(b.LAST_DDL_TIME, 'yyyy-mm-dd HH24:mi:ss') LAST_DDL_TIME
  FROM DBA_TAB_PARTITIONS a, dba_objects b
 WHERE a.TABLE_OWNER = b.owner
       and a.TABLE_NAME = b.OBJECT_NAME
       and a.PARTITION_NAME = b.SUBOBJECT_NAME
       and b.OBJECT_TYPE like 'TABLE PARTITION'
       and a.TABLE_NAME IN ('PON_ORDER_CUR_STATE')
       and  a.TABLE_OWNER ='ZC_TNMSPON'
       order by a.PARTITION_NAME;



------分区信息
set linesize 1000 pagesize 500
col COLUMN_NAME for a30
select t.table_name, kc.column_name,'part' type, t.partitioning_type
  from dba_part_key_columns kc, dba_part_tables t
 where kc.owner = t.owner
   and kc.name = t.table_name
   and t.table_name = 'PON_ORDER_CUR_STATE'
   and t.owner = 'ZC_TNMSPON'
union all
select u.table_name, skc.column_name,'subpart' type, u.subpartitioning_type
  from dba_subpart_key_columns skc, dba_part_tables u
 where skc.owner = u.owner
   and skc.name = u.table_name
   and u.subpartitioning_type != 'NONE'
   and u.table_name = 'PON_ORDER_CUR_STATE'
   and u.owner = 'ZC_TNMSPON';


      AND a.table_owner = 'ZC_TNMSPON'
 AND a.table_name in 
     ('PON_ORDER_CUR_STATE')
 --  and a.index_name in ('CP_DCFLOWNO_IDX')





-----查询表列情况
set linesize 1000 pagesize 500
col OWNER for a20
col TABLE_NAME for a35
col COLUMN_NAME for a30
col DENSITY for a15
col DATA_TYPE for a15
col HISTOGRAM for a15
SELECT OWNER,
       TABLE_NAME,
       COLUMN_NAME,
       DATA_TYPE,
       HISTOGRAM,
       NUM_DISTINCT,
       --LOW_VALUE,HIGH_VALUE,
       to_char(round(DENSITY, 8)) DENSITY,
       NUM_NULLS,
       to_char(LAST_ANALYZED, 'yyyy-mm-dd HH24:mi:ss') LAST_ANALYZED
  FROM dba_tab_columns
 WHERE owner = 'ZC_CCMS'
       AND table_name in  ('PON_RADIUS_CUSTOMER')
      --and COLUMN_NAME in (upper('INSPECTJOBS_ID'),'ID','IS_DELETE','SITE_TYPE','PROFESSION_ID')
      order by 2,3;


 set serveroutput on
 declare
   a_low  dba_tab_columns.low_value%type;
   a_high dba_tab_columns.high_value%type;
   aa     NMOSDB.TFA_ALARM_CLR.EVENT_TIME%type;
 begin
   SELECT LOW_VALUE, HIGH_VALUE
     into a_low, a_high
     FROM dba_tab_columns
    WHERE owner = 'NMOSDB' ----用户名
          AND table_name in ('TFA_ALARM_CLR') ---表名
          and COLUMN_NAME in (upper('EVENT_TIME'));
 
   dbms_stats.convert_raw_value(a_low, aa);
   dbms_output.put_line(aa);
   dbms_stats.convert_raw_value(a_high, aa);
   dbms_output.put_line(aa);
 end;
  /







 set serveroutput on
 declare
   a_low  dba_tab_columns.low_value%type;
   a_high dba_tab_columns.high_value%type;
   aa     NMOSDB.TFA_ALARM_CLR.EVENT_TIME%type;
 begin
   SELECT LOW_VALUE, HIGH_VALUE
     into a_low, a_high
     FROM dba_tab_columns
    WHERE owner = 'NMOSDB' ----用户名
          AND table_name in ('TFA_ALARM_CLR') ---表名
          and COLUMN_NAME in (upper('EVENT_TIME'));
 
   dbms_stats.convert_raw_value('78730915010101', aa); 
   dbms_output.put_line(aa);
   dbms_stats.convert_raw_value('78730C12123C3C', aa);
   dbms_output.put_line(aa);
 end;
  /


---------表列的选择率
set linesize 1000 pagesize 500
col TABLE_NAME for a20
col COLUMN_NAME for a25
col DATA_TYPE  for a15
col selectivity for a20
SELECT tab.OWNER,
       tab.TABLE_NAME,
       tab.COLUMN_NAME,
       tab.DATA_TYPE,
       tab.NUM_ROWS,
       tab.NUM_NULLS,
       tab.NUM_DISTINCT,
       tab.pct_not_null,
       to_char(trunc(1 / tab.NUM_DISTINCT * tab.pct_not_null, 8)) selectivity,
       trunc(tab.NUM_ROWS / tab.NUM_DISTINCT * tab.pct_not_null, 2) cardinality
  FROM (SELECT a.OWNER,
               a.TABLE_NAME,
               b.COLUMN_NAME,
               b.DATA_TYPE,
               a.NUM_ROWS,
               b.NUM_NULLS,
               b.NUM_DISTINCT,
               (a.NUM_ROWS - b.NUM_NULLS) / a.NUM_ROWS pct_not_null
          FROM dba_tables a, dba_tab_columns b
         WHERE a.OWNER = b.OWNER
               AND a.TABLE_NAME = b.TABLE_NAME
               AND a.TABLE_NAME in
              ('PUSH_INFO')
              --AND a.OWNER = 'FMDB'
              --and b.COLUMN_NAME in ( 'ENTITYTYPE_ID','NAME')
               AND a.NUM_ROWS > 0
               AND a.NUM_ROWS <> b.NUM_NULLS
               ) tab;

Non_empty_ratio=（NUM_ROWS-NUM_NULLS）/NUM_ROWS
selectivity=1/(NUM_DISTINCT*Non_empty_ratio)
cardinality=NUM_ROWS*selectivity
Index access i/o cost = dba_indexes.blevel + ceil(dba_indexes.leaf_blockes*index_selectivity)
Table access i/o cost =ceil(dba_indexes.clustering_factor* Index_selectivity_with_filters)
