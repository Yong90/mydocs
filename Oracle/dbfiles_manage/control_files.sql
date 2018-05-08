

/**************************************************/
控制文件
/************************************************/

控制文件中包括的内容：
? the database name（数据库名字）
? the timestamp of database  creation（数据库创建时间戳）
? the names and locations of associated datafiles and redo log files（数据文件和日志文件名字以及位置）
? tablespace information（表空间信息）
? datafiles offline ranges（数据文件脱机范围）
? the log history（日志历史）
? archived log information（归档日志信息） 
? backup set and backup piece information（备份集和备份片信息）
? backup datafile and redo log information（日志文件，数据文件的备份信息）
? datafile copy information（数据文件的拷贝信息）
? the current log sequence number（当前日志的序列号）
? checkkpoit information（检查点信息）
2、可以通过 dump 看到 控制文件内
直接dump controlfile：alter system set events 'immediate trace name controlf level 10'
使用： alter database backup controlfile to filename
以上两种方法生成的 dump 文件是不可读的即乱码。 只有生成 trace 后，才 是可读的。使用 alter database backup controlfile to trace 生成的 trace 文件在 udump  目录下，可以通过日期来判断。 
SQL>show parameter user_dump_dest
也可以使用如下 SQL 查询对应的 trace 文件:
SELECT a.VALUE || b.symbol || c.instance_name || '_ora_' || d.spid ||
       '.trc' trace_file
  FROM (SELECT VALUE FROM v$parameter WHERE NAME = 'user_dump_dest') a,
       (SELECT SUBSTR(VALUE, -6, 1) symbol
          FROM v$parameter
         WHERE NAME = 'user_dump_dest') b,
       (SELECT instance_name FROM v$instance) c,
       (SELECT spid
          FROM v$session s, v$process p, v$mystat m
         WHERE s.paddr = p.addr
           AND s.sid = m.sid
           AND m.statistic# = 0) d

SQL> alter database backup controlfile to trace;
TRACE_FILE
/oracle/app/oracle/diag/rdbms/anix/anix/trace/anix_ora_4477.trc



#######NORESETLOGS
CREATE CONTROLFILE REUSE DATABASE "ANIX" NORESETLOGS  NOARCHIVELOG
    MAXLOGFILES 16
    MAXLOGMEMBERS 3
    MAXDATAFILES 100
    MAXINSTANCES 8
    MAXLOGHISTORY 292
LOGFILE
  GROUP 1 '/oradata/datafile/anix/redo01.log'  SIZE 50M BLOCKSIZE 512,
  GROUP 2 '/oradata/datafile/anix/redo02.log'  SIZE 50M BLOCKSIZE 512,
  GROUP 3 '/oradata/datafile/anix/redo03.log'  SIZE 50M BLOCKSIZE 512
-- STANDBY LOGFILE
DATAFILE
  '/oradata/datafile/anix/system01.dbf',
  '/oradata/datafile/anix/sysaux01.dbf',
  '/oradata/datafile/anix/undotbs01.dbf',
  '/oradata/datafile/anix/users01.dbf',
  '/oradata/datafile/anix/example01.dbf'
CHARACTER SET AL32UTF8;
ALTER DATABASE OPEN;
ALTER TABLESPACE TEMP ADD TEMPFILE '/oradata/datafile/anix/temp01.dbf'
     SIZE 30408704  REUSE AUTOEXTEND ON NEXT 655360  MAXSIZE 32767M;


#######RESETLOGS
CREATE CONTROLFILE REUSE DATABASE "ANIX" RESETLOGS  NOARCHIVELOG
    MAXLOGFILES 16
    MAXLOGMEMBERS 3
    MAXDATAFILES 100
    MAXINSTANCES 8
    MAXLOGHISTORY 292
LOGFILE
  GROUP 1 '/oradata/datafile/anix/redo01.log'  SIZE 50M BLOCKSIZE 512,
  GROUP 2 '/oradata/datafile/anix/redo02.log'  SIZE 50M BLOCKSIZE 512,
  GROUP 3 '/oradata/datafile/anix/redo03.log'  SIZE 50M BLOCKSIZE 512
-- STANDBY LOGFILE
DATAFILE
  '/oradata/datafile/anix/system01.dbf',
  '/oradata/datafile/anix/sysaux01.dbf',
  '/oradata/datafile/anix/undotbs01.dbf',
  '/oradata/datafile/anix/users01.dbf',
  '/oradata/datafile/anix/example01.dbf'
CHARACTER SET AL32UTF8
;
ALTER DATABASE OPEN RESETLOGS;
ALTER TABLESPACE TEMP ADD TEMPFILE '/oradata/datafile/anix/temp01.dbf'
     SIZE 30408704  REUSE AUTOEXTEND ON NEXT 655360  MAXSIZE 32767M;
     
-----显示控制文件内容
oradebug  setmypid
oradebug  unlinit
alter session events 'immediate trace name controlf level 9';
oradebug tracefile_name -----获得trace name
or 
select value from v$diag_info where name = 'Diag Trace'; 







