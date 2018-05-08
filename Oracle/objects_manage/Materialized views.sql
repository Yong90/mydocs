-------------创建物化视图语法
使用语法：

CREATE MATERIALIZED VIEW XX
REFRESH [
          [fast | complete | force] 
          [on demand | commit] 
          [start with date] 
          [next date] 
          [with {primary key | rowid}] 
        ]
[ENABLE | DISABLE] QUERY REWRITE

Refresh 刷新子句 
   描述 当基表发生了DML操作后，实体化视图何时采用哪种方式和基表进行同步 取值 
   FAST 采用增量刷新，只刷新自上次刷新以后进行的修改 
   COMPLETE 对整个实体化视图进行完全的刷新 
   FORCE(默认) Oracle在刷新时会去判断是否可以进行快速刷新，如果可以则采用Fast方式，否则采用Complete的方式，Force选项是默认选项 
   ON DEMAND(默认) 实体化视图在用户需要的时候进行刷新，可以手工通过DBMS_MVIEW.REFRESH等方法来进行刷新，也可以通过JOB定时进行刷新 
   ON COMMIT 实体化视图在对基表的DML操作提交的同时进行刷新 
   START WITH 第一次刷新时间 
   NEXT 刷新时间间隔 
   WITH PRIMARY KEY(默认) 生成主键实体化视图,也就是说实体化视图是基于表的主键，而不是ROWID(对应于ROWID子句)。 
   为了生成PRIMARY KEY子句，应该在表上定义主键，否则应该用基于ROWID的实体化视图。主键实体化视图允许识别实体化视图表而不影响实体化视图增量刷新的可用性 

REWRITE 字句包括ENABLE QUERY REWRITE和DISABLE QUERY REWRITE两种。
分别指出创建的实体化视图是否支持查询重写。查询重写是指当对实体化视图的基表进行查询时，Oracle会自动判断能否通过查询实体化视图来得到结果，
如果可以，则避免了聚集或连接操作，而直接从已经计算好的实体化视图中读取数据,默认 DISABLE QUERY REWRITE 

CREATE MATERIALIZED VIEW mv_TREAT_CREATEORDER_area on commit  as select  rowid row_ ,area from NETFORCE.tbl_treat_createorder;



declare
begin
  dbms_mview.refresh('DEMO.AREAMAP_ALLBROKENSITES', 'C');
end;





select  rowid row_ ,area from NETFORCE.tbl_treat_createorder  where rownum=1;


------------------检查物化视图，共用某个mv的所有mv
SELECT a.log_table,
       a.log_owner,
       b.master     mast_tab,
       c.owner      mv_owner,
       c.name       mview_name,
       c.mview_site,
       c.mview_id
  FROM dba_mview_logs a, dba_base_table_mviews b, dba_registered_mviews c
 WHERE b.mview_id = c.mview_id
   AND b.owner = a.log_owner
   AND b.master = a.master
 ORDER BY a.log_table;


---------------检查mv是否按照计划刷新
#!/bin/bash
# Source oracle OS variables, see Chapter 2 for details
. /etc/oraset $1
#
crit_var=$(sqlplus -s <<EOF
mv_maint/foo
SET HEAD OFF FEED OFF
SELECT count(*) FROM user_mviews
WHERE sysdate-last_refresh_date > 1;
EOF)
#
if [ $crit_var -ne 0 ]; then
  echo $crit_var
  echo "mv_ref refresh problem with $1" | mailx -s "mv_ref problem" \
dkuhn@gmail.com
else
  echo $crit_var
  echo "MVs ok"
fi
#
exit 0


------------------查看物化视图刷新进度
column "MVIEW BEING REFRESHED" format a25
column inserts format 9999999
column updates format 9999999
column deletes format 9999999
--
SELECT currmvowner_knstmvr || '.' || currmvname_knstmvr "MVIEW BEING REFRESHED",
       decode(reftype_knstmvr, 1, 'FAST', 2, 'COMPLETE', 'UNKNOWN') reftype,
       decode(groupstate_knstmvr, 1, 'SETUP', 2, 'INSTANTIATE', 3, 'WRAPUP',
              'UNKNOWN') STATE,
       total_inserts_knstmvr inserts,
       total_updates_knstmvr updates,
       total_deletes_knstmvr deletes
  FROM x$knstmvr x
 WHERE type_knst = 6
   AND EXISTS (SELECT 1
          FROM v$session s
         WHERE s.sid = x.sid_knst
           AND s.serial# = x.serial_knst);

-----------------调度自动刷新
#!/bin/bash
if [ $# -ne 1 ]; then
  echo "Usage: $0 SID"
  exit 1
fi
#
HOSTNAME=`uname -a | awk '{print$2}'`
MAILX='/bin/mailx'
MAIL_LIST='dkuhn@gmail.com'
ORACLE_SID=$1
jobname=SALES_MV
# Source oracle OS variables, see Chapter 2 for details.
. /etc/oraset $ORACLE_SID
#
sqlplus -s <<EOF
mv_maint/foo
WHENEVER SQLERROR EXIT FAILURE
exec dbms_mview.refresh('SALES_MV','C');
EOF
#
if [ $? -ne 0 ]; then
echo "not okay"
$MAILX -s "Problem with MV refresh on $HOSTNAME $jobname" $MAIL_LIST <<EOF
$HOSTNAME $jobname MVs not okay.
EOF
else
echo "okay"
$MAILX -s "MV refresh OK on $HOSTNAME $jobname" $MAIL_LIST <<EOF
$HOSTNAME $jobname MVs okay.
EOF
fi
#
exit 0


----------------



