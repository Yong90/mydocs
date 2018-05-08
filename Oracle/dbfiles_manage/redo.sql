/***************/日志文件/************************/
ALTER DATABASE 
    ADD LOGFILE GROUP 4 ('/oradata/{DB_UNIQUE_NAME}/redo04_1.log',
    '/oradata/{DB_UNIQUE_NAME}/redo04_2.log') SIZE 1024M

增加删除日志组：
/*增加*/
/*文件系统：*/
alter database add logfile THREAD 2 group 10  ('/oradata01/dkh/redo01_01.redo.log','/data02/xspaasc/redo01_02.redo.log') size 2048M ;
alter database add logfile group 2  ('/data02/xspaasc/redo02_01.redo.log','/data02/xspaasc/redo02_02.redo.log') size 2048M ;
alter database add logfile group 3  ('/data02/xspaasc/redo03_01.redo.log','/data02/xspaasc/redo03_02.redo.log') size 2048M ;
alter database add logfile group 4  ('/data02/xspaasc/redo04_01.redo.log','/data02/xspaasc/redo04_02.redo.log') size 2048M ;
alter database add logfile group 5  ('/data02/xspaasc/redo05_01.redo.log','/data02/xspaasc/redo05_02.redo.log') size 2048M ;
alter database add logfile group 6  ('/data02/xspaasc/redo06_01.redo.log','/data02/xspaasc/redo06_02.redo.log') size 2048M ;
alter database add logfile group 7  ('/data02/xspaasc/redo07_01.redo.log','/data02/xspaasc/redo07_02.redo.log') size 2048M ;
alter database add logfile group 8  ('/data02/xspaasc/redo08_01.redo.log','/data02/xspaasc/redo08_02.redo.log') size 2048M ;

ALTER DATABASE DROP LOGFILE GROUP 1;
ALTER DATABASE DROP LOGFILE GROUP 2;
ALTER DATABASE DROP LOGFILE GROUP 3;
ALTER DATABASE DROP LOGFILE GROUP 4;

alter database add logfile THREAD 2 group 20  ('+DATA_DB','+FLASH_RECOVERY') size 256M ;
alter database add logfile THREAD 2 group 21  ('+DATA_DB','+FLASH_RECOVERY') size 256M ;
alter database add logfile THREAD 2 group 22  ('+DATA_DB','+FLASH_RECOVERY') size 256M ;
alter database add logfile THREAD 2 group 23  ('+DATA_DB','+FLASH_RECOVERY') size 256M ;
alter database add logfile THREAD 2 group 24  ('+DATA_DB','+FLASH_RECOVERY') size 256M ;
alter database add logfile THREAD 2 group 25  ('+DATA_DB','+FLASH_RECOVERY') size 256M ;
alter database add logfile THREAD 2 group 26  ('+DATA_DB','+FLASH_RECOVERY') size 256M ;











/*裸卷：*/
alter database add logfile group 4 ('/dev/vgX/rredo_xx_NN',’ /dev/vgX/rredo_xx_MM’) size 50M;

/*删除**/
ALTER DATABASE DROP LOGFILE GROUP 5;  -------非CURRENT、ACTIVE状态
ALTER DATABASE DROP LOGFILE GROUP 6; 
ALTER DATABASE DROP LOGFILE GROUP 7; 
ALTER DATABASE DROP LOGFILE GROUP 8; 

---------参数
archive_lag_target   设置日志最大的切换时间，一般Data Guard 环境设置1800秒，默认值为0（禁用）
fast_start_mttr_target
db_writer_processes

日志成员维护：
#####增加日志成员
 alter database add logfile member '/data02/xspaasc/redo03_01.log' to group 3;
ALTER DATABASE ADD LOGFILE THREAD 2 GROUP 8 ('+DATA_DG','+DATA_DG') size 1024M reuse;


SELECT b.GROUP#, b.TYPE, b.MEMBER, b.IS_RECOVERY_DEST_FILE
  FROM v$logfile b 
 ORDER BY b.GROUP#;

#####删除日志成员
SQL> alter database drop logfile member '/data02/xspaasc/redo01_02.log' ;

######日志成员重命名
SQL> alter database rename file '/oradata/datafile/anix/redo03.log' To '/oradata/datafile/anix/redo03_1.redo';

####清除ASM磁盘组中的归档
sqlplus / as sysdba
set linesize 1000
select 'alter diskgroup ARCHIVE_DG  drop file ' || '''' || name ||'''' || ';' from V$ARCHIVED_LOG;
su - grid
sqlplus "/as sysdba"
alter diskgroup ARCHIVE_DG drop file '+DISK_GROUP1/v10gasm//1_1809_563453055.dbf' ;


         
set linesize 1000  pagesize 500
col members for a50
select GROUP#,THREAD#,BYTES/1024/1024 BYTES_MB ,STATUS from v$log;  


set linesize 1000  pagesize 500
col member for a50
select * from v$logfile;  

######初始化日志组
alter database clear logfile group 4;  
alter database clear unarchived logfile group 4;   -----使用unarchived 避免归档，使用后需对数据库进行全备



归档日志相关视图：V$ARCHIVED_LOG、V$ARCHIVE_DEST、V$LOG_HISTORY
archive log list;  ----查看归档
--通过参数log_archive_dest_n 设置多个归档路径
Alter system set log_archive_dest_1='location=/oradata/anixfs/arc' scope=spfile;
----通过参数设置归档日志文件格式log_archive_format建议格式 SID_%t_%s_%r.arc
Alter   system set log_archive_format='anixfs_%t_%s_%r.arc' scope=spfile;
--修改数据库是自动归档
Alter    system   set     log_archive_start=true    scope=spfile;
----设置手动归档及执行手动归档
Alter    database    archive     log   manual;
alter system archive log all ; 

####数据库设置归档：
1、设置参数：log_archive_dest_n、log_archive_format
2、关库： host echo $ORACLE_SID
          Shutdown immediate
3、启动到mount： startup  mount;
4、开启归档：Alter database archivelog;
5、打开数据库：Alter database open；



监听日志清理
1、进入$ORACLE_HOME/network/log,查看日志大小： du -a
2、关闭监听记录日志信息：lsnrctl set log_status off
3、备份监听日志：mv listener.log listener_`date +%Y%m%d`.log.bak
4、重新设置，让监听记录日志：lsnrctl set log_status on




----当前重做日志文件(redo logfile)已被用到了什么位置(position)、还剩余多少空间和已使用的百分比，监控当前重做日志文件使用情况
set linesize 200 pagesize 1400;
select le.leseq "Current log sequence No",
       100 * cp.cpodr_bno / le.lesiz "Percent Full",
       (cpodr_bno - 1) * 512  "bytes used exclude header",
       le.lesiz * 512 - cpodr_bno * 512 "Left space",
       le.lesiz  *512       "logfile size"
  from x$kcccp cp, x$kccle le
 where LE.leseq = CP.cpodr_seq
   and bitand(le.leflg, 24) = 8;
 
 
Current log sequence No Percent Full bytes used exclude header Left space logfile size
----------------------- ------------ ------------------------- ---------- ------------
                    189   90.7612305                  95169536    9687552    104857600

/*  如上结果显示当前重做日志号为189，使用量百分比是90.7%
    当前日志被使用到了95169536+512 bytes(重做日志文件头)的位置，
    还剩余9687552 bytes的空间，该重做日志的总大小为104857600=100MB
*/

---------------------------------快照期间的redo变化
select b.snap_id,
       to_char(b.end_interval_time, 'yyyy-mm-dd hh24:mi:ss') time,
       a.value,
       a.value - lag(a.value, 1, a.value) over(order by a.snap_id) snap_redo_size_diff
  from dba_hist_sysstat a, dba_hist_snapshot b
 where a.snap_id = b.snap_id
       and a.stat_name = 'redo size'
       and end_interval_time > sysdate - 3
 order by 2;


--------------------列出Oracle每小时的redo重做日志产生量
WITH times AS
 (SELECT /*+ MATERIALIZE */
   hour_end_time
    FROM (SELECT (TRUNC(SYSDATE, 'HH') + (2 / 24)) - (ROWNUM / 24) hour_end_time
            FROM DUAL
          CONNECT BY ROWNUM <= (1 * 24) + 3),
         v$database
   WHERE log_mode = 'ARCHIVELOG')
SELECT hour_end_time,
       NVL(ROUND(SUM(size_mb), 3), 0) size_mb,
       i.instance_name
  FROM (SELECT hour_end_time,
               CASE
                 WHEN (hour_end_time - (1 / 24)) > lag_next_time THEN
                  (next_time + (1 / 24) - hour_end_time) *
                  (size_mb / (next_time - lag_next_time))
                 ELSE
                  0
               END + CASE
                 WHEN hour_end_time < lead_next_time THEN
                  (hour_end_time - next_time) *
                  (lead_size_mb / (lead_next_time - next_time))
                 ELSE
                  0
               END + CASE
                 WHEN lag_next_time > (hour_end_time - (1 / 24)) THEN
                  size_mb
                 ELSE
                  0
               END + CASE
                 WHEN next_time IS NULL THEN
                  (1 / 24) * LAST_VALUE(CASE
                                          WHEN next_time IS NOT NULL
                                               AND lag_next_time IS NULL THEN
                                           0
                                          ELSE
                                           (size_mb / (next_time - lag_next_time))
                                        END IGNORE NULLS)
                  OVER(ORDER BY hour_end_time DESC, next_time DESC)
                 ELSE
                  0
               END size_mb
          FROM (SELECT t.hour_end_time,
                       arc.next_time,
                       arc.lag_next_time,
                       LEAD(arc.next_time) OVER(ORDER BY arc.next_time ASC) lead_next_time,
                       arc.size_mb,
                       LEAD(arc.size_mb) OVER(ORDER BY arc.next_time ASC) lead_size_mb
                  FROM times t,
                       (SELECT next_time,
                               size_mb,
                               LAG(next_time) OVER(ORDER BY next_time) lag_next_time
                          FROM (SELECT next_time, SUM(size_mb) size_mb
                                  FROM (SELECT DISTINCT a.sequence#,
                                                        a.next_time,
                                                        ROUND(a.blocks *
                                                              a.block_size / 1024 / 1024) size_mb
                                          FROM v$archived_log a,
                                               (SELECT /*+ no_merge */
                                                 CASE
                                                   WHEN TO_NUMBER(pt.VALUE) = 0 THEN
                                                    1
                                                   ELSE
                                                    TO_NUMBER(pt.VALUE)
                                                 END VALUE
                                                  FROM v$parameter pt
                                                 WHERE pt.name = 'thread') pt
                                         WHERE a.next_time > SYSDATE - 3
                                           AND a.thread# = pt.VALUE
                                           AND ROUND(a.blocks * a.block_size / 1024 / 1024) > 0)
                                 GROUP BY next_time)) arc
                 WHERE t.hour_end_time =
                       (TRUNC(arc.next_time(+), 'HH') + (1 / 24)))
         WHERE hour_end_time > TRUNC(SYSDATE, 'HH') - 1 - (1 / 24)),
       v$instance i
 WHERE hour_end_time <= TRUNC(SYSDATE, 'HH')
 GROUP BY hour_end_time, i.instance_name
 ORDER BY hour_end_time;




------查询浪费的redo
select * from v$sysstat where name in ('redo size','redo wastage');




-------归档日志信息
set linesize 1000 pagesize 500
col FIRST_TIME for a35
SELECT to_char(FIRST_TIME, 'yymmdd:hh24:mi:ss') FIRST_TIME,
       t.THREAD#,
       t.SEQUENCE#,
       SUM(T.BLOCKS * T.BLOCK_SIZE / power(1024, 3)) / COUNT(*) GB
  FROM v$archived_log t
 GROUP BY to_char(FIRST_TIME, 'yymmdd:hh24:mi:ss'), t.THREAD#, t.SEQUENCE#
 ORDER BY 1,2,3;



--------redo  日志量
select b.snap_id,
       to_char(b.end_interval_time, 'yyyy-mm-dd hh24:mi:ss') time,
       a.instance_number inst_id,
       a.value,
       a.value - lag(a.value, 1, a.value) over(order by a.snap_id) snap_redo_size_diff
  from dba_hist_sysstat a, dba_hist_snapshot b
 where a.snap_id = b.snap_id
   and a.stat_name = 'redo size'
   and a.instance_number = 2
   and b.instance_number = 2
   and end_interval_time > sysdate - 7


1、查询数据库的归档日志视图，统计核心数据库每天的归档日志量。 

select to_char(first_time, 'YYYYMMDD'),
       count(recid),
       trunc(sum(blocks * block_size / 1024 / 1024 / 1024), 2)
  from v$archived_log
 group by to_char(first_time, 'YYYYMMDD')
 order by to_char(first_time, 'YYYYMMDD');

2、数据表记录修改统计 

col owner for a10;
col table_name for a20;
col num_rows for a20;
col last_analyzed for a20;
col trunc(sysdate - b.last_analyzed) for a20;
col inserts for a20;
col updates for a20;
col deletes for a20;
col trunc(a.inserts / ceil(sysdate - b.last_analyzed)) for a20;
col trunc(a.deletes / ceil(sysdate - b.last_analyzed)) for a20;
col trunc(a.updates / ceil(sysdate - b.last_analyzed)) for a20;
col trunc((a.inserts + a.updates + a.deletes) / ceil(sysdate - b.last_analyzed)) for a20;

select b.owner,
       b.table_name,
       b.num_rows,
       b.last_analyzed,
       trunc(sysdate - b.last_analyzed),
       a.inserts,
       a.updates,
       a.deletes,
       trunc(a.inserts / ceil(sysdate - b.last_analyzed)),
       trunc(a.updates / ceil(sysdate - b.last_analyzed)),
       trunc(a.deletes / ceil(sysdate - b.last_analyzed)),
       trunc((a.inserts + a.updates + a.deletes) /
             ceil(sysdate - b.last_analyzed))
  from sys.dba_tab_modifications a, dba_tables b
 where a.table_owner = b.owner
   and a.table_name = b.table_name
   and a.partition_name is null
   and b.owner in ('PRDB', 'RAWDB')
 order by (a.inserts + a.updates + a.deletes) /
          ceil(sysdate - b.last_analyzed) desc;


SELECT * FROM v$log WHERE a.THREAD# = 1;

SELECT b.SEQUENCE#,
       b.FIRST_TIME,
       a.SEQUENCE#,
       a.FIRST_TIME,
       round(((a.FIRST_TIME - b.FIRST_TIME) * 24) * 60, 2)
  FROM v$log_history a, v$log_history b
 WHERE a.SEQUENCE# = b.SEQUENCE# + 1
   AND b.THREAD# = 1
 ORDER BY a.SEQUENCE# DESC;

SELECT sequence#,
       first_time,
       nexttime,
       round(((first_time - nexttime) * 24) * 60, 2) diff
  FROM (SELECT sequence#,
               first_time,
               lag(first_time) over(ORDER BY sequence#) nexttime
          FROM v$log_history
         WHERE thread# = 1)
 ORDER BY sequence# DESC;



--日志频率
set linesize 1000 pagesize 5000
column  day     format a20              heading 'Day'
column  d_0     format a3               heading '00'
column  d_1     format a3               heading '01'
column  d_2     format a3               heading '02'
column  d_3     format a3               heading '03'
column  d_4     format a3               heading '04'
column  d_5     format a4               heading '05'
column  d_6     format a3               heading '06'
column  d_7     format a3               heading '07'
column  d_8     format a3               heading '08'
column  d_9     format a4              heading '09'
column  d_10    format a3               heading '10'
column  d_11    format a3               heading '11'
column  d_12    format a3               heading '12'
column  d_13    format a3               heading '13'
column  d_14    format a3               heading '14'
column  d_15    format a3               heading '15'
column  d_16    format a3               heading '16'
column  d_17    format a3               heading '17'
column  d_18    format a3               heading '18'
column  d_19    format a3               heading '19'
column  d_20    format a3               heading '20'
column  d_21    format a3               heading '21'
column  d_22    format a3               heading '22'
column  d_23    format a3               heading '23'
SELECT THREAD# ,substr(to_char(FIRST_TIME, 'YYYY/MM/DD,DY'), 1, 15) DAY,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '00', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '00', 1,
                          0))) d_0,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '01', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '01', 1,
                          0))) d_1,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '02', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '02', 1,
                          0))) d_2,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '03', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '03', 1,
                          0))) d_3,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '04', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '04', 1,
                          0))) d_4,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '05', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '05', 1,
                          0))) d_5,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '06', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '06', 1,
                          0))) d_6,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '07', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '07', 1,
                          0))) d_7,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '08', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '08', 1,
                          0))) d_8,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '09', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '09', 1,
                          0))) d_9,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '10', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '10', 1,
                          0))) d_10,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '11', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '11', 1,
                          0))) d_11,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '12', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '12', 1,
                          0))) d_12,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '13', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '13', 1,
                          0))) d_13,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '14', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '14', 1,
                          0))) d_14,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '15', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '15', 1,
                          0))) d_15,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '16', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '16', 1,
                          0))) d_16,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '17', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '17', 1,
                          0))) d_17,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '18', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '18', 1,
                          0))) d_18,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '19', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '19', 1,
                          0))) d_19,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '20', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '20', 1,
                          0))) d_20,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '21', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '21', 1,
                          0))) d_21,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '22', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '22', 1,
                          0))) d_22,
       decode(SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '23', 1,
                         0)), 0, '-',
              SUM(decode(substr(to_char(FIRST_TIME, 'HH24'), 1, 2), '23', 1,
                          0))) d_23
  FROM v$log_history
 WHERE first_time > SYSDATE - 7
 --and THREAD#=1
 GROUP BY THREAD# ,substr(to_char(FIRST_TIME, 'YYYY/MM/DD,DY'), 1, 15)
 ORDER BY THREAD# ,substr(to_char(FIRST_TIME, 'YYYY/MM/DD,DY'), 1, 15) ;

select  to_char(FIRST_TIME, 'yyyy-mm-dd'),count(*)
FROM v$log_history
 WHERE first_time > SYSDATE - 14
 group by to_char(FIRST_TIME, 'yyyy-mm-dd')
 order by 1;

set linesize 1000 pagesize 5000
col  end_time for a20
select end_time, conn1, conn2
  from (select to_char(b.END_INTERVAL_TIME, 'yyyy-mm-dd hh24:mi') end_time,
               a.INSTANCE_NUMBER,
               a.CURRENT_UTILIZATION
          from DBA_HIST_RESOURCE_LIMIT a, DBA_HIST_SNAPSHOT b
         where a.SNAP_ID = b.SNAP_ID
               and a.INSTANCE_NUMBER = b.INSTANCE_NUMBER
               and b.END_INTERVAL_TIME>sysdate -7
               and a.resource_name in ('sessions'))
pivot(max(CURRENT_UTILIZATION)
   for instance_number in('1' as conn1, '2' as conn2))
 order by end_time;
