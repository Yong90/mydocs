/*****************************************/
临时表空间使用情况
/****************************************/
------查看temp表空间使用情况
set linesize 1000 pagesize 5000
col EVENT for a30
SELECT *
  FROM (SELECT a.INST_ID,
               s.sid ,
               a.sql_id,
               a.TABLESPACE,
               a.USERNAME,
               s.event,
               s.status,
               a.CONTENTS,
               a.SEGTYPE,
               round(a.BLOCKS * 8 / 1024,2) size_mb
          FROM gv$sort_usage a
          left join gv$session s 
            on a.INST_ID = s.INST_ID
               and a.SESSION_ADDR = s.SADDR
          --where sid=4370
         ORDER BY a.INST_ID,a.BLOCKS DESC)
 WHERE rownum < 21;

------temp表空间使用情况
--11G下：
select tablespace_name,
       round(tablespace_size / 1024 / 1024 / 1024, 2) as total,
       round(free_space / 1024 / 1024 / 1024, 2) as free,
       round((tablespace_size - free_space) / 1024 / 1024 / 1024, 2) used_size,
       round(nvl(free_space, 0) * 100 / tablespace_size, 3) pct_free
  from dba_temp_free_space;

       
       
---10G下：
SELECT temp_used.tablespace_name,
       total - used as "Free",
       total as "Total",
       round(nvl(total - used, 0) * 100 / total, 3) "Free percent"
  FROM (SELECT tablespace_name, SUM(bytes_used) / 1024 / 1024 used
          FROM GV_$TEMP_SPACE_HEADER
         GROUP BY tablespace_name) temp_used,
       (SELECT tablespace_name, SUM(bytes) / 1024 / 1024 total
          FROM dba_temp_files
         GROUP BY tablespace_name) temp_total
 WHERE temp_used.tablespace_name = temp_total.tablespace_name;

set linesize 1000 pagesize 5000
col SAMPLE_TIME for a25
col SQL_ID for a15
col  PROGRAM for a30
col MACHINE for a30
select *
  from (select to_char(SAMPLE_TIME, 'yyyy-mm-dd hh24:mi:ss') SAMPLE_TIME,
               USER_ID,
               SQL_ID,
               PROGRAM,
               MACHINE,
               sum(TEMP_SPACE_ALLOCATED) / 1024 / 1024 / 1024 size_gb
          from V$ACTIVE_SESSION_HISTORY
         where SAMPLE_TIME > sysdate - 2 / 24
         group by to_char(SAMPLE_TIME, 'yyyy-mm-dd hh24:mi:ss') ,
                  USER_ID,
                  SQL_ID,
                  PROGRAM,
                  MACHINE)
 where size_gb > 1
 order by SAMPLE_TIME;




-----查看会话打开的游标
SELECT a.SQL_ID, a.SORTS, a.ROWS_PROCESSED / a.EXECUTIONS
  FROM gv$sql a
  join gv$open_cursor b
    on a.INST_ID = b.INST_ID
       and a.sql_id = b.sql_id
 WHERE a.PARSING_SCHEMA_NAME = 'ADMIN'
       AND a.EXECUTIONS > 0
       AND a.SORTS > 0
       AND b.sid = '5138'
 ORDER BY 3;



--------改良一下v$sort_usage    11.2.0.2及以上
set linesize 1000 pagesize 500
col OSUSER for a15
col USERNAME for a15
col TABLESPACE for a15
col  CONTENTS for a15
col SEGTYPE for a15
select *
  from (SELECT k.INST_ID,
               k.KTSSOSES SADDR,
               s.SID,
               s.status,
               k.KTSSOSNO SERIAL#,
               s.USERNAME,
               s.OSUSER,
               k.KTSSOSQLID sql_id,
               k.KTSSOTSN tablespace,
               decode(k.KTSSOCNT, 0, 'PERMANENT', 1, 'TEMPORARY') contents,
               decode(k.KTSSOSEGT,
                      1,
                      'SORT',
                      2,
                      'HASH',
                      3,
                      'DATA',
                      4,
                      'INDEX',
                      5,
                      'LOB_DATA',
                      6,
                      'LOB_INDEX',
                      'UNDEFINED') segtype,
               k.KTSSOFNO,
               k.KTSSOBNO,
               k.KTSSOEXTS,
               k.KTSSOBLKS,
               round(k.KTSSOBLKS * p.value / 1024 / 1024, 2) size_Mb,
               k.KTSSOFNO segrfno#
          FROM x$ktsso k,
               gv$session s,
               (SELECT VALUE
                  FROM v$parameter a
                 WHERE a.NAME = 'db_block_size') p
         WHERE k.KTSSOSES = s.SADDR
           AND k.KTSSOSNO = s.SERIAL#
           and k.INST_ID=s.INST_ID
           /*and USERNAME in ('UIMPDB',
                            'IWEB',
                            'ADMIN',
                            'ZQ_CYYW',
                            'HKJTCY_HOSTING_ADMIN',
                            'PORTA',
                            'hkjtcy_aepemcdb',
                            'hkjtcy_bfmdb',
                            'hkjtcy_bfmsso',
                            'HKJTCY_AEPSTATDB',
                            'HKJTCY_REPORT')*/
         order by size_Mb desc)
 where rownum < 21;
----SEGTYPE列的不同的值各有什么意义：
SORT：SQL排序使用的临时段，包括order by、group by、union、distinct、窗口函数(window function)、建索引等产生的排序。
DATA：临时表(Global Temporary Table)存储数据使有的段。
INDEX：临时表上建的索引使用的段。
HASH：hash算法，如hash连接所使用的临时段。
LOB_DATA和LOB_INDEX：临时LOB使用的临时段。

----根据上述的段类型，大体可以分为三类占用：
1、SQL语句排序、HASH JOIN占用
2、临时表占用
3、临时LOB对象占用



--------------------------采集temp使用问题
create or replace procedure proc_ly_temp_message is
  V_ERROR VARCHAR2(4000);
  V_SQL   VARCHAR2(4000);
  V_DELETE   VARCHAR2(4000);

  /*
  --20160405 修改脚本中计算used_percent ，增加 *100
  create table xjmon.ly_t_collect_error
(
  hostname        VARCHAR2(50),
  instance_name   VARCHAR2(50),
  log_date        DATE,
  tablespace_name VARCHAR2(200),
  temp_total_mb   NUMBER,
  temp_used_mb    NUMBER,
  temp_free_mb    NUMBER,
  used_percent    NUMBER,
  partition_id    NUMBER,
  beizhu          VARCHAR2(4000)
) tablespace IT_XINJU;
create table xjmon.LY_T_TEMP_MESSAGE
(
  collect_date DATE,
  inst_id      NUMBER,
  sid          NUMBER,
  sql_id       VARCHAR2(13),
  tablespace   VARCHAR2(31),
  username     VARCHAR2(30),
  event        VARCHAR2(64),
  status       VARCHAR2(8),
  contents     VARCHAR2(9),
  segtype      VARCHAR2(9),
  size_mb      NUMBER
) tablespace IT_XINJU;
create index xjmon.ind_TEMP_MESSAGE_date on  xjmon.LY_T_TEMP_MESSAGE(collect_date)  tablespace IT_XINJU;
  */

begin
  V_SQL := 'insert into xjmon.ly_t_temp_message
    SELECT *
  FROM (SELECT sysdate collect_date,
               a.INST_ID,
               s.sid,
               a.sql_id,
               a.TABLESPACE,
               a.USERNAME,
               s.event,
               s.status,
               a.CONTENTS,
               a.SEGTYPE,
               round(a.BLOCKS * 8 / 1024, 2) size_mb
          FROM gv$sort_usage a
          left join gv$session s
            on a.INST_ID = s.INST_ID
               and a.SESSION_ADDR = s.SADDR
         ORDER BY a.INST_ID, a.BLOCKS DESC)
 WHERE rownum < 21 and size_mb>500';
 V_DELETE := 'delete from xjmon.ly_t_temp_message where collect_date<sysdate-10';
  ------
  BEGIN
    EXECUTE IMMEDIATE V_SQL;
    EXECUTE IMMEDIATE v_delete;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      V_ERROR := SUBSTR(SQLERRM, 1, 2500);
      INSERT INTO xjmon.ly_t_collect_error
        (LOG_DATE, BEIZHU, partition_id)
      VALUES
        (SYSDATE, V_ERROR, to_number(to_char(sysdate, 'dd')));
      COMMIT;
  END;
end;
/



DECLARE
  JOBS INT;
BEGIN

  SYS.DBMS_JOB.SUBMIT(JOB       => JOBS,
                      WHAT      => 'PROC_LY_TEMP_MESSAGE;',
                      NEXT_DATE => TO_DATE('2016-07-15 08:17:00',
                                           'YYYY-MM-DD HH24:MI:SS'),
                      INTERVAL  => 'SYSDATE+1/(24*60*60)');
  COMMIT;
END;
/


-----------------11g查询历史temp消耗较高的语句
select instance_number, username, sql_id, count(*), max(size_gb)
  from (select to_char(a.sample_time, 'yyyy-mm-dd hh24:mi:ss') sample_time,
               a.instance_number,
               b.username,
               a.sql_id,
               a.temp_space_allocated / 1024 / 1024 / 1024 size_gb
          from dba_hist_active_sess_history a, dba_users b
         where a.sample_time > sysdate - 5
               and a.user_id = b.user_id
               --and a.instance_number = 3
               )
 where size_gb > 10
 group by instance_number, username, sql_id;
 
set linesize 1000 pagesize 5000
select *
  from (select to_char(a.sample_time, 'yyyy-mm-dd hh24:mi:ss') sample_time,
               a.INST_ID,
               b.username,
               a.sql_id,
               a.temp_space_allocated / 1024 / 1024 / 1024 size_gb
          from gV$active_session_history a, dba_users b
         where a.sample_time > sysdate - 2
               and a.user_id = b.user_id)
 where size_gb > 10
 order by sample_time, INST_ID;


