

创建同义词语句：
　 create public synonym sy_table_name for user.table_name[@dblink];
创建私有同义词语法：
   Create [OR REPLACE] SYNONYM [schema.]synonym_name FOR [schema.]object_name;
   其中：OR REPLACE表示在同义词存在的情况下替换该同义词。
         synonym_name表示要创建的同义词的名称。
         object_name指定要为之创建同义词的对象的名称。
创建公有同义词语法：
   Create PUBLIC SYNONYM synonym_name FOR [schema.]object_name;
删除同义词：
drop public synonym sy_table_name;
视图：select * from dba_synonyms
     




视图创建语法：
CREATE [OR REPLACE] [FORCE|NOFORCE] VIEW view_name [(alias[, alias]...)] 
AS subquery 
[WITH CHECK OPTION [CONSTRAINT constraint]] 
[WITH READ ONLY]

CREATE  OR  REPLACE  VIEW  dept_sum_vw 
(name,minsal,maxsal,avgsal) 
AS SELECT d.dname,min(e.sal),max(e.sal),avg(e.sal) 
FROM    emp e,dept d 
WHERE  e.deptno=d.deptno 
GROUP  BY  d.dname;
视图：user_views、dba_views




序列
语法：
CREATE SEQUENCE sequence  //创建序列名称
    [INCREMENT BY n]  //递增的序列值是n 如果n是正数就递增,如果是负数就递减 默认是1
    [START WITH n]    //开始的值,递增默认是minvalue 递减是maxvalue
    [{MAXVALUE n | NOMAXVALUE}] //最大值
    [{MINVALUE n | NOMINVALUE}] //最小值
    [{CYCLE | NOCYCLE}] //循环/不循环
    [{CACHE n | NOCACHE}]
    [{order | noorder}];//分配并存入到内存中

使用序列：
只要定义了 SEQ_EXAMPLE ，你就可以用使CURRVAL，NEXTVAL
 CURRVAL=返回 sequence的当前值
 NEXTVAL=增加sequence的值，然后返回 sequence 值
例如：
  SEQ_EXAMPLE.CURRVAL
  SEQ_EXAMPLE.NEXTVAL
select * from dba_sequences a where a.sequence_name ='SEQ_TM_INTEGRATIONLOG';

SELECT a.owner,
       a.object_name,
       to_char(a.created, 'yyyy-mm-dd hh24:mi:ss') created,
       to_char(a.last_ddl_time, 'yyyy-mm-dd hh24:mi:ss') last_ddl_time
  FROM dba_objects a
 WHERE a.object_name = 'SEQ_TM_INTEGRATIONLOG';


dblink
语法：
#####创建
CREATE [PUBLIC] DATABASE LINK dblink_name CONNECT TO user IDENTIFIED BY password USING ‘connect_string’; 
#####删除
DROP [PUBLIC] DATABASE LINK dblink;
####配置本地服务
create public database
　　link  torac connect to scott
　　identified by tiger using 'rac01'

CREATE  DATABASE LINK ZZ_AEPSTATDB_DB_LINK_EMCDB  CONNECT TO zz_aepemcdb IDENTIFIED BY "Aepemcdb123!@#" USING 'ZZ_AEPSTATDB_DB_LINK_EMCDB'; 

#####直接建立链接
create database link torac
　　 connect to scott identified by tiger 
　　 using '(DESCRIPTION = 
　　 (ADDRESS_LIST = 
　　 (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.10.100 )(PORT = 1521)) 
　　 ) 
　　 (CONNECT_DATA = 
　　 (SERVICE_NAME = rac01) 
　　 ) 
　　 )';

set linesize 1000 pagesize 500
col owner for a20
col DB_LINK for a30
col username for a20
col HOST for a70
select OWNER,DB_LINK,USERNAME,to_date(CREATED,'yyyy-mm-dd hh24:mi:ss') CREATED,HOST  from DBA_DB_LINKS  where DB_LINK like 'HWDEVICE%';


SELECT KTUXEUSN,
       KTUXESLT,
       KTUXESQN, /* Transaction ID */
       KTUXESTA STATUS,
       KTUXECFL Flags 6
  FROM x$ktuxe
 WHERE ktuxesta != 'INACTIVE' 8
       AND ktuxeusn IN (56, 19, 12)
 ORDER BY 1;


权限：CREATE DATABASE LINK或CREATE PUBLIC DATABASE LINK。

CREATE  DATABASE LINK dluis  CONNECT TO scott IDENTIFIED BY oracle USING 'luis'; 


#####################关闭正在运行的job
select sid,job  from dba_jobs_running;

查找到正在运行的JOB的spid:
    select a.spid
      from gv$process a, gv$session b
     where a.addr = b.paddr
           and a.INST_ID = b.INST_ID
           and b.sid in (select sid from dba_jobs_running);
Broken你确认的JOB   
    注意使用DBMS_JOB包来标识你的JOB为BROKEN。
    SQL> EXEC DBMS_JOB.BROKEN('262',TRUE);
   注意：当执行完该命令你选择的这个JOB还是在运行着的。



COL WHAT FOR A50
COL INTERVAL FOR A30
SET LINES 1000
SELECT SCHEMA_USER,PRIV_USER,JOB,BROKEN,INTERVAL ,to_char(T.NEXT_DATE,'yyyy-mm-dd hh24:mi:ss') NEXT_DATE,WHAT  FROM DBA_JOBS T  where SCHEMA_USER='HK_139SITE_TSSITE';

---------关闭和开启某个job
set  linesize 1000 pagesize 500
col WHAT for a70
col PRIV_USER for a20
col BROKEN for a5
col LOG_USER for a20
SELECT a.JOB,
       a.LOG_USER,
       a.PRIV_USER,
       to_char(LAST_DATE, 'yyyy-mm-dd') || ' ' || LAST_SEC LAST_DATE,
       to_char(a.NEXT_DATE, 'yyyy-mm-dd') || ' ' || a.NEXT_SEC NEXT_DATE,
       a.FAILURES,
       a.BROKEN,
       WHAT
  FROM dba_jobs a
 where PRIV_USER in ('XJMON')
 order by job;

 
-----删除

 
BEGIN
  dbms_ijob.remove(JOB=>164);
  COMMIT;
END;
/
 
----关闭
BEGIN
  sys.dbms_ijob.broken(959, TRUE);
  COMMIT;
END;
/
----开启
BEGIN
  sys.dbms_job.broken(job => 336, broken => FALSE);
  COMMIT;
END;

------SCHEDULER job
------创建job
BEGIN
  DBMS_SCHEDULER.CREATE_JOB(job_name        => 'INSERT_TEST_TBL',
                            job_type        => 'STORED_PROCEDURE',
                            job_action      => ' P_ INSERT INTOTEST ',
                            start_date      => sysdate,
                            repeat_interval => 'FREQ=DAILY;INTERVAL=1');
END;
/


repeat_interval => 'FREQ=MINUTELY;INTERVAL=10');

JOB_NAME ：指定任务的名称，必选值，注意要确保指定的名称唯一。
JOB_TYPE ：任务执行的操作类型，必选值，有下列几个可选值：
PLSQL_BLOCK ：表示任务执行的是一个PL/SQL匿名块。
STORED_PROCEDURE ：表示任务执行的是ORACLE过程(含PL/SQL PROCEDURE和JAVA PROCEDURE)，本例中正是指定这一参数值。
EXECUTABLE ：表示任务执行的是一个外部程序，比如说操作系统命令。
CHAIN ：表示任务执行的是一个CHAIN。
JOB_ACTION ：任务执行的操作，必选值，应与JOB_TYPE类型中指定的参数相匹配。
比如说对于PL/SQL匿名块，此处就可以放置PL/SQL块的具体代表，类似DECLARE .. BEGIN ..END这类；如果是ORACLE过程，那么此处应该指定具体的过程名，注意由于任务执行，即使过程中有OUT之类参数，实际执行时也不会有输出的。
START_DATE ：指定任务初次执行的时间，本参数可为空，当为空时，表示任务立刻执行，效果等同于指定该参数值为SYSDATE。
REPEAT_INTERVAL ：指定任务执行的频率，比如多长时间会被触发再次执行。本参数也可以为空，如果为空的话，就表示当前设定的任务只执行一次。REPEAT_INTERVAL参数需要好好说说，因为这一参数与标准JOB中的INTERVAL参数有很大区别，相比之下，REPEAT_INTERVAL参数的语法结构要复杂的多。其中最重要的是FREQ和INTERVAL两个关键字。
FREQ 关键字用来指定间隔的时间周期，可选参数有：YEARLY, MONTHLY, WEEKLY, DAILY, HOURLY, MINUTELY, and SECONDLY，分别表示年、月、周、日、时、分、秒等单位。
INTERVAL 关键字用来指定间隔的频繁，可指定的值的范围从1-99。
例如：REPEAT_INTERVAL=>'FREQ=DAILY;INTERVAL=1';表示每天执行一次，如果将INTERVAL改为7就表示每7天执行一次，效果等同于FREQ=WEEKLY;INTERVAL=1。
一般来说，使用DBMS_SCHEDULER.CREATE_JOB创建一个JOB，至少需要指定上述参数中的前3项。除此之外，还可以在CREATE_JOB时，指定下列参数：
NUMBER_OF_ARGUMENTS ：指定该JOB执行时需要附带的参数的数量，默认值为0，注意当JOB_TYPE列值为PLSQL_BLOCK或CHAIN时，本参数必须设置为0，因为上述两种情况下不支持附带参数。
END_DATE ：指定任务的过期时间，默认值为NULL。任务过期后，任务的STATE将自动被修改为COMPLETED，ENABLED被置为FALSE。如果该参数设置为空的话，表示该任务永不过期，将一直按照REPEAT_INTERVAL参数设置的周期重复执行，直到达到设置的MAX_RUNS或MAX_FAILURES值。
JOB_CLASS ：指定任务关联的CLASS，默认值为DEFAULT_JOB_CLASS。关于JOB CLASS的信息就关注本系列的后续文章。
ENABLED ：指定任务是否启用，默认值为FALSE。FALSE状态表示该任务并不会被执行，除非被用户手动调用，或者用户将该任务的状态修改为TRUE。
AUTO_DROP ：当该标志被置为TRUE时，ORACLE会在满足条件时自动删除创建的任务
任务已过期；
任务最大运行次数已达MAX_RUNS的设置值；
任务未指定REPEAT_INTERVAL参数，仅运行一次；
该参数的默认值即为TRUE。用户在执行CREATE_JOB过程时可以手动将该标志指定为FALSE，当参数值设置为FALSE时，即使满足上述提到的条件任务也不会被自动删除，这种情况下，唯一能够导致任务被删除的情况，就是用户主动调用DROP_JOB过程。
COMMENTS ：设置任务的注释信息，默认值为NULL。



 
select job_name,
       job_type,
       job_action,
       start_date,
       repeat_interval,
       end_date,
       enabled,
       auto_drop,
       state,
       run_count,
       max_runs
  from dba_scheduler_jobs
 where OWNER in ('XJMON');


set linesize 1000 pagesize 500
col OWNER for a15
col JOB_NAME for a35
col PROGRAM_OWNER for a10
col PROGRAM_NAME for a10
col JOB_ACTION for a70
select OWNER || '.' || JOB_NAME JOB_NAME,
       JOB_TYPE,
       ENABLED,
       --to_char(START_DATE, 'yyyy-mm-dd hh24:mi:ss') START_DATE,
       to_char(NEXT_RUN_DATE,'yyyy-mm-dd hh24:mi:ss') NEXT_RUN_DATE,
       to_char(LAST_START_DATE,'yyyy-mm-dd hh24:mi:ss') LAST_START_DATE,
       JOB_ACTION
  from DBA_SCHEDULER_JOBS
 where OWNER  in ('ZC_FM','ZC_NHM','ZC_RM');

exec dbms_scheduler.enable('j_test');  --启用jobs    
exec dbms_scheduler.disable('ZC_NHM.JB_ENTERPRISE_LINE_REPORT');  --禁用jobs    
exec dbms_scheduler.run_job('j_test');  --执行jobs    
exec dbms_scheduler.stop_job('j_test');  --停止jobs    
exec dbms_scheduler.drop_job('j_test');  --删除jobs  

-------修改job

BEGIN
  dbms_scheduler.set_attribute(NAME      => 'job_name',
                               ATTRIBUTE => 'change_option',
                               VALUE     => 'change_value');
END;
/
SET_ATTRIBUTE 过程虽然仅有三个参数，不过能够修改的属性值可是不少，以下列举几个较常用到的：
LOGGING_LEVEL ：指定对jobs执行情况记录的日志信息级别。
SCHEDULER 管理的JOB对任务的执行情况专门进行了记录，同时用户还可以选择日志中记录信息的级别，有下列三种选择：
DBMS_SCHEDULER.LOGGING_OFF ：关闭日志记录功能；
DBMS_SCHEDULER.LOGGING_RUNS ：对任务的运行信息进行记录；
DBMS_SCHEDULER.LOGGING_FULL ：记录任务所有相关信息，不仅有任务的运行情况，甚至连任务的创建、修改等也均将记入日志。
提示：查看SCHEDULER管理的JOB，可以通过USER_SCHEDULER_JOB_LOG和USER_SCHEDULER_JOB_RUN_DETAILS两个视图中查询
RESTARTABLE ：指定jobs运行出错后，是否能够适时重启。创建任务时如未明确指定，本参数默认情况下设置为FALSE，如果设置为TRUE，就表示当任务运行时出错，下次运行时间点到达时仍会启动，并且如果运行仍然出错，会继续重新运行，不过如果连接出错达到6次，该job就会停止。
MAX_FAILURES ：指定jobs最大连续出错次数。该参数值可指定的范围从1-1000000，默认情况下该参数设置为NULL，表示无限制。达到指定出错次数后，该job会被自动disable。
MAX_RUNS ：指定jobs最大运行次数。该参数值可指定的范围从1-1000000，默认情况下该参数设置为NULL，表示无限制(只是运行次数无限制，实际job会否继续运行，仍受制于end_date以及max_failures等参数的设置)。达到指定运行次数后，该job也将被自动disable，并且状态会被置为COMPLETED。
JOB_TYPE ：指定job执行的任务的类型。有四个可选值：¨PLSQL_BLOCK¨, ¨STORED_PROCEDURE¨, ¨EXECUTABLE¨, and ¨CHAIN¨。
JOB_ACTION ：指定job执行的任务。这一参数所指定的值依赖于JOB_TYPE参数中的值，比如说JOB_TYPE设置为¨STORED_PROCEDURE¨，那么本参数值中指定的一定是ORACLE中的过程名。
START_DATE ：指定job初次启动的时间
END_DATE ：指定job停止运行的时间。本参数又与AUTO_DROP相关联，如果AUTO_DROP设置为TRUE的话，那么一旦job到达停止运行的时间，该job就会被自动删除，否则的话job一直存在，不过状态被修改为COMPLETED。



