
---------获得表的DDL语句
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/


FUNCTION GET_DDL RETURNS CLOB
 Argument Name                  Type                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 OBJECT_TYPE                    VARCHAR2                IN
 NAME                           VARCHAR2                IN
 SCHEMA                         VARCHAR2                IN     DEFAULT
 VERSION                        VARCHAR2                IN     DEFAULT
 MODEL                          VARCHAR2                IN     DEFAULT
 TRANSFORM                      VARCHAR2                IN     DEFAULT


SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON
SELECT DBMS_METADATA.GET_DDL(SCHEMA=>'HOSTS',NAME=>'TC_JOBINS_ITEM_TEMP_HISTORY',OBJECT_TYPE=>'TABLE') FROM DUAL;

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON


select owner,segment_name,bytes/1024/1024 from dba_segments where segment_name in(
'IDX_MSMSQUEUE_SS',
SQL> SELECT DBMS_METADATA.GET_DDL(SCHEMA=>'SMS',NAME=>'IDX_MSMSQUEUE_REPORTMSGID2',OBJECT_TYPE=>'INDEX') FROM DUAL;


----------收集单表统计信息
DECLARE
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(ownname => 'JL_CRM',
                                tabname => 'T_CART',
                                --granularity => 'PARTITION',
                                --partname=>'POPERATIONPROCESS0102',  
                                estimate_percent => 10,
                                method_opt =>'for all columns size repeat',
                                 -----'FOR ALL COLUMNS  SIZE 1'/'FOR  COLUMNS BILLSTATE SIZE 15'
                                no_invalidate => FALSE, cascade => TRUE,
                                degree => 16);
END;
/

DECLARE
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(ownname => 'ZC_TNMSPONBAK',
                                tabname => 'PON_ONU',
                                --granularity => 'PARTITION',
                                --partname=>'POPERATIONPROCESS0102',  
                                estimate_percent => 5,
                                method_opt =>'for all columns size repeat',
                                 -----'FOR ALL COLUMNS  SIZE 1'/'FOR  COLUMNS orgno SIZE auto'
                                no_invalidate => FALSE, cascade => TRUE,
                                degree => 16);
END;
/


ZC_CCMS.ST_INSPECTJOBS_SITE_NEW sisn,
                       ZC_CCMS.DIC_IRM_SITE_TYPE       dist,
                       ZC_CCMS.ST_INSPECTJOBS_NEW      sin,
                       ZC_CCMS.DIC_DW_NEW_PROFESSION   ddnp





 exec dbms_stats.unlock_schema_stats(ownname => 'test');

ERROR at line 1:
ORA-20005: object statistics are locked (stattype = ALL)
ORA-06512: at "SYS.DBMS_STATS", line 24281
ORA-06512: at "SYS.DBMS_STATS", line 24332
ORA-06512: at line 3

exec DBMS_STATS.LOCK_TABLE_STATS('NETFORCE','TBL_UM_ORG');




---------收集分区表统计信息
declare
  v_error varchar2(4000);
  cursor c2 is
    select distinct a.owner, a.segment_name, a.partition_name
      from dba_segments a, dba_tab_partitions b
     where a.segment_type like  'TABLE %'
       and a.segment_name not like 'BIN$%'
       and a.owner = b.table_owner
       and a.owner in('ZC_TNMSPON')  
       and a.segment_name = b.table_name
       and a.partition_name = b.partition_name
       and a.segment_name  like 'PON_ORDER_CUR_STATE';
  v_start_time date;
  v_end_time   date;
begin
  for r2 in c2 loop
    begin
      DBMS_STATS.GATHER_TABLE_STATS(ownname          => r2.owner,
                                    tabname          => r2.segment_name,
                                    partname         => r2.partition_name,
                                    estimate_percent => 5,
                                    method_opt       =>  'FOR ALL COLUMNS  SIZE repeat',
                                    no_invalidate    => false,
                                    cascade          => true,
                                    degree           => 32);
      commit;
    end;
  end loop;
end;
/


ERROR at line 1:
ORA-20005: object statistics are locked (stattype = ALL)
ORA-06512: at "SYS.DBMS_STATS", line 15027
ORA-06512: at "SYS.DBMS_STATS", line 15049
ORA-06512: at line 19

exec dbms_stats.unlock_table_stats('ZC_TNMSPON','PON_HB_FAILPOWER');





-----索引统计信息
DECLARE
  v_error VARCHAR2(4000);
  CURSOR c2 IS
    SELECT DISTINCT a.owner, a.segment_name, a.partition_name
      FROM dba_segments a
     WHERE a.segment_name NOT LIKE 'BIN$%'
       AND segment_name = UPPER('IDX_MEMBER_ECCODE_USERID');
  v_start_time DATE;
  v_end_time   DATE;
BEGIN
  FOR r2 IN c2
  LOOP
    BEGIN
      v_start_time := SYSDATE;
      DBMS_STATS.GATHER_INDEX_STATS(ownname => r2.owner,
                                    indname => r2.segment_name,
                                    partname => r2.partition_name,
                                    estimate_percent => 20,
                                    degree => 16,
                                    no_invalidate => FALSE);
      COMMIT;
    END;
  END LOOP;
END;
/





-------------按照用户收集统计信息
BEGIN
   DBMS_STATS.GATHER_SCHEMA_STATS(ownname => 'ZC_TNMSPON',
                                  estimate_percent => 1, --DBMS_STATS.AUTO_SAMPLE_SIZE
                                  options => 'GATHER AUTO',
                                  degree  => 16, --DBMS_STATS.AUTO_DEGREE
                                  method_opt => 'for all columns size repeat',  ---已存在直方图才会收集
                                  cascade => TRUE 
                                 );
END;                                 
/
Options =>’gather’       收集所有对象的统计信息
Options =>’gather empty’ 只收集还没被统计的表
Options =>’gather stale’ 只收集修改量超过10%的表
Options =>’gather auto’  相当于empty+stale ，所以我们一般设置为AUTO。

ORACLE会根据数据分布收集直方图
method_opt=>'for all columns size repeat'
只有以前收集过直方图，才会收集直方图信息，所以一般我们会设置method_opt 为repeat
method_opt=>'for all columns size auto' 
ORACLE会根据数据分布以及列的workload来确定是否收集直方图
method_opt=>'for all columns size interger'


------对分区表收集信息
BEGIN
   DBMS_STATS.GATHER_TABLE_STATS(ownname => 'SMSEXP',
                                 tabname => 'TBL_DTL_HOURPARTMT2016041409',
                                 estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
                                 method_opt => 'for all columns size repeat',
                                 degree => DBMS_STATS.AUTO_DEGREE,
                                 granularity => 'ALL',
                                 cascade=>TRUE
                                 );
END;
/
granularity => 'ALL'  收集分区，子分区，全局的统计信息
granularity => 'AUTO' 这个是默认的设置，ORACLE会根据分区类型来决定用ALL,GLOBAL AND PARTITION ,还是其他的
granularity => 'DEFAULT' 这个是过期了的
granularity => 'GLOBAL' 收集全局统计信息
granularity => 'GLOBAL AND PARTITION' 收集全局，分区统计信息，但是不收集子分区统计信息
granularity => 'PARTITION' 收集分区统计信息
granularity => 'SUBPARTITION' 收集子分区统计信息





------查看直放图
set linesize 1000 pagesize 500
col COLUMN_NAME for a30
col ENDPOINT_VALUE for a40
 SELECT OWNER, TABLE_NAME, COLUMN_NAME, ENDPOINT_NUMBER, to_char(ENDPOINT_VALUE)  ENDPOINT_VALUE
   FROM DBA_TAB_HISTOGRAMS
  WHERE TABLE_NAME = 'TBL_CP_BILLSTATEMAP'
  --and COLUMN_NAME='BILLSTATE'
  order by COLUMN_NAME;

set linesize 1000 pagesize 500
col COLUMN_NAME for a30
col ENDPOINT_VALUE for a40
 SELECT OWNER, TABLE_NAME, COLUMN_NAME, COUNT(*)
   FROM DBA_TAB_HISTOGRAMS
  WHERE TABLE_NAME = 'TBL_CP_BILLSTATEMAP'
 --and COLUMN_NAME='BILLSTATE'
  GROUP BY OWNER, TABLE_NAME, COLUMN_NAME
  ORDER BY COLUMN_NAME;


SELECT OWNER, TABLE_NAME, COLUMN_NAME, HISTOGRAM
  FROM DBA_TAB_COLUMNS
 WHERE TABLE_NAME = 'TBL_CP_BILLSTATEMAP'
   AND HISTOGRAM <> 'NONE';
