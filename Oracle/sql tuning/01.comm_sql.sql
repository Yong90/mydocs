---------查询执行计划
alter session set statistics_level=all;
set timing on 
set linesize 1000 pagesize 5000
------跑sql
select * from table(dbms_xplan.display_cursor(null,null,'allstats +alias +outline'));

----看AWR执行计划
alter session set statistics_level=all;
set timing on 
set linesize 1000 pagesize 5000

select * from table(dbms_xplan.display_awr('7mr5y1889u2dj'));
select * from table(dbms_xplan.display_awr('5zrr7zgw2zz8g',format=>'ALL'));
select *
  from table(dbms_xplan.display_awr(SQL_ID          => '7b2n1c0j8a6d5',
                                    PLAN_HASH_VALUE => '1620732970',
                                    --DB_ID           => 379027385,
                                    FORMAT          => 'ADVANCED ALLSTATS LAST PEEKED_BINDS'));
---- 看内存执行计划
select * from table(dbms_xplan.display_cursor('ghg69pkaacxtg',null,'ADVANCED ALLSTATS LAST PEEKED_BINDS'));
select * from table(dbms_xplan.display_cursor('bdt380rw7dgx4',null,'ADVANCED'));

select output from table(dbms_workload_repository.awr_sql_report_text(db_id,instance_number,begin_snap,end_snap,sql_id,8));
@$ORACLE_HOME/rdbms/admin/awrsqrpt.sql
select a.SQL_ID,a.PLAN_HASH_VALUE,a.CHILD_NUMBER,to_char(a.LAST_ACTIVE_TIME,'yyyy-mm-dd hh24:mi:ss') LAST_ACTIVE_TIME from v$sql a where a.SQL_ID='0wmxr08d92xfn';


select b.username
  from DBA_HIST_ACTIVE_SESS_HISTORY a
  left join dba_users b
    on a.user_id = b.user_id
 where a.SQL_ID = 'b8wag6h2qg4nj'
   and rownum = 1;
 
 
 ----------SQL文本查看
set long 1999999999
set linesize 32767 pagesize 50000
col SQL_FULLTEXT for  a170
col SQL_TEXT for a150
select SQL_FULLTEXT from v$sqlarea where sql_ID ='bdt380rw7dgx4';

select  SQL_FULLTEXT from v$sql where sql_ID ='1rth42r1y8anz' and  rownum = 1;

select EXECUTIONS ,SQL_FULLTEXT from v$sqlarea where sql_id in  ('23xspwdrzsa3d','8ajaztfyjy71z','35y8kqgxx4z28') ;


select sql_id from v$sqlarea   where  SQL_FULLTEXT like '%DELETE FROM C_DEVICE t WHERE t.ID in (:1 )%'




set long 999999999
set linesize 10000 pagesize 5000
col SQL_FULLTEXT for  a200
col SQL_TEXT for a150
select SQL_ID, SQL_TEXT
  from DBA_HIST_SQLTEXT
 where sql_ID  in  ('864j21vszrz66') ;
 
 
-----------执行计划是否有突变
select distinct SQL_ID,
                PLAN_HASH_VALUE,
                to_char(TIMESTAMP, 'yyyymmdd hh24:mi:ss') TIMESTAMP
  from dba_hist_sql_plan
 where SQL_ID = '05nb58nnw17j5'
 order by TIMESTAMP;
 ------------查询某条sql的所有执行计划，确定是否突变
select distinct s.snap_id,
                to_char(b.end_interval_time, 'yyyy-mm-dd hh24:mi:ss') end_interval_time,
                s.instance_number,
                s.plan_hash_value
  from DBA_HIST_SQLSTAT s, dba_hist_snapshot b
 where s.snap_id = b.snap_id
       and s.sql_id = '8g79gg9dnxp18'
 order by s.snap_id, s.plan_hash_value;
 
col cmd_to_show_plan for a70
select distinct 
                s.snap_id,
                to_char(b.end_interval_time, 'yyyy-mm-dd hh24:mi:ss') end_interval_time,
                s.instance_number,
                s.sql_id,
                s.plan_hash_value,
                'select *from table(dbms_xplan.display_awr(SQL_ID=>' || '''' ||
                s.sql_id || '''' || ',
                PLAN_HASH_VALUE=>' || '''' ||
                s.plan_hash_value || '''' || ',
                DB_ID =>' || '''' || s.dbid || '''' ||',
                FORMAT=>' || '''' || 'ADVANCED ALLSTATS LAST PEEKED_BINDS' || '''' || '));' cmd_to_show_plan
  from DBA_HIST_SQLSTAT s, dba_hist_snapshot b
 where s.snap_id = b.snap_id
       and s.sql_id = 'frshvqnjj86y5'
       and trunc(end_interval_time)=to_date('2016-03-01','yyyy-mm-dd')
 order by s.snap_id, s.plan_hash_value;

---获取SQL的一个绑定变量
select   sql_id, HASH_VALUE ,plan_hash_value from v$sqlarea where sql_id='frshvqnjj86y5'; 



set linesize 1000 pagesize 5000
col DATATYPE_STRING for a15
col BIND_VALUE for a30
col VALUE_ANYDATA for a30
col  name for a15
SELECT sql_id,
       HASH_VALUE,
       name,
       datatype_string,
       --  DUMP(t.value_anydata) VALUE_ANYDATA,
       case datatype
         when 180 then --TIMESTAMP
          to_char(ANYDATA.accesstimestamp(t.value_anydata),
                  'YYYY/MM/DD HH24:MI:SS')
         else
          t.value_string
       end as bind_value,
       to_char(last_captured, 'yyyy-mm-dd hh24:mi:ss') last_captured
  FROM v$sql_bind_capture t
 WHERE sql_id = 'b8wag6h2qg4nj'
       --and HASH_VALUE = '588520389'
 order by HASH_VALUE,name;


set linesize 1000 pagesize 5000
col VALUE_STRING for a30
col VALUE_ANYDATA for a30
col  name for a20
SELECT snap_id,
       NAME,
       position,
       value_string,
       last_captured,
       WAS_CAPTURED
  FROM dba_hist_sqlbind
 WHERE sql_id = 'd6129ta92sr71'
 order by 1,5,3;

---获取SQL的一个绑定变量
set linesize 1000 pagesize 5000
col a1 for a20
col a2 for a20
col a3 for a20
col a4 for a20
col a5 for a20
col a6 for a20
col a7 for a20
col a8 for a20
SELECT SNAP_ID,
       dbms_sqltune.extract_bind(bind_data, 1).value_string AS a1,
       dbms_sqltune.extract_bind(bind_data, 2).value_string AS a2,
       dbms_sqltune.extract_bind(bind_data, 3).value_string AS a3,
       dbms_sqltune.extract_bind(bind_data, 4).value_string AS a4,
       dbms_sqltune.extract_bind(bind_data, 5).value_string AS a5,
       dbms_sqltune.extract_bind(bind_data, 6).value_string AS a6,
       dbms_sqltune.extract_bind(bind_data, 7).value_string AS a7,
       dbms_sqltune.extract_bind(bind_data, 8).value_string AS a8
  FROM sys.wrh$_sqlstat
 WHERE sql_id = '01mnbqvsjkbj2'
--and PLAN_HASH_VALUE = '1002455315'
 order by 1;




-----查执行计划及其他详细信息
-----------------------10046
alter session set events '10046 trace name context forever, level 12'; 
alter session set events '10046 trace name context off'; 
----------对其他的会话进行跟踪
----用SQL_TRACE跟踪
select sid,serial# from v$session where SID=267;
-- 启动SQL_TRACE
execute dbms_system.set_sql_trace_in_session(267,996,true); 
-- 关闭SQL_TRACE
execute dbms_system.set_sql_trace_in_session(267,996,false); 
----使用10046 事件跟踪
-- 启动trace
exec dbms_monitor.session_trace_enable(267,996,waits=>true,binds=>true);  
-- 关闭trace
SQL> exec dbms_monitor.session_trace_disable(267,996); 
------------------------10053
alter session set max_dump_file_size=unlimited;
alter session set tracefile_identifier='lyong__10053_no_hint';
alter session set statistics_level=all;
alter session set events '10053 trace name context forever, level 1';
-----------
alter session set events '10053 trace name context off';   


------------------------10046
alter session set max_dump_file_size=unlimited;
alter session set tracefile_identifier='MYDUMP_10046';
alter session set statistics_level=all;
/*
level 1：跟踪sql语句，包括解析、执行、提取、提交和回滚等。
level 4：包括变量的详细信息
level 8：包括等待事件
level 12：包括绑定变量与等待事件
其中，level 1相当于打开了sql_trace
*/
 alter session set events '10046 trace name context forever ,level 12' ;   
-----------
alter session set events '10046 trace name context off'; 
10053事件内容解析 
1.  Predicate Move-Around (PM)(对SQL语句的谓词进行分析、重写，把它改为最符合逻辑的SQL语句)
2.  解释trace文件用到的一些缩写的指标定义
3.  Peeked values of the binds in SQL statement(绑定变量的描述)
4.  Bug Fix Control Environment(一些修复的bug信息)
5.  PARAMETERS WITH DEFAULT VALUES(性能相关的初始化参数)
6.  BASE STATISTICAL INFORMATION(SQL引用对象的基本信息)
7.  CBO计算每个对象单独访问的代价
8.  CBO计算列出两个表关联方式，并计算出每一种关联方式的代价，最终选择最小的cost

------将shared  pool对象移除
sys.dbms_shared_pool.purge
          Value        Kind of Object to keep
--        -----      ----------------------
--        P          package/procedure/function
--        Q          sequence
--        R          trigger
--        T          type
--        JS         java source
--        JC         java class
--        JR         java resource
--        JD         java shared data
--        C          cursor
set linesize 300 pagesize 500
col sql_addr for a30
SELECT sql_id, address || ',' || hash_value sql_addr, CHILD_NUMBER
  FROM v$sql_plan
 WHERE sql_id = '569xn5p8xggyf'
 ORDER BY CHILD_NUMBER;
SQL_ID                                  SQL_ADDR                       CHILD_NUMBER
--------------------------------------- ------------------------------ ------------
569xn5p8xggyf                           0000002782784138,1373093838               0


exec sys.dbms_shared_pool.purge('0000002782784138,1373093838','C');


set linesize 300 pagesize 500
col sql_addr for a30
SELECT sql_id, address || ',' || hash_value sql_addr
  FROM v$sqlarea
 WHERE sql_id = '8yykyzp9v1h1v';

select * from table(dbms_xplan.display_cursor('8yykyzp9v1h1v',null,'ADVANCED ALLSTATS LAST PEEKED_BINDS'));

在10.2.0.4中，虽然PURGE过程已经存在，但是要使这个过程可以真正的生效，还必须设置一个EVENT：
SQL> alter system set event = '5614566 trace name context forever' scope = spfile;






  






frshvqnjj86y5
dygq9zpuds34f

--------------将sql执行计划purge出共享池
alter session set events '5614566 trace name context forever';
set long 999999
select address,hash_value,PLAN_HASH_VALUE,executions,parse_calls,SQL_FULLTEXT from v$sql where sql_ID ='brwysws21kmk6';
ADDRESS          HASH_VALUE EXECUTIONS PARSE_CALLS
---------------- ---------- ---------- -----------
00000000AC41F408 3565516480          1           1
exec dbms_shared_pool.purge('00000000AC3C00C0,773970511','C');
select address,hash_value,executions,parse_calls,PLAN_HASH_VALUE,SQL_FULLTEXT from v$sql where sql_ID ='9a409znr23qkg';

set long 999999
select address,hash_value,PLAN_HASH_VALUE,executions,parse_calls,SQL_FULLTEXT  from v$sqlarea where sql_ID ='brwysws21kmk6';


