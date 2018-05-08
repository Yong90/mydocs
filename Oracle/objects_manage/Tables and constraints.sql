--#######建表语法
CREATE [global temporary] TABLE  [schema.]table_name
(column  datatype [, column  datatype] … )
[TABLESPACE  tablespace]
 [PCTFREE  integer]
 [PCTUSED  integer]
 [INITRANS  integer]
 [MAXTRANS  integer]
 [STORAGE  storage-clause]
 [LOGGING | NOLOGGING]
 [CACHE | NOCACHE] ];

范例：
CREATE TABLE test
(id          NUMBER(5)     CONSTRAINT test_id_pk PRIMARYKEY,
Salerno   number generated as identity,   -------定义自动增长（标示）列
last_name   VARCHAR2(10)  CONSTRAINT test_last_name_nn NOT NULL,
first_name  VARCHAR2(10)  NOT NULL UNIQUE,
userid       VARCHAR2(8)  CONSTRAINT test_userid_uk UNIQUE,
start_date   DATE         DEFAULT    SYSDATE,
title       VARCHAR2(10),
dept_id     NUMBER(7)      CONSTRAINT test_dept_id_fk REFERENCES dept(id),
Salary      NUMBER(11,2),
user_type   VARCHAR2(4)   CONSTRAINT test_user_type_ck CHECK(user_type IN('IN','OUT')),
CONSTRAINT test_uk_title UNIQUE (title,salary)

 )
INITRANS 1 MAXTRANS 255
PCTFREE  20  PCTUSED  50
STORAGE( INITIAL  1024K  NEXT  1024K  PCTINCREASE  0  MINEXTENTS  1  MAXEXTENTS  5)
TABLESPACE  users

-------创建索引组织表
create table prod_sku
(prod_sku_id number,
sku varchar2(256),
create_dtt timestamp(5),
constraint prod_sku_pk primary key(prod_sku_id)
)
organization index
including sku
pctthreshold 30
tablespace inv_data
overflow
tablespace inv_data;



-----启用DDL日志功能
enable_ddl_logging=true
select value from v$diag_info where name='Diag Alert';




表压缩：
-----基本压缩
不同表空间：alter   table table_name move  tablespace tablespace_name compress;
相同表空间：alter  table table_name move  compress basic;
-----高级行压缩（OLTP压缩）   ---额外的压缩组件，需要许可
row  store compress advanced
-----仓库和归档混合列压缩
column store compress for query low|high 
or
column store compress for archive  low|high 



-----表状态查询
SELECT * FROM Dba_Tab_Partitions WHERE Table_Name = ’%表名%’;

SELECT owner, index_name, status, degree, table_name
  FROM dba_indexes
 WHERE table_name = ’table_name’;
 
 
SELECT owner, segment_name, segment_type, sum(bytes) / 1024 / 1024
  FROM dba_segments
 WHERE segment_name = 'FACT_BRAS_CDR'
 group by owner, segment_name, segment_type;

---计算一个表占用的空间的大小
SELECT owner,segment_name,
       bytes / 1024 / 1024,
       segment_name,
       segment_type,
       tablespace_name
  FROM dba_segments
 WHERE owner like 'ITLOCS_LOCS%';






###重命名
表:alter table  rename dept to dt;  
列:alter table dept rename column loc to loca;  

###添加/删除列
alter table employee_info add id varchar2(18);  
alter table employee_info add hiredate date default sysdate not null;  
alter table employee_info drop column introduce;

###修改列  
修改列的长度  
      alter table dept modify loc varchar2(50);  
 修改列的精度  
      alter table employee_info modify empno number(2);  
 修改列的数据类型  
      alter table employee_info modify sex char(2);  
 修改默认值  
      alter table employee_info modify hiredate default sysdate+1;

###添加约束  
##primary key： 
      alter table employee_info add constraint pk_emp_info primary key(empno);  
##foreign key：  
alter table employee_info add constraint fk_emp_info foreign key(deptno) references dept(deptno);  
##check：  
      alter table employee_info add constraint ck_emp_info check (sex in ('F','M'));  
##not null：  
      alter table employee_info modify phone constraint not_null_emp_info not null;  
##unique：  
      alter table employee_info add constraint uq_emp_info unique(phone);  
##default：  
      alter table employee_info modify sex char(2) default 'M';

###启用/禁用约束
  alter table employee_info enable constraint uq_emp_info;
  alter table employee_info disable constraint uq_emp_info;

####添加注释
  comment on table employee_info is 'information of employees';  
  comment on column employee_info.ename is 'the name of employees';  
  comment on column dept.dname is 'the name of department';  




---------获得表的DDL语句
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.GET_DDL('TABLE','T_TLBR_USER_WEEK_PART_201528','TLBR') FROM DUAL;

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON




-------统计表行数
UNDEFINE user
SET SERVEROUT ON SIZE 1000000 VERIFY OFF
SPO part_count_&&user..txt
DECLARE
  counter  NUMBER;
  sql_stmt VARCHAR2(1000);
  CURSOR c1 IS
  SELECT table_name, partition_name
  FROM dba_tab_partitions
  WHERE table_owner = UPPER('&&user');
BEGIN
  FOR r1 IN c1 LOOP
    sql_stmt := 'SELECT COUNT(*) FROM &&user..' || r1.table_name
      ||' PARTITION ( '||r1.partition_name ||' )';
    EXECUTE IMMEDIATE sql_stmt INTO counter;
    DBMS_OUTPUT.PUT_LINE(RPAD(r1.table_name
      ||'('||r1.partition_name||')',30) ||' '||TO_CHAR(counter));
  END LOOP;
END;
/
SPO OFF



SPO tabcount.sql
SET LINESIZE 132 PAGESIZE 0 TRIMSPO OFF VERIFY OFF FEED OFF TERM OFF
SELECT
  'SELECT RPAD(' || '''' || table_name || '''' ||',30)'
  || ',' || ' COUNT(*) FROM ' || table_name || ';'
FROM user_tables
ORDER BY 1;
SPO OFF;
SET TERM ON
@@tabcount.sql
SET VERIFY ON FEED ON








--------------------------------------表碎片整理
Kindly please run 3 scripts which oracle provided following the instruction in document to detect the table fragmentation for your 2 tables.
Script to Report Table Fragmentation (Doc ID 1019716.6)
For more information regarding to fragmentation please refere following documents:
Various Aspects of Fragmentation (Doc ID 186826.1)
Script to Report Tablespace Free and Fragmentation (Doc ID 1019709.6)
Script to Detect Tablespace Fragmentation (Doc ID 1020182.6)
Script: To Report Information on Indexes (Doc ID 1019722.6) ( Script 1: Index Fragmentation ) 



SELECT t.table_name,
       avg_row_len * num_rows / (1 - pct_free / 100) / 16384 actual_block,
       alloc_block,
       1 - ((avg_row_len * num_rows / (1 - pct_free / 100) / 16384) /
       alloc_block) percen,
       'alter table ' || t.table_name || ' enable row movement' || ';' enable_row,
       'alter table ' || t.table_name || ' shrink space' || ';' ddl_shrink
  FROM (SELECT segment_name, SUM(blocks) alloc_block
          FROM dba_extents
        HAVING SUM(blocks) > 8
         GROUP BY segment_name) a,
       dba_tables t
 WHERE a.segment_name = t.table_name
   AND num_rows IS NOT NULL
   AND num_rows > 0
 ORDER BY 4 DESC;

SELECT owner,
       table_name,
       tablespace_name,
       round(blocks * 16384 / 1024 / 1024, 2) table_size_m,
       round((avg_row_len * num_rows +
             (24 * ini_trans + 100 + 16384 * pct_free / 100) * blocks) /
             16384 / blocks * 100, 2) pct
  FROM dba_tables
 WHERE (avg_row_len * num_rows +
       (24 * ini_trans + 100 + 16384 * pct_free / 100) * blocks) / 16384 /
       blocks < 0.7
   AND blocks > 0
   AND last_analyzed > SYSDATE - 30
   AND table_name = 'TB_CM_MAIN_BILL_HIST'
 ORDER BY 4, owner, 5;


show_space()

SELECT owner, segment_name, segment_type, bytes / 1024 / 1024
  FROM dba_segments
 WHERE segment_name LIKE 'HISTGRM$';

alter table OW_PAY_SZ.TB_SM_STAFFPOST_HIST enable row movement;
alter table OW_PAY_SZ.TB_SM_STAFFPOST_HIST shrink space;
alter table OW_PAY_SZ.TB_SM_STAFFPOST_HIST disable row movement;








--更新统计信息
Analyze table <table_name> compute statistics ;
--计算碎片空间
SELECT TABLE_NAME,
       (BLOCKS * 8192 / 1024 / 1024) -
       (NUM_ROWS * AVG_ROW_LEN / 1024 / 1024) "Data lower than HWM in MB"
  FROM DBA_TABLES
 WHERE UPPER(owner) = UPPER('&OWNER')
 ORDER BY 2 DESC;

ANALYZE TABLE big_emp1 ESTIMATE STATISTICS;
SELECT table_name, num_rows, blocks, empty_blocks
  FROM user_tables
 WHERE table_name = 'BIG_EMP1';
SELECT COUNT(DISTINCT DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID) ||
             DBMS_ROWID.ROWID_RELATIVE_FNO(ROWID)) "Used"
  FROM big_emp1;

SELECT segment_name, segment_type, blocks
  FROM dba_segments
 WHERE segment_name = 'BIG_EMP1';

--对于索引校验结构
analyze index <index name> validate structure;
--检查
column name format a15
column blocks heading "ALLOCATED|BLOCKS"
column lf_blks heading "LEAF|BLOCKS"
column br_blks heading "BRANCH|BLOCKS"
column Empty heading "UNUSED|BLOCKS"
SELECT NAME, blocks, lf_blks, br_blks, blocks - (lf_blks + br_blks) empty
  FROM index_stats;
或者
select name, btree_space, used_space, pct_used from index_stats;
 
--回收空间方法
'Compatible' 必须 >=10.0
1. Enable row movement for the table.
SQL>  ALTER TABLE scott.emp ENABLE ROW MOVEMENT;
2. Shrink table but don t want to shrink HWM (High Water Mark).
SQL>  ALTER TABLE scott.emp SHRINK SPACE COMPACT;
3. Shrink table and HWM too.
SQL>  ALTER TABLE scott.emp SHRINK SPACE;
4. Shrink table and all dependent index too.
SQL>  ALTER TABLE scott.emp SHRINK SPACE CASCADE;
5. Shrink table under MView.
SQL>  ALTER TABLE <table name> SHRINK SPACE;
6. Shrink Index only.
SQL>  ALTER INDEX <index nam> SHRINK SPACE;
验证
SQL> set serveroutput on
SQL> declare
             v_unformatted_blocks number;
             v_unformatted_bytes number;
             v_fs1_blocks number;
             v_fs1_bytes number;
             v_fs2_blocks number;
             v_fs2_bytes number;
             v_fs3_blocks number;
             v_fs3_bytes number;
            v_fs4_blocks number;
            v_fs4_bytes number;
            v_full_blocks number;
            v_full_bytes number;
        begin
          dbms_space.space_usage ('SYSTEM', 'T_SHRINK', 'TABLE', v_unformatted_blocks,
          v_unformatted_bytes, v_fs1_blocks, v_fs1_bytes, v_fs2_blocks, v_fs2_bytes,
          v_fs3_blocks, v_fs3_bytes, v_fs4_blocks, v_fs4_bytes, v_full_blocks, v_full_bytes);
          dbms_output.put_line('Unformatted Blocks = '||v_unformatted_blocks);
          dbms_output.put_line('FS1 Blocks       = '||v_fs1_blocks);
          dbms_output.put_line('FS2 Blocks       = '||v_fs2_blocks);
          dbms_output.put_line('FS3 Blocks       = '||v_fs3_blocks);
          dbms_output.put_line('FS4 Blocks       = '||v_fs4_blocks);
          dbms_output.put_line('Full Blocks       = '||v_full_blocks);
   end;
   /
Unformatted Blocks = 0
FS1 Blocks       = 0
FS2 Blocks       = 0
FS3 Blocks       = 0
FS4 Blocks       = 2
Full Blocks       = 1




set serverout on size 1000000
declare
   p_fs1_bytes number;
   p_fs2_bytes number;
   p_fs3_bytes number;
   p_fs4_bytes number;
   p_fs1_blocks number;
   p_fs2_blocks number;
   p_fs3_blocks number;
   p_fs4_blocks number;
   p_full_bytes number;
   p_full_blocks number;
   p_unformatted_bytes number;
   p_unformatted_blocks number;
begin
   dbms_space.space_usage(
      segment_owner      => user,
      segment_name       => 'INV',
      segment_type       => 'TABLE',
      fs1_bytes          => p_fs1_bytes,
      fs1_blocks         => p_fs1_blocks,
      fs2_bytes          => p_fs2_bytes,
      fs2_blocks         => p_fs2_blocks,
      fs3_bytes          => p_fs3_bytes,
      fs3_blocks         => p_fs3_blocks,
      fs4_bytes          => p_fs4_bytes,
      fs4_blocks         => p_fs4_blocks,
      full_bytes         => p_full_bytes,
      full_blocks        => p_full_blocks,
      unformatted_blocks => p_unformatted_blocks,
      unformatted_bytes  => p_unformatted_bytes
   );
   dbms_output.put_line('FS1: blocks = '||p_fs1_blocks);
   dbms_output.put_line('FS2: blocks = '||p_fs2_blocks);
   dbms_output.put_line('FS3: blocks = '||p_fs3_blocks);
   dbms_output.put_line('FS4: blocks = '||p_fs4_blocks);
   dbms_output.put_line('Full blocks = '||p_full_blocks);
end;
/





-------查询表的碎片
col owner for a10
col table_name for a30

SELECT OWNER,
       SEGMENT_NAME TABLE_NAME,
       SEGMENT_TYPE,
       GREATEST(ROUND(100 * (NVL(HWM - AVG_USED_BLOCKS, 0) /
                      GREATEST(NVL(HWM, 1), 1)), 2), 0) WASTE_PER
  FROM (SELECT A.OWNER OWNER,
               A.SEGMENT_NAME,
               A.SEGMENT_TYPE,
               B.LAST_ANALYZED,
               A.BYTES,
               B.NUM_ROWS,
               A.BLOCKS BLOCKS,
               B.EMPTY_BLOCKS EMPTY_BLOCKS,
               A.BLOCKS - B.EMPTY_BLOCKS - 1 HWM,
               DECODE(ROUND((B.AVG_ROW_LEN * NUM_ROWS *
                            (1 + (PCT_FREE / 100))) / C.BLOCKSIZE, 0), 0, 1,
                      ROUND((B.AVG_ROW_LEN * NUM_ROWS *
                             (1 + (PCT_FREE / 100))) / C.BLOCKSIZE, 0)) + 2 AVG_USED_BLOCKS,
               ROUND(100 *
                     (NVL(B.CHAIN_CNT, 0) / GREATEST(NVL(B.NUM_ROWS, 1), 1)),
                     2) CHAIN_PER,
               B.TABLESPACE_NAME O_TABLESPACE_NAME
          FROM SYS.DBA_SEGMENTS A, SYS.DBA_TABLES B, SYS.TS$ C
         WHERE A.OWNER = B.OWNER
           AND SEGMENT_NAME = TABLE_NAME
           AND SEGMENT_TYPE = 'TABLE'
           AND B.TABLESPACE_NAME = C.NAME)
 WHERE GREATEST(ROUND(100 * (NVL(HWM - AVG_USED_BLOCKS, 0) /
                      GREATEST(NVL(HWM, 1), 1)), 2), 0) > 50
   AND OWNER LIKE 'ZCW'
   AND BLOCKS > 100
 ORDER BY WASTE_PER DESC;



















----------------大约束：
--1）not null：非空约束
--2）primary key：主键约束
--3）unique：唯一性约束
--4）foreign key：外键约束
--on delete cascade:级联删除。意味着当删除父表中的行时，子表中所有依赖于该父行的子行同时删除。
--on delete set null:删除父表中的行时，子表中所有依赖于该父行的子行的外键列被设为null值
--5）check：检查约束


范例：
create   table   text(
id   number,
salary   number,
deptid   number,
name   varchar2(20)     notnull,---------非空
email    varchar2(30)    constraint   test_uk_email_uk   unique,------唯一
    constraint    test_pk_id_pk    primarykey(id),-------主键
constraint    test_fk_pk     foreignkey(deptid)
references    dept(department_id)  [on   delete   cascade]/[on  delete   set   null] ,-------外键
constraint    test_ck_sal_ck    check(salary>0)---------检查

)
tablespace    SYSTEM-----指定表空间
pctfree  10
pctused  40
initrans 1
maxtrans  255
storage
(
initial   64
next  1
minextents  1
max  extent   sun  limited
);

-给emp2添加主键约束
alter table emp add constraint emp_empid_pk primarykey(employee_id);

--给emp2添加外键约束
alter table emp add constraint emp_mgr_fk foreignkey(manager_id) references    emp2(employee_id);

---延迟约束
--示例：
create table new_emp_sal
(
salary number constraint sal_ck check(salary>100) deferrable  initially immediate,
bonus number constraint bonus_ck check(bonus>0) deferrable initially  deferred
);

--禁用emp2表的外键约束
--注意：当禁用主键约束时，会导致主键索引也被自动删除
alter table emp disable constraint emp_mgr_fk;
---------查询主键被引用的外键
col primary_key_table form a18
col primary_key_constraint form a18
col fk_child_table form a18
col fk_child_table_constraint form a18
--
SELECT b.table_name      primary_key_table,
       b.constraint_name primary_key_constraint,
       a.table_name      fk_child_table,
       a.constraint_name fk_child_table_constraint
  FROM dba_constraints a, dba_constraints b
 WHERE a.r_constraint_name = b.constraint_name
   AND a.r_owner = b.owner
   AND a.constraint_type = 'R'
   AND b.owner = upper('&table_owner')
   AND b.table_name = upper('&pk_table_name');

----禁用某用户所有外键约束
set lines 132 trimsp on head off feed off verify off echo off pagesize 0
spo dis_dyn.sql
SELECT 'alter table ' || a.table_name || ' disable constraint ' ||
       a.constraint_name || ';'
  FROM dba_constraints a, dba_constraints b
 WHERE a.r_constraint_name = b.constraint_name
   AND a.r_owner = b.owner
   AND a.constraint_type = 'R'
   AND b.owner = upper('&table_owner');
spo off;




--启用约束
--注意：当起用主键约束时，会导致主键索引也被自动创建
alter table emp enable constraint emp_empid_pk;
--------重启某个表的所有外键约束
set lines 132 trimsp on head off feed off verify off echo off pagesize 0
spo enable_dyn.sql
SELECT 'alter table ' || a.table_name || ' enable constraint ' ||
       a.constraint_name || ';'
  FROM dba_constraints a, dba_constraints b
 WHERE a.r_constraint_name = b.constraint_name
   AND a.r_owner = b.owner
   AND a.constraint_type = 'R'
   AND b.owner = upper('&table_owner');
spo off;






---删除约束
--SQL 错误: ORA-02273: 此唯一/主键已被某些外键引用
alter table emp drop constraint emp2_empid_pk;

---使用alter table语句修改列名或者约束名
alter table emp rename column job_id to jobid;

alter table emp enable/disable  novalidate/validate constraint FK_DEPTNO
enable/disable:校验的是新数据的正确性
novalidate/validate：校验的是表中的现有数据

disable/enable validate/novalidate 的区别

启用约束:
enable( validate) :启用约束,创建索引,对已有及新加入的数据执行约束.
enable novalidate :启用约束,创建索引,仅对新加入的数据强制执行约束,而不管表中的现有数据. 
禁用约束:
disable( novalidate):关闭约束,删除索引,可以对约束列的数据进行修改等操作.
disable validate :关闭约束,删除索引,不能对表进行 插入/更新/删除等操作.


环境:oracle 9i 9.0.1.0 for win,以上结论均测试通过.
例:disable validate约束后,执行update...操作提示:
ORA-25128: 不能对带有禁用和验证约束条件 (SYS.PK_EMP_01) 的表进行插入/更新/删除


启用键的时候报异常存在重复数据可以使用exception表，建表语句如下：
sql>@?/rdbms/admin/utlexptl.sql



------disable_chk
SELECT 'ALTER TABLE "' || a.table_name || '" DISABLE CONSTRAINT "' ||
       a.constraint_name || '";'
  FROM all_constraints a
 WHERE a.constraint_type = 'C'
   AND a.owner = UPPER('&2');
AND a.table_name = DECODE(UPPER('&1'), 'ALL', a.table_name, UPPER('&1'));
-------disable_ref_fk
SELECT 'ALTER TABLE "' || a.table_name || '" DISABLE CONSTRAINT "' ||
       a.constraint_name || '";' enable_constraints
  FROM all_constraints a
 WHERE a.owner = Upper('&2')
   AND a.constraint_type = 'R'
   AND a.r_constraint_name IN
       (SELECT a1.constraint_name
          FROM all_constraints a1
         WHERE a1.table_name =
               DECODE(Upper('&1'), 'ALL', a.table_name, Upper('&1'))
           AND a1.owner = Upper('&2'));
----disable_pk
SELECT 'ALTER TABLE "' || a.table_name || '" DISABLE PRIMARY KEY;'
  FROM all_constraints a
 WHERE a.constraint_type = 'P'
   AND a.owner = Upper('&2')
   AND a.table_name = DECODE(Upper('&1'), 'ALL', a.table_name, Upper('&1'));
---disable_fk
SELECT 'ALTER TABLE "' || a.table_name || '" DISABLE CONSTRAINT "' ||
       a.constraint_name || '";'
  FROM all_constraints a
 WHERE a.constraint_type = 'R'
   AND a.table_name = DECODE(Upper('&1'), 'ALL', a.table_name, Upper('&1'))
   AND a.owner = Upper('&2');
--enable
SELECT 'ALTER TABLE "' || a.table_name || '" ENABLE PRIMARY KEY;'
  FROM all_constraints a
 WHERE a.constraint_type = 'P'
   AND a.owner = Upper('&2')
   AND a.table_name = DECODE(Upper('&1'), 'ALL', a.table_name, Upper('&1'));
---------
SELECT 'ALTER TABLE "' || a.table_name || '" ENABLE CONSTRAINT "' ||
       a.constraint_name || '";'
  FROM all_constraints a
 WHERE a.owner = Upper('&2')
   AND a.constraint_type = 'R'
   AND a.r_constraint_name IN
       (SELECT a1.constraint_name
          FROM all_constraints a1
         WHERE a1.table_name =
               DECODE(Upper('&1'), 'ALL', a.table_name, Upper('&1'))
           AND a1.owner = Upper('&2'));
-------------
SELECT 'ALTER TABLE "' || a.table_name || '" ENABLE CONSTRAINT "' ||
       a.constraint_name || '";'
  FROM all_constraints a
 WHERE a.constraint_type = 'C'
   AND a.owner = Upper('&2');
AND a.table_name = DECODE(Upper('&1'), 'ALL', a.table_name, UPPER('&1'));
-------------------
SELECT 'ALTER TABLE "' || a.table_name || '" ENABLE CONSTRAINT "' ||
       a.constraint_name || '";'
  FROM all_constraints a
 WHERE a.constraint_type = 'R'
   AND a.table_name = DECODE(Upper('&1'), 'ALL', a.table_name, Upper('&1'))
   AND a.owner = Upper('&2');
                               
                               

