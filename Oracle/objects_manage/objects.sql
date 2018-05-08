
-----------------查询对象级别开启了并发
SELECT owner, obj_type, COUNT(*)
  FROM (SELECT owner, 'table' obj_type
          FROM dba_tables
         WHERE TRIM(DEGREE) NOT IN ('1', '0')
           AND owner NOT IN ('SYS', 'SYSTEM', 'XDB', 'OLAPSYS', 'SYSMAN',
                             'MDSYS', 'TSMSYS', 'WMSYS')
        UNION
        SELECT owner, 'index' obj_type
          FROM dba_indexes
         WHERE TRIM(DEGREE) NOT IN ('1', '0')
           AND owner NOT IN ('SYS', 'SYSTEM', 'XDB', 'OLAPSYS', 'SYSMAN',
                             'MDSYS', 'TSMSYS', 'WMSYS'))
 GROUP BY owner, obj_type
 ORDER BY 1, 2, 3 DESC;
 
 
set linesize 500 pagesize 500
SELECT owner, 'table' obj_type, TABLE_NAME NAME, degree
  FROM dba_tables
 WHERE TRIM(DEGREE)  not in ( '1','0')
   AND owner NOT IN ('SYS', 'SYSTEM', 'XDB', 'OLAPSYS', 'SYSMAN', 'MDSYS',
                     'TSMSYS', 'WMSYS')
UNION
SELECT owner, 'index' obj_type, INDEX_NAME NAME, degree
  FROM dba_indexes
 WHERE TRIM(DEGREE) not in ( '1','0')
   AND owner NOT IN ('SYS', 'SYSTEM', 'XDB', 'OLAPSYS', 'SYSMAN', 'MDSYS',
                     'TSMSYS', 'WMSYS');





----------------------------对象大小
col owner for a10
col SEGMENT_NAME for a30
col PARTITION_NAME for a20
select *
  from (SELECT owner,
               SEGMENT_TYPE,
               segment_name,
               SUM(bytes) / 1024 / 1024 size_mb
          FROM dba_extents
        -- WHERE tablespace_name = 'MV_SHORT_ALARM_2'
         GROUP BY owner, SEGMENT_TYPE, segment_name
         ORDER BY size_Mb desc)
 where rownum < 21;



col owner for a10
col SEGMENT_NAME for a30
col PARTITION_NAME for a20
with tab as
 (select owner, segment_name, size_mb
    from (SELECT owner, segment_name, SUM(bytes) / 1024 / 1024 size_mb
            FROM dba_extents
           WHERE tablespace_name = 'BSARA_INDEX'
             and SEGMENT_TYPE = 'INDEX'
           GROUP BY owner, SEGMENT_TYPE, segment_name
           ORDER BY size_Mb desc)
   where rownum < 21)
select a.TABLE_OWNER||'.'||a.TABLE_NAME as table_name , a.INDEX_NAME, b.size_mb as index_mb
  from dba_indexes a, tab b
 where a.owner = b.owner
   and a.INDEX_NAME = b.segment_name
   order by index_mb desc ;



D:\life\study\tools\Oracle_Client_11gR2_x86_64\product\11.2.0\client_1\Network\Admin\tnsnames.ora




SELECT owner,
       SEGMENT_TYPE,
       segment_name,
       PARTITION_NAME,
       SUM(bytes) / 1024 / 1024
  FROM dba_extents
 WHERE tablespace_name = 'ALARM_HIS_DATA';

SELECT owner,
       SEGMENT_TYPE,
       segment_name,
       PARTITION_NAME,
       SUM(bytes) / 1024 / 1024
  FROM dba_extents
 WHERE tablespace_name = 'TNMS_DATA';

SELECT owner,
       SEGMENT_TYPE,
       segment_name,
       PARTITION_NAME,
       SUM(bytes) / 1024 / 1024 size_mb
  FROM dba_extents
 WHERE SEGMENT_NAME = 'TBL_USER'
 GROUP BY owner, SEGMENT_TYPE, segment_name, PARTITION_NAME
 ORDER BY 5;


0、查看用户表、索引、分区表占用空间
    SELECT segment_name, SUM(bytes) / 1024 / 1024 Mbytese
      FROM user_segments
     GROUP BY segment_name;
1、表占用空间
    SELECT segment_name, SUM(bytes) / 1024 / 1024 Mbytese
      FROM user_segments
     WHERE segment_type = 'TABLE'
     GROUP BY segment_name;
2、索引占用空间
    SELECT segment_name, SUM(bytes) / 1024 / 1024
      FROM user_segments
     WHERE segment_type = 'INDEX'
     GROUP BY segment_name;
3、分区表TABLE PARTITION占用空间
    SELECT segment_name, SUM(bytes) / 1024 / 1024 Mbytes
      FROM user_segments
     WHERE segment_type = 'TABLE PARTITION'
     GROUP BY segment_name;

SELECT segment_name, SUM(bytes) / 1024 / 1024 / 1024 GB
  FROM dba_segments
 WHERE segment_name = 'INVOICE'
   AND OWNER = 'OW_PAY_SZ'
 GROUP BY segment_name;


---根据对象大小排序
set linesize 1000 pagesize 500
select *
  from (SELECT OWNER, segment_name, SUM(bytes) / 1024 / 1024 / 1024 GB
          FROM dba_segments
         where tablespace_name='ZC_TNMSPONBAK'
         GROUP BY OWNER, segment_name
         order by 3 desc)
 where rownum < 100;

--------查询段区分配情况
set linesize 1000 pagesize 500
col SEGMENT_NAME for a30
col OWNER for a15
col TABLESPACE_NAME for a20
select OWNER,
       SEGMENT_NAME, /*
              PARTITION_NAME,*/
       SEGMENT_TYPE,
       TABLESPACE_NAME,
       EXTENT_ID,
       FILE_ID,
       BLOCK_ID,
       BYTES,
       BLOCKS
  from DBA_EXTENTS
 where SEGMENT_NAME in ('TFA_ALARM_CLR')
   and OWNER = 'NMOSDB'
 order by SEGMENT_NAME, EXTENT_ID;

------------------重新编译对象


SET echo OFF
SET heading OFF  

spool e:\tmp.sql;
SELECT 'alter '||object_type||' '||owner||'.'||UPPER(object_name)||' compile;'
FROM all_objects
WHERE status ='INVALID'
   	 AND object_type in ('FUNCTION','TRIGGER','JAVA SOURCE','JAVA CLASS','PROCEDURE','PACKAGE','TRIGGER')
AND owner not in('SYS','SYSTEM');

SELECT 'alter package '||owner||'.'||UPPER(object_name)||' compile body;'
 	FROM all_objects
 	WHERE status = 'INVALID'
   	 AND object_type = 'PACKAGE BODY' 
AND owner not in('SYS','SYSTEM');
spool OFF
SET heading ON
SET echo ON
@e:\tmp.sql;




-------批量编译
DECLARE 
 v_objname        user_objects.object_name%TYPE; 
 v_objtype        user_objects.object_type%TYPE; 
 CURSOR cur IS 
    SELECT object_name,object_type 
      FROM USER_OBJECTS 
     WHERE status = 'INVALID' 
       AND object_type IN ('FUNCTION','JAVA SOURCE','JAVA CLASS','PROCEDURE','PACKAGE','TRIGGER'); 
BEGIN 
 OPEN cur; 
 LOOP 
    FETCH cur into v_objname, v_objtype; 
 
EXIT WHEN cur%NOTFOUND; 
    BEGIN 
      EXECUTE Immediate 'alter ' || v_objtype || ' ' || v_objname||' Compile'; 
      dbms_output.put_line('编译' || v_objtype || ' ' || v_objname || '()成功'); 
    EXCEPTION 
      WHEN OTHERS THEN 
        dbms_output.put_line('编译' || v_objtype ||' ' || v_objname || '()失败.' || SQLERRM); 
    END; 
 END LOOP; 
 CLOSE cur; 
END; 




-----------批量编译失效对象
@?/rdbms/admin/utlrp.sql


-------------------------------获取对象DDL语句

set long 99999999
set linesize 5000  pagesize 5000
SELECT DISTINCT comd
  FROM (SELECT DISTINCT dbms_metadata.get_ddl('INDEX', a.INDEX_NAME, a.owner) ||
                        ' parallel 8 ;' comd
          FROM dba_indexes a
         WHERE owner IN ('WPS_SCASYSMSG', 'WPS_BPCMSG', 'WPS_COMMONDB',
                         'WPS_CEIMSG', 'WPS_BSPACE', 'WPS_BPCOBS', 'WPS_CEIDB',
                         'WPS_SCAAPPMSG', 'WPS_BPCDB')
         ORDER BY table_name);
--去除storage等多余参数  
set long 99999999
set linesize 5000  pagesize 5000     
EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false); 
SELECT  dbms_metadata.get_ddl('TABLE','PON_ORDER_CUR_STATE','ZC_TNMSPON')  from dual;



常见错误
SQL> select dbms_metadata.get_ddl('TABLE','PC','SCOTT') from dual;
ERROR:
ORA-19206: Invalid value for query or REF CURSOR parameter
ORA-06512: at "SYS.DBMS_XMLGEN", line 83
ORA-06512: at "SYS.DBMS_METADATA", line 345
ORA-06512: at "SYS.DBMS_METADATA", line 410
ORA-06512: at "SYS.DBMS_METADATA", line 449
ORA-06512: at "SYS.DBMS_METADATA", line 615
ORA-06512: at "SYS.DBMS_METADATA", line 1221
ORA-06512: at line 1
no rows selected
解决办法：运行 $ORACLE_HOME/rdbms/admin/catmeta.sql   





dbms_metadata包中的get_ddl函数定义 
FUNCTION get_ddl ( object_type IN VARCHAR2,
name IN VARCHAR2,
schema IN VARCHAR2 DEFAULT NULL,
version IN VARCHAR2 DEFAULT 'COMPATIBLE',
model IN VARCHAR2 DEFAULT 'ORACLE',
transform. IN VARCHAR2 DEFAULT 'DDL') RETURN CLOB; 
注意如果使用sqlplus需要进行下列格式化，特别需要对long进行设置，否则无法显示完整的SQL
set linesize 180    
set pages 999
set long 90000    
查看创建用户表的SQL
查看当前用户表的SQL 
select dbms_metadata.get_ddl('TABLE','EMPLOYEES') from dual; 
查看其他用表或索引的SQL
SELECT DBMS_METADATA.GET_DDL('TABLE','DEPT','SCOTT') FROM DUAL;
查看创建用户索引的SQL 
查看所需表的索引
SQL> select INDEX_NAME, INDEX_TYPE, TABLE_NAME from user_indexes WHERE table_name='EMP'; 
查看当前用户索引的SQL
select dbms_metadata.get_ddl('INDEX','PK_DEPT') from dual;
查看其他用户索引的SQL
 select dbms_metadata.get_ddl('INDEX','PK_DEPT','SCOTT') from dual; 
查看创建主键的SQL 
查看所需表的约束
SQL> select owner, table_name, constraint_name, constraint_type from user_constraints where table_name='EMP'; 
查看创建主键的SQL
SELECT DBMS_METADATA.GET_DDL('CONSTRAINT','EMP_PK') FROM DUAL; 
查看创建外键的SQL
SQL> SELECT DBMS_METADATA.GET_DDL('REF_CONSTRAINT','EMP_FK_DEPT') FROM DUAL; 
查看创建VIEW的语句 
查看当前用户视图的SQL
SQL> SELECT dbms_metadata.get_ddl('VIEW', 'MY_TABLES')
查看其他用户视图的SQL
SQL> SELECT dbms_metadata.get_ddl('VIEW', 'MY_TABLES','SCOTT') FROM DUAL; 
查看创建视图的SQL也可以
SQL> select text from user_views where view_name=upper('&view_name'); 
DBMS_METADATA.GET_DDL的一些使用技巧 
1、得到一个用户下的所有表，索引，存储过程，函数的ddl 
SELECT DBMS_METADATA.GET_DDL(U.OBJECT_TYPE, u.object_name)
FROM USER_OBJECTS u
where U.OBJECT_TYPE IN ('TABLE','INDEX','PROCEDURE','FUNCTION'); 
2、得到所有表空间的ddl语句 
SELECT DBMS_METADATA.GET_DDL('TABLESPACE', TS.tablespace_name)
FROM DBA_TABLESPACES TS; 
3、得到所有创建用户的ddl 
SELECT DBMS_METADATA.GET_DDL('USER', U.username) FROM DBA_USERS U;
    
