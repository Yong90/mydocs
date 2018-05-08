------以下操作可以使用nologging或append
SQL*Loader
create  table  ... as  select  ....
alter  table ... move
alter table ... add/merge/split/move/modify/  partition
create index  ...
alter index  rebuild
create materialized view 
alter   materialized  ... move
create materialized view  log
alter materialized view  log ... move


------

--------------截取字符串前或后面的字符
select name,substr(name,1,instr(name,'-')-1) 前,substr(name,instr(name,'-')+1,length(name)-instr(name,'-')) 后 from test


-------------------查询sql的执行计划统计信息
SELECT p.hash_value,
       p.SQL_ID,
       p.PLAN_HASH_VALUE,
       p.child_number,
       to_char(p.id, '990') || decode(access_predicates, NULL, NULL, 'A') ||
       decode(filter_predicates, NULL, NULL, 'F') id,
       p.cost cost,
       p.cardinality card,
       lpad(' ', depth) || p.operation || ' ' || p.options || ' ' ||
       p.object_name || decode(p.partition_start, NULL, ' ', ':') ||
       translate(p.partition_start, '(NUMBER', '(NR') ||
       decode(p.partition_stop, NULL, ' ', '-') ||
       translate(p.partition_stop, '(NUMBE', '(NR') operation,
       p.position,
       (SELECT s.LAST_STARTS
          FROM v$sql_plan_statistics s
         WHERE s.address = p.address
           AND s.hash_value = p.hash_value
           AND s.child_number = p.child_number
           AND s.operation_id = p.id) "LAST_STARTS",
       (SELECT s.last_output_rows
          FROM v$sql_plan_statistics s
         WHERE s.address = p.address
           AND s.hash_value = p.hash_value
           AND s.child_number = p.child_number
           AND s.operation_id = p.id) "LAST_ROWS",
       (SELECT round(s.last_elapsed_time / 1000000, 2)
          FROM v$sql_plan_statistics s
         WHERE s.address = p.address
           AND s.hash_value = p.hash_value
           AND s.child_number = p.child_number
           AND s.operation_id = p.id) "ELAPSED",
       (SELECT s.last_cu_buffer_gets + s.last_cr_buffer_gets
          FROM v$sql_plan_statistics s
         WHERE s.address = p.address
           AND s.hash_value = p.hash_value
           AND s.child_number = p.child_number
           AND s.operation_id = p.id) "LOGICAL_READS"
  FROM v$sql_plan p
 WHERE p.hash_value = '1809878095'
 ORDER BY p.child_number, p.id;




--------查询数据库中走全表扫描的sql
WITH fsql AS
 (SELECT /*+ materialize */
   sql_id, to_clob(upper(sql_fulltext)) AS ftext
    FROM v$sql
   WHERE parsing_schema_name = 'SCOTT'),
sqlid AS
 (SELECT /*+ materialize */
   parsing_schema_name, sql_id, sql_text
    FROM v$sql
   WHERE parsing_schema_name = 'SCOTT'
   GROUP BY parsing_schema_name, sql_id, sql_text),
SQL AS
 (SELECT parsing_schema_name,
         sql_id,
         sql_text,
         (SELECT ftext
            FROM fsql
           WHERE sql_id = a.sql_id
             AND rownum <= 1) ftext
    FROM sqlid a),
col AS
 (SELECT /*+ materialize */
   a.sql_id,
   a.object_owner,
   a.object_name,
   nvl(a.filter_predicates, '空') filter_predicates,
   a.column_cnt,
   b.column_cnttotal,
   b.size_mb
    FROM (SELECT sql_id,
                 object_owner,
                 object_name,
                 object_type,
                 filter_predicates,
                 access_predicates,
                 projection,
                 length(projection) -
                 length(REPLACE(projection, '], ', '] ')) + 1 column_cnt
            FROM v$sql_plan
           WHERE object_owner = 'SCOTT'
             AND operation = 'TABLE ACCESS'
             AND options = 'FULL'
             AND object_type = 'TABLE') a,
         (SELECT /*+ USE_HASH(A,B) */
           a.owner, a.table_name, a.column_cnttotal, b.size_mb
            FROM (SELECT owner, table_name, COUNT(*) column_cnttotal
                    FROM DBA_TAB_COLUMNS
                   WHERE owner = 'SCOTT'
                   GROUP BY owner, table_name) a,
                 (SELECT owner, segment_name, SUM(bytes / 1024 / 1024) size_mb
                    FROM dba_segments
                   WHERE owner = 'SCOTT'
                   GROUP BY owner, segment_name) b
           WHERE a.owner = b.owner
             AND a.table_name = b.segment_name) b
   WHERE a.object_owner = b.owner
     AND a.object_name = b.table_name)
SELECT a.parsing_schema_name "用户",
       a.sql_id,
       a.sql_text,
       b.object_name         "表名",
       b.size_mb             "表大小(MB)",
       b.column_cnt          "列访问数",
       b.column_cnttotal     "列总数",
       b.filter_predicates   "过滤条件",
       a.ftext
  FROM SQL a, col b
 WHERE a.sql_id = b.sql_id
 ORDER BY b.size_mb DESC, b.column_cnt ASC;






--------查询sql扫描对象列的个数
SELECT sql_id,
       object_owner,
       object_name,
       object_type,
       filter_predicates,
       access_predicates,
       projection,
       length(projection) - length(REPLACE(projection, '], ', '] ')) + 1 column_cnt
  FROM v$sql_plan
 WHERE object_owner = 'SCOTT'
   AND operation = 'TABLE ACCESS'
   AND options = 'FULL'
   AND object_type = 'TABLE';






嵌套连接外链接的时候无法使用leading改驱动表可以使用/*+ swap_join_inputs(emp) */更改驱动表



---------变化的in无法使用绑定变量问题
with t as
 (select '广东,广西,海南,贵州,云南' str from dual)
SELECT REGEXP_SUBSTR(str, '[^,]+' , 1 , ROWNUM ) province
  FROM t
CONNECT BY ROWNUM <= LENGTH (str) - LENGTH (REPLACE (str, ',' )) + 1 ;



---------------------rowid  切片技术
REM   put it in GUI TOOLS! otherwise caused ORA-00933
REM   control commit yourself, avoid ORA-1555

SELECT 'and rowid between ''' || ora_rowid || ''' and ''' ||
       lead(ora_rowid, 1) over(ORDER BY rn ASC) || '''' || ';'
  FROM (WITH cnt AS (SELECT COUNT(*) FROM order_history) -- 注意替换这里！！
         SELECT rn, ora_rowid
           FROM (SELECT rownum rn, ora_rowid
                   FROM (SELECT ROWID ora_rowid
                           FROM order_history -- 注意替换这里！！
                          ORDER BY ROWID))
          WHERE rn IN (SELECT (rownum - 1) *
                              trunc((SELECT * FROM cnt) / &row_range) + 1
                         FROM dba_tables
                        WHERE rownum < &row_range --输入分区的数目
                       UNION
                       SELECT *
                         FROM cnt));



--------------------------------rowid  切片技术
select 'and rowid between ''' || ora_rowid || ''' and ''' ||
       lead(ora_rowid, 1) over(order by rn asc) || '''' || ';'
  from (

       with cnt as (select count(*)
                      from order_history
                     where order_id < 1999999) -- replace here
         select rn, ora_rowid
           from (select rownum rn, ora_rowid
                   from (select rowid ora_rowid
                           from order_history
                          where order_id < 1999999 -- replace here
                          order by rowid))
          where rn in (select (rownum - 1) *
                              trunc((select * from cnt) / &row_range) + 1
                         from dba_tables
                        where rownum < &row_range
                       union
                       select * from cnt))







