----------------查询表分区的相关信息
select t.table_name, kc.column_name, t.partitioning_type
  from dba_part_key_columns kc, dba_part_tables t
 where kc.owner = t.owner
   and kc.name = t.table_name
   and t.table_name = '&TABNAME'
   and t.owner = '&OWNAME'
union all
select u.table_name, skc.column_name, u.subpartitioning_type
  from dba_subpart_key_columns skc, dba_part_tables u
 where skc.owner = u.owner
   and skc.name = u.table_name
   and u.subpartitioning_type != 'NONE'
   and u.table_name = '&TABNAME'
   and u.owner = '&OWNAME';


select owner,index_name,table_name,status from dba_indexes where table_name ='TFA_ALARM_CLR'
union all
select owner,index_name,table_name,locality from dba_part_indexes where table_name ='TFA_ALARM_CLR' ;

select owner,index_name,table_name,status,PARTITIONED from dba_indexes where table_name ='TFA_ALARM_CLR'
select owner,index_name,table_name,status,PARTITIONED from dba_indexes where table_name ='IX2_TFA_ALARM_CLR_T1'
select OWNER,INDEX_NAME,TABLE_NAME,locality,ALIGNMENT from dba_part_indexes where index_name like 'IX2_TFA_ALARM_CLR%';


分区索引
1、分区表的索引
分区索引分为本地(local index)索引和全局索引(global index)。局部索引比全 局索引容易管理,  而全局索引比较快。
与索引有关的表:
dba_part_indexes  分区索引的概要统计信息，可以得知每个表上有哪些分区索引，分区索引的类型(local/global)
dba_ind_partitions   每个分区索引的分区级统计信息
dba_indexes/dba_part_indexes  可以得到每个表上有哪些非分区索引

Local 索引肯定是分区索引，Global 索引可以选择是否分区，如果分区，只能是有前缀的分区索引。
分区索引分2类:有前缀(prefix)的分区索引和无前缀(nonprefix)的分区索引: 

(1)有前缀的分区索引指包含了分区键，并且将其作为引导列的索引。 如:
create index i_id_global on PDBA(id) global   --引导列
   partition by range(id)    --分区键
    (partition p1 values less than (200),
     partition p2 values less than (maxvalue) 5   
     );
这里的 ID 就是分区键，并且分区键 id 也是索引的引导列。


(2)无前缀的分区索引的列不是以分区键开头，或者不包含分区键列。 如:
create index ix_custaddr_local_id_p on custaddr(id) 
local 
(
partition t_list556 tablespace icd_service, 
partition p_other tablespace icd_service
)
这个分区是按照 areacode 来的。但是索引的引导列是 ID。 所以它就是非前 缀分区索引。
全局分区索引不支持非前缀的分区索引，如果创建，报错如下:



2、Local 本地索引
对于 local 索引，当表的分区发生变化时，索引的维护由 Oracle 自动进行。

注意事项:
(1)  局部索引一定是分区索引，分区键等同于表的分区键。
(2)     前缀和非前缀索引都可以支持索引分区消除，前提是查询的条件中包含索引分区键。
(3)     局部索引只支持分区内的唯一性，无法支持表上的唯一性，因此如果要用局部索引去给表做唯一性约束，则约束中必须要包括分区键列。
(4)  局部分区索引是对单个分区的，每个分区索引只指向一个表分区:全局索引则不然，一个分区索引能指向 n 个表分区，同时，一个表分区，也可能指向 n个索引分区，对分区表中的某个分区做 truncate 或者 move，shrink 等，可能会影响到 n 个全局索引分区，正因为这点，局部分区索引具有更高的可用性。
(5) 位图索引必须是局部分区索引。
(6) 局部索引多应用于数据仓库环境中。
(7) B 树索引和位图索引都可以分区，但是 HASH 索引不可以被分区。
示例:
sql> create index ix_custaddr_local_id on custaddr(id) local;
索引己创建。

和下面 SQL  效果相同，因为 local 索引就是分区索引:
create index ix_custaddr_local_id_p on custaddr(id) 
local 
(
partition t_list556 tablespace icd_service, 
partition p_other tablespace icd_service
)
SQL> create index ix_custaddr_local_areacode on custaddr(areacode) local;
索引己创建。


3、Global 索引
对于 global 索引，可以选择是否分区，而且索引的分区可以不与表分区相对 应。全局分区索引只能是 B 树索引，到目前为止(10gR2)，oracle 只支持有前缀 的全局索引。
另外 oracle 不会自动的维护全局分区索引，当我们在对表的分区做修改之后， 如果对分区进行维护操作时不加上 update global indexes 的话，通常会导致全局 索引的 
INVALDED，必须在执行完操作后 REBUILD。

注意事项: 
(1)全局索引可以分区，也可以是不分区索引，全局索引必须是前缀索引，即 全局索引的索引列必须是以索引分区键作为其前几列。 
(2)全局索引可以依附于分区表:也可以依附于非分区表。 
(3)全局分区索引的索引条目可能指向若干个分区，因此，对于全局分区索引，即使只截断一个分区中的数据，都需要 rebulid 若干个分区甚至是整个索引。 
(4)全局索引多应用于 oltp  系统中。 
(5)全局分区索引只按范围或者散列分区，hash 分区是 10g 以后才支持。
(6) oracle9i 以后对分区表做 move 或者 truncate 的时可以用 update globalindexes 吾句来同步更新全局分区索引，用消耗一定资源来换取高度的可用性。
(7) 表用 a 列作分区，索引用 b 做局部分区索引，若 where 条件中用 b 来查询，那么 oracle 会扫描所有的表和索引的分区，成本会比分区更高，此时可以考虑用b 做全局分区索引。

注意:Oracle 只支持 2 中类型的全局分区索引:
range partitioned  和 Hash Partitioned.

示例 1    全局索引，全局索引对所有分区类型都支持:
sql> create index ix_custaddr_ global_id on custaddr(id) global;
索引己创建。

示例 2:全局分区索引
SQL> create index i_id_global on PDBA(id) global
   partition by range(id)
   (partition p1 values less than (200),
   partition p2 values less than (maxvalue) 5   );
索引己创建。


4、索引重建问题

1)分区索引
对于分区索引，不能整体进行重建，只能对单个分区进行重建。语法如下:
Alter index idx_name rebuild partition index_partition_name [online nologging]
说明:
online:表示重建的时候不会锁表。 
nologging:表示建立索引的时候不生成日志，加快速度。
如果要重建分区索引，只能  drop  表原索引，在重新创建:
SQL>create index loc_xxxx_col on xxxx(col) local tablespace SYSTEM;
这个操作要求较大的临时表空间和排序区。


2)全局索引
Oracle 会自动维护分区索引，对于全局索引，如果在对分区表操作时，没有指定 update index，则会导致全局索引失效，需要重建。


RANGE分区维护 
  CREATE TABLE dao_partitions  
   ( prod_id        NUMBER(6),  
     insert_time    date    
   )  
PARTITION BY RANGE (insert_time)  
 (PARTITION SALES_1998 VALUES LESS THAN (TO_DATE('01-JAN-1999','DD-MON-YYYY')),  
  PARTITION SALES_1999 VALUES LESS THAN (TO_DATE('01-JAN-2000','DD-MON-YYYY')),  
  PARTITION SALES_2000 VALUES LESS THAN (TO_DATE('01-JAN-2001','DD-MON-YYYY'))  
 ); 

SELECT DTP.TABLE_OWNER, DTP.TABLE_OWNER, DTP.PARTITION_NAME
  FROM dba_tab_partitions DTP
 WHERE table_owner = 'ZC_TNMSPON'
   AND TABLE_NAME = 'PON_ORDER_CUR_STATE';

SELECT COUNT(*), 'all'
  FROM dao_test_hash
UNION ALL
SELECT COUNT(*), 'p1'
  FROM dao_test_hash PARTITION(p1)
UNION ALL
SELECT COUNT(*), 'p2'
  FROM dao_test_hash PARTITION(p2);


 
  
1）RANGE无maxvalue分区下增加分区  
SQL> alter table  dao_range_partition add PARTITION SALES_2001  VALUES LESS THAN (TO_DATE('01-JAN-2002','DD-MON-YYYY'));  
  Table altered. 
  
2） 增加max分区  
SQL> ALTER TABLE  DAO_RANGE_PARTITION ADD PARTITION SALES_MAX  VALUES LESS THAN ( MAXVALUE );  
  Table altered.  

3）通过拆分maxvalue分区增加分区  
SQL> alter table DAO_RANGE_PARTITION  split   partition SALES_MAX  at  
    (TO_DATE(' 2003-01-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN'))  
    into (partition SALES_2002 tablespace users ,partition SALES_MAX tablespace users );  
  Table altered.  
  
alter table A_BATCH_TURNDAYS 
split subpartition P_200401_SP_OTHERS values (6230000) into (
  subpartition P_200401_SP_6230000,
  subpartition P_200401_SP_OTHERS 
)


4）通过drop maxvalue分区 加入分区  
SQL> alter table DAO_RANGE_PARTITION drop partition SALES_MAX ;
SQL> alter table  dao_range_partition add PARTITION SALES_2003  VALUES LESS THAN (TO_DATE('01-JAN-2004','DD-MON-YYYY'));  
  Table altered  

5）分区删除  
SQL> alter table DAO_RANGE_PARTITION drop partition SALES_MAX ;  
  Table altered. 

6） 分区truncate   
SQL> alter table DAO_RANGE_PARTITION truncate partition  SALES_2002 ;  
  Table truncated.  


7） 分区拆分  
SQL> alter table DAO_RANGE_PARTITION  split   partition SALES_MAX  at  
    (TO_DATE(' 2003-01-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN'))  
    into (partition SALES_2002 tablespace users ,partition SALES_MAX tablespace users );  
  Table altered.  


8） 分区合并 
SQL> ALTER TABLE DAO_RANGE_PARTITION MERGE PARTITIONS  SALES_1998,SALES_1999  INTO  PARTITION SALES_1999 ;  
  Table altered
  
9） 分区交换
alter table DAO_RANGE_PARTITION exchange partition SALES_1999  with table DAO_RANGE_PARTITION _tmp;

alter table DAO_RANGE_PARTITION exchange partition SALES_2000  with table DAO_RANGE_PARTITION _tmp;

两次交换后数据又回来了只是从SALES_1999变到了SALES_2000

10） 分区移动
SQL> alter table custaddr move partition P_OTHER tablespace system;


11)、修改子分区模板
------添加6230000
alter table A_CHECKBILL_DAY
set subpartition template (
  subpartition SP_6160000 values (6160000),
  subpartition SP_6180000 values (6180000),
  subpartition SP_6230000 values (6230000),
  subpartition SP_OTHERS values (default)
);









2、HASH分区维护
增加分区  
SQL> alter table dao_test_hash add partition p3 ;  
  Table altered


列表分区  
基本与范围分区相同，参见范围分区





11g提供Interval参数
1.创建按月分区的分区表

/* Formatted on 2010/6/10 20:21:12 (QP5 v5.115.810.9015) */
create table intervalpart (c1 number, c3 date) partition by range (c3)
interval ( numtoyminterval (1, 'month') ) 
(
partition part1 values less than (to_date ('01/12/2010', 'mm/dd/yyyy')), 
partition part2 values less than (to_date ('02/12/2010', 'mm/dd/yyyy'))
)
注意:如果在建  Interval  分区表是没有把所有的分区写完成，在插入相关数据后会 自动生成分区
2.创建一个以天为间隔的分区表
create table dave 
(
id  number,
dt  date
)
partition by range (dt)
INTERVAL (NUMTODSINTERVAL(1,'day'))
(
   partition p100101 values less than (to_date('2010-01-01','yyyy-mm-dd'))
);

普通表转分区表方法
将普通表转换成分区表有 4 种方法:
1. Export/import method
2. Insert with a subquery method
3. Partition exchange method
4. DBMS_REDEFINITION





##############分区表范例

------1、RANGE  
CREATE TABLE time_range_sales  
   ( prod_id        NUMBER(6)  
   , cust_id        NUMBER  
   , time_id        DATE  
   , channel_id     CHAR(1)  
   , promo_id       NUMBER(6)  
   , quantity_sold  NUMBER(3)  
   , amount_sold    NUMBER(10,2)  
   )  
PARTITION BY RANGE (time_id)  
 (PARTITION SALES_1998 VALUES LESS THAN (TO_DATE('01-JAN-1999','DD-MON-YYYY')),  
  PARTITION SALES_1999 VALUES LESS THAN (TO_DATE('01-JAN-2000','DD-MON-YYYY')),  
  PARTITION SALES_2000 VALUES LESS THAN (TO_DATE('01-JAN-2001','DD-MON-YYYY')),  
  PARTITION SALES_2001 VALUES LESS THAN (MAXVALUE)  
 );   
  
  
------2、LIST  
CREATE TABLE list_sales  
   ( prod_id        NUMBER(6)  
   , cust_id        NUMBER  
   , time_id        DATE  
   , channel_id     CHAR(1)  
   , promo_id       NUMBER(6)  
   , quantity_sold  NUMBER(3)  
   , amount_sold    NUMBER(10,2)  
   )  
PARTITION BY LIST (channel_id)  
 (PARTITION even_channels VALUES (2,4),  
  PARTITION odd_channels VALUES (3,9)  
 );   
  
------3、HASH  
CREATE TABLE hash_sales  
   ( prod_id        NUMBER(6)  
   , cust_id        NUMBER  
   , time_id        DATE  
   , channel_id     CHAR(1)  
   , promo_id       NUMBER(6)  
   , quantity_sold  NUMBER(3)  
   , amount_sold    NUMBER(10,2)  
   )  
PARTITION BY HASH (prod_id)  
PARTITIONS 2;   

------4、range-range组合分区  
CREATE TABLE shipments  
( order_id      NUMBER NOT NULL  
, order_date    DATE NOT NULL  
, delivery_date DATE NOT NULL  
, customer_id   NUMBER NOT NULL  
, sales_amount  NUMBER NOT NULL  
)  
PARTITION BY RANGE (order_date)  
SUBPARTITION BY RANGE (delivery_date)  
( PARTITION p_2006_jul VALUES LESS THAN (TO_DATE('01-AUG-2006','dd-MON-yyyy'))  
  ( SUBPARTITION p06_jul_e VALUES LESS THAN (TO_DATE('15-AUG-2006','dd-MON-yyyy'))  
  , SUBPARTITION p06_jul_a VALUES LESS THAN (TO_DATE('01-SEP-2006','dd-MON-yyyy'))  
  , SUBPARTITION p06_jul_l VALUES LESS THAN (MAXVALUE)  
  )  
, PARTITION p_2006_aug VALUES LESS THAN (TO_DATE('01-SEP-2006','dd-MON-yyyy'))  
  ( SUBPARTITION p06_aug_e VALUES LESS THAN (TO_DATE('15-SEP-2006','dd-MON-yyyy'))  
  , SUBPARTITION p06_aug_a VALUES LESS THAN (TO_DATE('01-OCT-2006','dd-MON-yyyy'))  
  , SUBPARTITION p06_aug_l VALUES LESS THAN (MAXVALUE)  
  )  
, PARTITION p_2006_sep VALUES LESS THAN (TO_DATE('01-OCT-2006','dd-MON-yyyy'))  
  ( SUBPARTITION p06_sep_e VALUES LESS THAN (TO_DATE('15-OCT-2006','dd-MON-yyyy'))  
  , SUBPARTITION p06_sep_a VALUES LESS THAN (TO_DATE('01-NOV-2006','dd-MON-yyyy'))  
  , SUBPARTITION p06_sep_l VALUES LESS THAN (MAXVALUE)  
  )  
, PARTITION p_2006_oct VALUES LESS THAN (TO_DATE('01-NOV-2006','dd-MON-yyyy'))  
  ( SUBPARTITION p06_oct_e VALUES LESS THAN (TO_DATE('15-NOV-2006','dd-MON-yyyy'))  
  , SUBPARTITION p06_oct_a VALUES LESS THAN (TO_DATE('01-DEC-2006','dd-MON-yyyy'))  
  , SUBPARTITION p06_oct_l VALUES LESS THAN (MAXVALUE)  
  )  
, PARTITION p_2006_nov VALUES LESS THAN (TO_DATE('01-DEC-2006','dd-MON-yyyy'))  
  ( SUBPARTITION p06_nov_e VALUES LESS THAN (TO_DATE('15-DEC-2006','dd-MON-yyyy'))  
  , SUBPARTITION p06_nov_a VALUES LESS THAN (TO_DATE('01-JAN-2007','dd-MON-yyyy'))  
  , SUBPARTITION p06_nov_l VALUES LESS THAN (MAXVALUE)  
  )  
, PARTITION p_2006_dec VALUES LESS THAN (TO_DATE('01-JAN-2007','dd-MON-yyyy'))  
  ( SUBPARTITION p06_dec_e VALUES LESS THAN (TO_DATE('15-JAN-2007','dd-MON-yyyy'))  
  , SUBPARTITION p06_dec_a VALUES LESS THAN (TO_DATE('01-FEB-2007','dd-MON-yyyy'))  
  , SUBPARTITION p06_dec_l VALUES LESS THAN (MAXVALUE)  
  )  
); 

--------5、range-list组合分区  
CREATE TABLE customers_part (  
   customer_id        NUMBER(6),  
   cust_first_name    VARCHAR2(20),  
   cust_last_name     VARCHAR2(20),  
   nls_territory      VARCHAR2(30),  
   credit_limit       NUMBER(9,2))   
   PARTITION BY RANGE (credit_limit)  
   SUBPARTITION BY LIST (nls_territory)  
      SUBPARTITION TEMPLATE   
         (SUBPARTITION east  VALUES   
            ('CHINA', 'JAPAN', 'INDIA', 'THAILAND'),  
          SUBPARTITION west VALUES   
             ('AMERICA', 'GERMANY', 'ITALY', 'SWITZERLAND'),  
          SUBPARTITION other VALUES (DEFAULT))  
      (PARTITION p1 VALUES LESS THAN (1000),  
       PARTITION p2 VALUES LESS THAN (2500),  
       PARTITION p3 VALUES LESS THAN (MAXVALUE));  

CREATE TABLE stripe_regional_sales  
            ( deptno number, item_no varchar2(20),  
              txn_date date, txn_amount number, state varchar2(2))  
   PARTITION BY RANGE (txn_date)  
   SUBPARTITION BY LIST (state)  
   SUBPARTITION TEMPLATE   
      (SUBPARTITION northwest VALUES ('OR', 'WA') TABLESPACE tbs_1,  
       SUBPARTITION southwest VALUES ('AZ', 'UT', 'NM') TABLESPACE tbs_2,  
       SUBPARTITION northeast VALUES ('NY', 'VM', 'NJ') TABLESPACE tbs_3,  
       SUBPARTITION southeast VALUES ('FL', 'GA') TABLESPACE tbs_4,  
       SUBPARTITION midwest VALUES ('SD', 'WI') TABLESPACE tbs_5,  
       SUBPARTITION south VALUES ('AL', 'AK') TABLESPACE tbs_6,  
       SUBPARTITION others VALUES (DEFAULT ) TABLESPACE tbs_7  
      )  
  (PARTITION q1_1999 VALUES LESS THAN ( TO_DATE('01-APR-1999','DD-MON-YYYY')),  
   PARTITION q2_1999 VALUES LESS THAN ( TO_DATE('01-JUL-1999','DD-MON-YYYY')),  
   PARTITION q3_1999 VALUES LESS THAN ( TO_DATE('01-OCT-1999','DD-MON-YYYY')),  
   PARTITION q4_1999 VALUES LESS THAN ( TO_DATE('1-JAN-2000','DD-MON-YYYY'))  
  );  
  





----6、range –hash 组合分区  
CREATE TABLE composite_sales  
    ( prod_id        NUMBER(6)  
    , cust_id        NUMBER  
    , time_id        DATE  
    , channel_id     CHAR(1)  
    , promo_id       NUMBER(6)  
    , quantity_sold  NUMBER(3)  
    , amount_sold         NUMBER(10,2)  
    )   
PARTITION BY RANGE (time_id)  
SUBPARTITION BY HASH (channel_id)  
  (PARTITION SALES_Q1_1998 VALUES LESS THAN (TO_DATE('01-APR-1998','DD-MON-YYYY')),  
   PARTITION SALES_Q2_1998 VALUES LESS THAN (TO_DATE('01-JUL-1998','DD-MON-YYYY')),  
   PARTITION SALES_Q3_1998 VALUES LESS THAN (TO_DATE('01-OCT-1998','DD-MON-YYYY')),  
   PARTITION SALES_Q4_1998 VALUES LESS THAN (TO_DATE('01-JAN-1999','DD-MON-YYYY')),  
   PARTITION SALES_Q1_1999 VALUES LESS THAN (TO_DATE('01-APR-1999','DD-MON-YYYY')),  
   PARTITION SALES_Q2_1999 VALUES LESS THAN (TO_DATE('01-JUL-1999','DD-MON-YYYY')),  
   PARTITION SALES_Q3_1999 VALUES LESS THAN (TO_DATE('01-OCT-1999','DD-MON-YYYY')),  
   PARTITION SALES_Q4_1999 VALUES LESS THAN (TO_DATE('01-JAN-2000','DD-MON-YYYY')),  
   PARTITION SALES_Q1_2000 VALUES LESS THAN (TO_DATE('01-APR-2000','DD-MON-YYYY')),  
   PARTITION SALES_Q2_2000 VALUES LESS THAN (TO_DATE('01-JUL-2000','DD-MON-YYYY'))  
      SUBPARTITIONS 8,  
   PARTITION SALES_Q3_2000 VALUES LESS THAN (TO_DATE('01-OCT-2000','DD-MON-YYYY'))  
     (SUBPARTITION ch_c,  
      SUBPARTITION ch_i,  
      SUBPARTITION ch_p,  
      SUBPARTITION ch_s,  
      SUBPARTITION ch_t),  
   PARTITION SALES_Q4_2000 VALUES LESS THAN (MAXVALUE)  
      SUBPARTITIONS 4)  

CREATE TABLE emp_sub_template (deptno NUMBER, empname VARCHAR(32), grade NUMBER)  
     PARTITION BY RANGE(deptno) SUBPARTITION BY HASH(empname)  
     SUBPARTITION TEMPLATE  
         (SUBPARTITION a TABLESPACE ts1,  
          SUBPARTITION b TABLESPACE ts2,  
          SUBPARTITION c TABLESPACE ts3,  
          SUBPARTITION d TABLESPACE ts4  
         )  
    (PARTITION p1 VALUES LESS THAN (1000),  
     PARTITION p2 VALUES LESS THAN (2000),  
     PARTITION p3 VALUES LESS THAN (MAXVALUE)  
    );





-----、list-range组合分区  
  
CREATE TABLE accounts  
( id             NUMBER  
, account_number NUMBER  
, customer_id    NUMBER  
, balance        NUMBER  
, branch_id      NUMBER  
, region         VARCHAR(2)  
, status         VARCHAR2(1)  
)  
PARTITION BY LIST (region)  
SUBPARTITION BY RANGE (balance)  
( PARTITION p_northwest VALUES ('OR', 'WA')  
  ( SUBPARTITION p_nw_low VALUES LESS THAN (1000)  
  , SUBPARTITION p_nw_average VALUES LESS THAN (10000)  
  , SUBPARTITION p_nw_high VALUES LESS THAN (100000)  
  , SUBPARTITION p_nw_extraordinary VALUES LESS THAN (MAXVALUE)  
  )  
, PARTITION p_southwest VALUES ('AZ', 'UT', 'NM')  
  ( SUBPARTITION p_sw_low VALUES LESS THAN (1000)  
  , SUBPARTITION p_sw_average VALUES LESS THAN (10000)  
  , SUBPARTITION p_sw_high VALUES LESS THAN (100000)  
  , SUBPARTITION p_sw_extraordinary VALUES LESS THAN (MAXVALUE)  
  )  
, PARTITION p_northeast VALUES ('NY', 'VM', 'NJ')  
  ( SUBPARTITION p_ne_low VALUES LESS THAN (1000)  
  , SUBPARTITION p_ne_average VALUES LESS THAN (10000)  
  , SUBPARTITION p_ne_high VALUES LESS THAN (100000)  
  , SUBPARTITION p_ne_extraordinary VALUES LESS THAN (MAXVALUE)  
  )  
, PARTITION p_southeast VALUES ('FL', 'GA')  
  ( SUBPARTITION p_se_low VALUES LESS THAN (1000)  
  , SUBPARTITION p_se_average VALUES LESS THAN (10000)  
  , SUBPARTITION p_se_high VALUES LESS THAN (100000)  
  , SUBPARTITION p_se_extraordinary VALUES LESS THAN (MAXVALUE)  
  )  
, PARTITION p_northcentral VALUES ('SD', 'WI')  
  ( SUBPARTITION p_nc_low VALUES LESS THAN (1000)  
  , SUBPARTITION p_nc_average VALUES LESS THAN (10000)  
  , SUBPARTITION p_nc_high VALUES LESS THAN (100000)  
  , SUBPARTITION p_nc_extraordinary VALUES LESS THAN (MAXVALUE)  
  )  
, PARTITION p_southcentral VALUES ('OK', 'TX')  
  ( SUBPARTITION p_sc_low VALUES LESS THAN (1000)  
  , SUBPARTITION p_sc_average VALUES LESS THAN (10000)  
  , SUBPARTITION p_sc_high VALUES LESS THAN (100000)  
  , SUBPARTITION p_sc_extraordinary VALUES LESS THAN (MAXVALUE)  
  )  
) ENABLE ROW MOVEMENT; 


-----、list-list组合分区  
  
CREATE TABLE accounts  
( id             NUMBER  
, account_number NUMBER  
, customer_id    NUMBER  
, balance        NUMBER  
, branch_id      NUMBER  
, region         VARCHAR(2)  
, status         VARCHAR2(1)  
)  
PARTITION BY LIST (region)  
SUBPARTITION BY LIST (status)  
( PARTITION p_northwest VALUES ('OR', 'WA')  
  ( SUBPARTITION p_nw_bad VALUES ('B')  
  , SUBPARTITION p_nw_average VALUES ('A')  
  , SUBPARTITION p_nw_good VALUES ('G')  
  )  
, PARTITION p_southwest VALUES ('AZ', 'UT', 'NM')  
  ( SUBPARTITION p_sw_bad VALUES ('B')  
  , SUBPARTITION p_sw_average VALUES ('A')  
  , SUBPARTITION p_sw_good VALUES ('G')  
  )  
, PARTITION p_northeast VALUES ('NY', 'VM', 'NJ')  
  ( SUBPARTITION p_ne_bad VALUES ('B')  
  , SUBPARTITION p_ne_average VALUES ('A')  
  , SUBPARTITION p_ne_good VALUES ('G')  
  )  
, PARTITION p_southeast VALUES ('FL', 'GA')  
  ( SUBPARTITION p_se_bad VALUES ('B')  
  , SUBPARTITION p_se_average VALUES ('A')  
  , SUBPARTITION p_se_good VALUES ('G')  
  )  
, PARTITION p_northcentral VALUES ('SD', 'WI')  
  ( SUBPARTITION p_nc_bad VALUES ('B')  
  , SUBPARTITION p_nc_average VALUES ('A')  
  , SUBPARTITION p_nc_good VALUES ('G')  
  )  
, PARTITION p_southcentral VALUES ('OK', 'TX')  
  ( SUBPARTITION p_sc_bad VALUES ('B')  
  , SUBPARTITION p_sc_average VALUES ('A')  
  , SUBPARTITION p_sc_good VALUES ('G')  
  )  
); 



-----9、List-hash组合分区  
CREATE TABLE accounts  
( id             NUMBER  
, account_number NUMBER  
, customer_id    NUMBER  
, balance        NUMBER  
, branch_id      NUMBER  
, region         VARCHAR(2)  
, status         VARCHAR2(1)  
)  
PARTITION BY LIST (region)  
SUBPARTITION BY HASH (customer_id) SUBPARTITIONS 8  
( PARTITION p_northwest VALUES ('OR', 'WA')  
, PARTITION p_southwest VALUES ('AZ', 'UT', 'NM')  
, PARTITION p_northeast VALUES ('NY', 'VM', 'NJ')  
, PARTITION p_southeast VALUES ('FL', 'GA')  
, PARTITION p_northcentral VALUES ('SD', 'WI')  
, PARTITION p_southcentral VALUES ('OK', 'TX')  
); 




------、组合列RANGE分区  
CREATE TABLE sales_demo (  
   year          NUMBER,   
   month         NUMBER,  
   day           NUMBER,  
   amount_sold   NUMBER)   
PARTITION BY RANGE (year,month)   
  (PARTITION before2001 VALUES LESS THAN (2001,1),  
   PARTITION q1_2001    VALUES LESS THAN (2001,4),  
   PARTITION q2_2001    VALUES LESS THAN (2001,7),  
   PARTITION q3_2001    VALUES LESS THAN (2001,10),  
   PARTITION q4_2001    VALUES LESS THAN (2002,1),  
   PARTITION future     VALUES LESS THAN (MAXVALUE,0));  

 

  
  
-----、interval-range 分区  
CREATE TABLE sales  
  ( prod_id       NUMBER(6)  
  , cust_id       NUMBER  
  , time_id       DATE  
  , channel_id    CHAR(1)  
  , promo_id      NUMBER(6)  
  , quantity_sold NUMBER(3)  
  , amount_sold   NUMBER(10,2)  
  )  
 PARTITION BY RANGE (time_id) INTERVAL (NUMTODSINTERVAL(1,'DAY'))  
SUBPARTITION BY RANGE(amount_sold)  
   SUBPARTITION TEMPLATE  
   ( SUBPARTITION p_low VALUES LESS THAN (1000)  
   , SUBPARTITION p_medium VALUES LESS THAN (4000)  
   , SUBPARTITION p_high VALUES LESS THAN (8000)  
   , SUBPARTITION p_ultimate VALUES LESS THAN (maxvalue)  
   )  
 ( PARTITION before_2000 VALUES LESS THAN (TO_DATE('01-JAN-2000','dd-MON-yyyy')))  
PARALLEL;  





------、interval-list  分区  
CREATE TABLE sales  
  ( prod_id       NUMBER(6)  
  , cust_id       NUMBER  
  , time_id       DATE  
  , channel_id    CHAR(1)  
  , promo_id      NUMBER(6)  
  , quantity_sold NUMBER(3)  
  , amount_sold   NUMBER(10,2)  
  )  
 PARTITION BY RANGE (time_id) INTERVAL (NUMTODSINTERVAL(1,'DAY'))  
 SUBPARTITION BY LIST (channel_id)  
   SUBPARTITION TEMPLATE  
   ( SUBPARTITION p_catalog VALUES ('C')  
   , SUBPARTITION p_internet VALUES ('I')  
   , SUBPARTITION p_partners VALUES ('P')  
   , SUBPARTITION p_direct_sales VALUES ('S')  
   , SUBPARTITION p_tele_sales VALUES ('T')  
   )  
 ( PARTITION before_2000 VALUES LESS THAN (TO_DATE('01-JAN-2000','dd-MON-yyyy')))  
PARALLEL;





-----、interval-hash分区  
CREATE TABLE xjmon.sales  
  ( prod_id       NUMBER(6)  
  , cust_id       NUMBER  
  , time_id       DATE  
  , channel_id    CHAR(1)  
  , promo_id      NUMBER(6)  
  , quantity_sold NUMBER(3)  
  , amount_sold   NUMBER(10,2)  
  )  
 PARTITION BY RANGE (time_id) INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))  
 SUBPARTITION BY HASH (cust_id) SUBPARTITIONS 4  
 ( PARTITION before_2000 VALUES LESS THAN (TO_DATE('2000-01','yyyy-mm')))  
PARALLEL;  
  
  
----、虚拟列分区表  
CREATE TABLE sales  
  ( prod_id       NUMBER(6) NOT NULL  
  , cust_id       NUMBER NOT NULL  
  , time_id       DATE NOT NULL  
  , channel_id    CHAR(1) NOT NULL  
  , promo_id      NUMBER(6) NOT NULL  
  , quantity_sold NUMBER(3) NOT NULL  
  , amount_sold   NUMBER(10,2) NOT NULL  
  , total_amount AS (quantity_sold * amount_sold)  
  )  
 PARTITION BY RANGE (time_id) INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))  
 SUBPARTITION BY RANGE(total_amount)  
 SUBPARTITION TEMPLATE  
   ( SUBPARTITION p_small VALUES LESS THAN (1000)  
   , SUBPARTITION p_medium VALUES LESS THAN (5000)  
   , SUBPARTITION p_large VALUES LESS THAN (10000)  
   , SUBPARTITION p_extreme VALUES LESS THAN (MAXVALUE)  
   )  
 (PARTITION sales_before_2007 VALUES LESS THAN  
        (TO_DATE('01-JAN-2007','dd-MON-yyyy'))  
)  
ENABLE ROW MOVEMENT  
PARALLEL NOLOGGING;  
  
  
  
-----、索引组织范围分区表  
CREATE TABLE sales(acct_no NUMBER(5),   
                   acct_name CHAR(30),   
                   amount_of_sale NUMBER(6),   
                   week_no INTEGER,  
                   sale_details VARCHAR2(1000),  
             PRIMARY KEY (acct_no, acct_name, week_no))   
     ORGANIZATION INDEX   
             INCLUDING week_no  
             OVERFLOW TABLESPACE overflow_here  
     PARTITION BY RANGE (week_no)  
            (PARTITION VALUES LESS THAN (5)   
                   TABLESPACE ts1,  
             PARTITION VALUES LESS THAN (9)   
                   TABLESPACE ts2 OVERFLOW TABLESPACE overflow_ts2,  
             ...  
             PARTITION VALUES LESS THAN (MAXVALUE)   
                   TABLESPACE ts13);  
  
----、索引组织hash分区表  
CREATE TABLE sales(acct_no NUMBER(5),   
                   acct_name CHAR(30),   
                   amount_of_sale NUMBER(6),   
                   week_no INTEGER,  
                   sale_details VARCHAR2(1000),  
             PRIMARY KEY (acct_no, acct_name, week_no))   
     ORGANIZATION INDEX   
             INCLUDING week_no  
     OVERFLOW  
          PARTITION BY HASH (week_no)  
             PARTITIONS 16  
             STORE IN (ts1, ts2, ts3, ts4)  
             OVERFLOW STORE IN (ts3, ts6, ts9);  
  
  
-----、索引组织列表分区表  
CREATE TABLE sales(acct_no NUMBER(5),   
                   acct_name CHAR(30),   
                   amount_of_sale NUMBER(6),   
                   week_no INTEGER,  
                   sale_details VARCHAR2(1000),  
             PRIMARY KEY (acct_no, acct_name, week_no))   
     ORGANIZATION INDEX   
             INCLUDING week_no  
             OVERFLOW TABLESPACE example  
     PARTITION BY LIST (week_no)  
            (PARTITION VALUES (1, 2, 3, 4)   
                   TABLESPACE example,  
             PARTITION VALUES (5, 6, 7, 8)   
                   TABLESPACE example OVERFLOW TABLESPACE example,  
             PARTITION VALUES (DEFAULT)   
                   TABLESPACE example);  
  
  
-----、11G 新特性 虚拟列分区  
CREATE TABLE car_rentals  
( id                  NUMBER NOT NULL  
 , customer_id         NUMBER NOT NULL  
 , confirmation_number VARCHAR2(12) NOT NULL  
 , car_id              NUMBER  
 , car_type            VARCHAR2(10)  
 , requested_car_type  VARCHAR2(10) NOT NULL  
 , reservation_date    DATE NOT NULL  
 , start_date          DATE NOT NULL  
 , end_date            DATE  
 , country as (substr(confirmation_number,9,2))  
) PARTITION BY LIST (country)  
SUBPARTITION BY HASH (customer_id)  
SUBPARTITIONS 16  
( PARTITION north_america VALUES ('US','CA','MX')  
 , PARTITION south_america VALUES ('BR','AR','PE')  
 , PARTITION europe VALUES ('GB','DE','NL','BE','FR','ES','IT','CH')  
 , PARTITION apac VALUES ('NZ','AU','IN','CN')  
) ENABLE ROW MOVEMENT;




