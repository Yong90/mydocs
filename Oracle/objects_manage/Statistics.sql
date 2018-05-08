优化器统计范围：
表统计： 行数，块数，行平均长度；all_tables：NUM_ROWS，BLOCKS，AVG_ROW_LEN；
列统计： 列中唯一值的数量（NDV），NULL值的数量，数据分布；
             --DBA_TAB_COLUMNS：NUM_DISTINCT，NUM_NULLS，HISTOGRAM；
索引统计：叶块数量，等级，聚簇因子；
             --DBA_INDEXES：LEAF_BLOCKS，CLUSTERING_FACTOR，BLEVEL；
系统统计：I/O性能与使用率；
             --CPU性能与使用率；
             --存储在aux_stats$中，需要使用dbms_stats收集，I/O统计在X$KCFIO中；
analyze统计：
需要使用ANALYZE统计的统计：使用LIST CHAINED ROWS和VALIDATE子句收集空闲列表块的统计； 
ANALYZE table tablename compute statistics;
ANALYZE index|cluster indexname estimate statistics;
ANALYZE TABLE tablename COMPUTE STATISTICS  FOR TABLE/FOR ALL [LOCAL] INDEXES/FOR ALL [INDEXED] COLUMNS;
ANALYZE TABLE tablename DELETE STATISTICS
ANALYZE TABLE tablename VALIDATE REF UPDATE
ANALYZE TABLE tablename VALIDATE STRUCTURE [CASCADE]|[INTO TableName]
ANALYZE TABLE tablename LIST CHAINED ROWS [INTO TableName]
analyze table irm.E_DEVICE_PTN validate structure cascade online 
注意：ANALYZE 不适合做分区表的分析

dbms_stats：
dbms_stats能良好地估计统计数据（尤其是针对较大的分区表），并能获得更好的统计结果，最终制定出速度更快的SQL执行计划。这个包的下面四个存储过程分别收集index、table、schema、database的统计信息:
dbms_stats.gather_table_stats           收集表、列和索引的统计信息；
dbms_stats.gather_schema_stats         收集SCHEMA下所有对象的统计信息；
dbms_stats.gather_index_stats           收集索引的统计信息；
dbms_stats.gather_system_stats          收集系统统计信息
dbms_stats.GATHER_DICTIONARY_STATS：  所有字典对象的统计；
DBMS_STATS.GATHER_DICTIONARY_STATS   其收集所有系统模式的统计
dbms_stats.delete_table_stats            删除表的统计信息
dbms_stats.delete_index_stats            删除索引的统计信息
dbms_stats.export_table_stats            输出表的统计信息
dbms_stats.create_state_table
dbms_stats.set_table_stats               设置表的统计
dbms_stats.auto_sample_size

----查看自动统计信息是否开启，
oracle 10g ：SELECT OWNER,JOB_NAME,ENABLED FROM DBA_SCHEDULER_JOBS WHERE JOB_NAME = 'GATHER_STATS_JOB'; 
oracle 11g ：select t1.owner, t1.job_name, t1.enabled  from dba_scheduler_jobs t1  where t1.job_name = 'BSLN_MAINTAIN_STATS_JOB';

---10g关闭自动统计信息命令
exec DBMS_SCHEDULER.DISABLE('GATHER_STATS_JOB');
BEGIN
  DBMS_SCHEDULER.DISABLE('GATHER_STATS_JOB');
END;
/
---10g启用自动统计信息命令
exec DBMS_SCHEDULER.ENABLE('GATHER_STATS_JOB');


-------11g 打开自动收集统计信息
BEGIN
  DBMS_AUTO_TASK_ADMIN.ENABLE(
     client_name => 'auto optimizer stats collection' 
,    operation   => NULL
,    window_name => NULL
);
END;
/
-------11g 关闭自动收集统计信息
BEGIN
  DBMS_AUTO_TASK_ADMIN.DISABLE(
     client_name => 'auto optimizer stats collection'
,    operation   => NULL 
,    window_name => NULL
);
END;
/



--------不收集直方图
declare
begin
 DBMS_STATS.GATHER_TABLE_STATS(ownname => 'SWATCH',
                                tabname => 'TEST_INDEX_COST',
                                --granularity => 'PARTITION',
                                --partname=>'POPERATIONPROCESS0102',  
                                estimate_percent => 1,     -------1可以替换为dbms_stat.auto_sample_size
                                method_opt       => 'FOR ALL COLUMNS SIZE 1',
                                no_invalidate    => false,
                                cascade          => true,
                                degree           => 10);   ------10可以换为dbma_stat.auto_degree
end;


declare
  v_error varchar2(4000);
  cursor c2 is
    select distinct a.owner, a.segment_name, a.partition_name
      from dba_segments a, dba_tab_partitions b
     where a.segment_type = 'TABLE PARTITION'
       and a.segment_name not like 'BIN$%'
       and a.owner = b.table_owner
       and a.owner in('TLBR')  
       and a.segment_name = b.table_name
       and a.partition_name = b.partition_name
       and segment_name=UPPER('t_tlbr_user_week_part_201528');
  v_start_time date;
  v_end_time   date;
begin
  for r2 in c2 loop
    begin
      v_start_time := sysdate;
      DBMS_STATS.GATHER_TABLE_STATS(ownname          => r2.owner,
                                    tabname          => r2.segment_name,
                                    partname         => r2.partition_name,
                                    estimate_percent => 1,
                                    method_opt       => 'FOR ALL COLUMNS SIZE 1',
                                    no_invalidate    => false,
                                    cascade          => true,
                                    degree           => 10);
      v_end_time := sysdate;
      insert into sys.tab_ana_log
      values
        (r2.owner,r2.segment_name, r2.partition_name, v_start_time, v_end_time,'');
      commit;
    end;
  end loop;
end;






BEGIN
 DBMS_STATS.GATHER_TABLE_STATS(ownname          => 'SCOTT',
             tabname          => 'par_table',
             estimate_percent => 30,   
             method_opt       => 'for all columns size repeat',
             no_invalidate    => FALSE, 
                   degree           => 8,
             granularity      => 'ALL',
             cascade          => TRUE); 
END;
/

exec dbms_stats.gather_table_stats (ownname => 'TNMS',tabname => 'TRAPH',estimate_percent => 50,block_sample => TRUE,method_opt => 'FOR ALL COLUMNS SIZE 1',degree => DBMS_STATS.AUTO_DEGREE,granularity => 'ALL',cascade => true);




-----------减少热快和增大事务并行数
alter table <table_name> PCTFREE 40  INITRANS 50;




统计收集的权限
必须授予普通用户权限
sys@ORADB> grant execute_catalog_role to hr;
sys@ORADB> grant connect,resource,analyze any to hr;

