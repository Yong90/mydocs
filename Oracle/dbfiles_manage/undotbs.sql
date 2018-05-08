-------设定是否可以覆盖没有过期的块
alter database undo  undotbs_name retention noguarantee/guarantee;

select a.END_TIME,
       UNDOBLKS /*消耗undo块总和*/,
       MAXQUERYLEN /*最长查询时间*/,
       MAXQUERYID /*最长查询sql_id*/,
       TXNCOUNT   /*总事务量*/,
       a.EXPSTEALCNT /*偷窃过期区次数*/,
       a.EXPBLKRELCNT /*偷窃成功的块数*/,
       a.EXPBLKREUCNT /*同回滚段中重用过期块数*/,
       a.UNXPSTEALCNT /*偷窃未过期块次数*/,
       a.UNXPBLKRELCNT /*偷窃成功未过期块数*/,
       a.UNXPBLKREUCNT /*重用未过期块数*/
  from v$undostat a;

---------------undo膨胀问题分析
with tab_min_extend as
 (select distinct b.SEGMENT_NAME,
         b.TABLESPACE_NAME,
         min(b.EXTENT_ID) over(partition by b.SEGMENT_NAME, b.TABLESPACE_NAME) min_extend,
         b.STATUS
    from dba_undo_extents b
   where b.STATUS <> 'EXPIRED'),
tab_sge_size as
 (select distinct d.SEGMENT_NAME,
                  d.TABLESPACE_NAME,
                  sum(d.BYTES) over(partition by d.SEGMENT_NAME, d.TABLESPACE_NAME) seg_size
    from dba_undo_extents d),
tab_sge_unused as
 (select distinct a.SEGMENT_NAME,
                  a.TABLESPACE_NAME,
                  sum(a.bytes) over(partition by a.SEGMENT_NAME, a.TABLESPACE_NAME) as sge_unused
    from dba_undo_extents a, tab_min_extend c, tab_sge_size e
   where a.SEGMENT_NAME = c.SEGMENT_NAME
     and a.TABLESPACE_NAME = c.TABLESPACE_NAME
     and a.EXTENT_ID < c.min_extend)
select roll.usn,al.TABLESPACE_NAME, al.SEGMENT_NAME, al.seg_size, un.sge_unused
  from tab_sge_size al, tab_sge_unused un,v$rollname roll
 where al.SEGMENT_NAME = un.SEGMENT_NAME(+)
   and al.TABLESPACE_NAME = un.TABLESPACE_NAME(+)
   and al.SEGMENT_NAME=roll.name
order by roll.usn;
-----------undo重用规则

wechat = WechatExt(username='liuyong@shsnc.com', password='Weixin@1205')












-----undo表空间使用情况 （如果used_rag>60%需要查具体是哪个进程）
set linesize 200
col used_pct format a8
select b.tablespace_name,
       nvl(used_undo,0) "USED_UNDO(M)",
       total_undo "Total_undo(M)",
       trunc(nvl(used_undo,0) / total_undo * 100, 2) || '%' used_PCT
  from (select nvl(sum(bytes / 1024 / 1024), 0) used_undo, tablespace_name
          from dba_undo_extents
         where status = 'ACTIVE'
         group by tablespace_name) a,
       (select tablespace_name, sum(bytes / 1024 / 1024) total_undo
          from dba_data_files
         where tablespace_name in
               (select value
                  from v$spparameter
                 where name = 'undo_tablespace'
                   and (sid = (select instance_name from v$instance) or
                       sid = '*'))
         group by tablespace_name) b
 where a.tablespace_name (+)= b.tablespace_name
/

--注:包含UNEXPIRED类型 （主要是用这个）
select b.tablespace_name,
       nvl(used_undo,0) "USED_UNDO(M)",
       total_undo "Total_undo(M)",
       trunc(nvl(used_undo,0) / total_undo * 100, 2) || '%' used_PCT
  from (select nvl(sum(bytes / 1024 / 1024), 0) used_undo, tablespace_name
          from dba_undo_extents
         where status in ( 'ACTIVE','UNEXPIRED')
         group by tablespace_name) a,
       (select tablespace_name, sum(bytes / 1024 / 1024) total_undo
          from dba_data_files
         where tablespace_name in
               (select value
                  from v$spparameter
                 where name = 'undo_tablespace'
                   and (sid in  (select instance_name from gv$instance) or
                       sid = '*'))
         group by tablespace_name) b
 where a.tablespace_name (+)= b.tablespace_name
/


SELECT tablespace_name, status, SUM(bytes) / 1024 / 1024/1024  size_gb
  FROM dba_undo_extents
 WHERE tablespace_name LIKE 'UNDOTBS%'
 GROUP BY tablespace_name, status
 ORDER BY 1 
 /
 
---------回滚段等待比率大于1%
SELECT decode(r1.hwmsize, NULL, drs.segment_name || ' (Offline)',
              drs.segment_Name) "Rollback Segment Name",
       COUNT(ds.SEGMENT_NAME) "Segment Count",
       r1.HWMSIZE "High Water Mark",
       r1.OptSize "Optimal Size",
       r1.Shrinks "Shrinks",
       r1.AveShrink "Average Shrink",
       r1.AveActive "Avg Active Size",
       r1.Wraps "Wraps",
       r1.Extends "Extends",
       r1.gets "Gets",
       r1.waits "Waits",
       Round((r1.Waits * 100 / r1.Gets), 2) "Wait Ratio (%)",
       drs.tablespace_name "Tablespace",
       drs.initial_extent "Extent Size"
  FROM sys.dba_segments ds, Sys.V_$Rollstat r1, sys.dba_rollback_segs drs
 WHERE r1.usn(+) = drs.segment_id
   AND drs.segment_name = ds.segment_name
   AND ds.segment_type = 'ROLLBACK'
   AND Round((r1.Waits * 100 / r1.Gets), 2) > 1
 GROUP BY r1.hwmsize,
          drs.segment_name,
          r1.OptSize,
          r1.Shrinks,
          r1.AveShrink,
          r1.AveActive,
          r1.Wraps,
          r1.Extends,
          r1.gets,
          r1.waits,
          drs.tablespace_name,
          drs.initial_extent
 ORDER BY 3;




 
-----各个session使用的undo
set linesize 1000 pagesize 500
col rollname for a25
col db_os_term_gram for a50
col sid_serial_spid for a20
col sql_id for a15
col COMMAND_NAME for a15
col SELECT_DATE for a15
col undo_kb for  999999999
col login_time for  a20
col last_txn for  a20
col trans_starttime for  a30

SELECT r.name rollname,
       nvl(s.SCHEMANAME, 'None') || '/' || s.osuser || '/' || s.TERMINAL || '/' ||
       s.PROGRAM db_os_term_gram,
       s.sid||'/'|| s.serial#||'/'||p.spid sid_serial_spid,
       s.sql_id,/*
       (select COMMAND_NAME
          from v$sqlcommand comm
         where s.COMMAND = comm.COMMAND_TYPE) COMMAND_NAME,*/
       t.used_ublk * TO_NUMBER(x.value) / 1024 AS undo_kb,
       TO_CHAR(s.logon_time, 'yy/mm/dd hh24:mi:ss') AS login_time,
       TO_CHAR(SYSDATE - (s.last_call_et) / 86400, 'yy/mm/dd hh24:mi:ss') AS last_txn,
       t.START_TIME trans_starttime
  FROM v$process     p,
       v$rollname    r,
       v$session     s,
       v$transaction t,
       v$parameter   x
 WHERE s.taddr = t.addr
       AND s.paddr = p.addr
       AND r.usn = t.xidusn(+)
       AND x.name = 'db_block_size'
--and s.sid in  (1908,960,1387,1448) 
 ORDER BY undo_kb DESC;







