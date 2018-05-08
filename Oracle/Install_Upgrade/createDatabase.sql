
----1、参数调整
alter system set  db_recovery_file_dest=''   scope=spfile  sid='*';
alter system reset db_recovery_file_dest_size scope=spfile sid='*';
alter system set  audit_trail='db'   scope=spfile  sid='*';
alter system set  processes=10000    scope=spfile  sid='*';
alter system set  session_cached_cursors=400 scope=spfile sid='*';
alter system set  remote_login_passwordfile='NONE'  scope=spfile  sid='*';
alter system set  O7_DICTIONARY_ACCESSIBILITY=false scope=spfile sid='*';
alter system set  REMOTE_OS_ROLES=false scope=spfile sid='*';
alter system set  db_files=5000 scope=spfile sid='*';
alter system set  open_cursors=1500 scope=spfile sid='*';
alter system set  cursor_sharing='force' scope=spfile sid='*';
alter system set  remote_listener=''  scope=both sid='*';
alter system set undo_retention=3600 scope=both sid='*';
alter system set parallel_force_local=true sid='*' scope=spfile;


----内存参数
alter system set  memory_target=0 scope=spfile sid='*';
alter system set  sga_target=0 scope=spfile sid='*';
alter system set  sga_max_size=160G scope=spfile sid='*';
alter system set  db_cache_size=120G scope=spfile sid='*';
alter system set  shared_pool_size=15G scope=spfile sid='*';

-----一般建议为shared_pool_size 的10%

alter system set shared_pool_reserved_size=1G scope=spfile sid='*';    
alter system set  pga_aggregate_target=20G scope=spfile sid='*';
alter system set  java_pool_size=500M scope=spfile sid='*';
alter system set  large_pool_size=500M scope=spfile sid='*';
alter system set  streams_pool_size=500M scope=spfile sid='*';


----不开大页时建议设置
alter system set lock_sga=true sid='*' scope = spfile sid='*';

alter system set pre_page_sga = true scope=spfile sid='*';  

--##for 11g ADG
alter system set  "_ktb_debug_flags"=8 scope=spfile sid='*';
----关闭feedback  11g
alter system set  "_optimizer_use_feedback"=false  scope=spfile sid='*';
---##关闭笛卡尔集 11g
alter system set  "_optimizer_mjc_enabled"=false scope=spfile sid='*';
alter system set "_optimizer_cartesian_enabled"=false scope=both sid='*';
/*+ opt_param('_optimizer_mjc_enabled','false')*/
----###关闭索引bitmap 11g
alter system set  "_b_tree_bitmap_plans"=FALSE scope=spfile sid='*';
----### 11g 关闭密码延迟验证
alter system set event = '28401 trace name context forever, level 1' sid='*' scope = spfile;
--### 关闭drm  11g
alter system set  "_gc_policy_time"=0  scope=spfile sid='*';
alter system set "_gc_undo_affinity"=false sid='*' scope=spfile;
------关闭Adaptive direct path read  11g
alter system set "_serial_direct_read"=never scope=spfile sid='*';
-----关闭Adaptive Log File Sync  11g
alter system set "_use_adaptive_log_file_sync"=False scope=spfile sid='*';
------关闭Adaptive Cursor Sharing  11g  容易引起多版本问题
alter system set "_optimizer_extended_cursor_sharing_rel"=none   scope=spfile sid='*';
alter system set "_optimizer_extended_cursor_sharing"=none scope=spfile sid='*';
alter system set "_optimizer_adaptive_cursor_sharing"=false scope=spfile sid='*';


------关闭文件写错误终止实例  11g
alter system set  "_datafile_write_errors_crash_instance"=False  scope=spfile sid='*';
-----关闭资源管理器 11g
alter system set "_resource_manager_always_off"=true scope=spfile;
alter system set "_resource_manager_always_on"=false scope=spfile;
----关闭段延迟段创建 11g
alter system set deferred_segment_creation=flase sscope=spfile;


--------------redo调整

alter database add logfile THREAD 1 group 11  ('/opt/oradata01/bjpaasc/redo_11_01.redo.log','/opt/oradata02/bjpaasc/redo_11_02.redo.log') size 2048M ;
alter database add logfile THREAD 1 group 12  ('/opt/oradata01/bjpaasc/redo_12_01.redo.log','/opt/oradata02/bjpaasc/redo_12_02.redo.log') size 2048M ;
alter database add logfile THREAD 1 group 13  ('/opt/oradata01/bjpaasc/redo_13_01.redo.log','/opt/oradata02/bjpaasc/redo_13_02.redo.log') size 2048M ;
alter database add logfile THREAD 1 group 14  ('/opt/oradata01/bjpaasc/redo_14_01.redo.log','/opt/oradata02/bjpaasc/redo_14_02.redo.log') size 2048M ;
alter database add logfile THREAD 1 group 15  ('/opt/oradata01/bjpaasc/redo_15_01.redo.log','/opt/oradata02/bjpaasc/redo_15_02.redo.log') size 2048M ;
alter database add logfile THREAD 1 group 16  ('/opt/oradata01/bjpaasc/redo_16_01.redo.log','/opt/oradata02/bjpaasc/redo_16_02.redo.log') size 2048M ;
alter database add logfile THREAD 1 group 17  ('/opt/oradata01/bjpaasc/redo_17_01.redo.log','/opt/oradata02/bjpaasc/redo_17_02.redo.log') size 2048M ;
alter database add logfile THREAD 1 group 18  ('/opt/oradata01/bjpaasc/redo_18_01.redo.log','/opt/oradata02/bjpaasc/redo_18_02.redo.log') size 2048M ;

alter database add logfile THREAD 2 group 21  ('/opt/oradata01/bjpaasc/redo_21_01.redo.log','/opt/oradata02/bjpaasc/redo_21_02.redo.log') size 2048M ;
alter database add logfile THREAD 2 group 22  ('/opt/oradata01/bjpaasc/redo_22_01.redo.log','/opt/oradata02/bjpaasc/redo_22_02.redo.log') size 2048M ;
alter database add logfile THREAD 2 group 23  ('/opt/oradata01/bjpaasc/redo_23_01.redo.log','/opt/oradata02/bjpaasc/redo_23_02.redo.log') size 2048M ;
alter database add logfile THREAD 2 group 24  ('/opt/oradata01/bjpaasc/redo_24_01.redo.log','/opt/oradata02/bjpaasc/redo_24_02.redo.log') size 2048M ;
alter database add logfile THREAD 2 group 25  ('/opt/oradata01/bjpaasc/redo_25_01.redo.log','/opt/oradata02/bjpaasc/redo_25_02.redo.log') size 2048M ;
alter database add logfile THREAD 2 group 26  ('/opt/oradata01/bjpaasc/redo_26_01.redo.log','/opt/oradata02/bjpaasc/redo_26_02.redo.log') size 2048M ;
alter database add logfile THREAD 2 group 27  ('/opt/oradata01/bjpaasc/redo_27_01.redo.log','/opt/oradata02/bjpaasc/redo_27_02.redo.log') size 2048M ;
alter database add logfile THREAD 2 group 28  ('/opt/oradata01/bjpaasc/redo_28_01.redo.log','/opt/oradata02/bjpaasc/redo_28_02.redo.log') size 2048M ;

alter database add logfile THREAD 3 group 31  ('/opt/oradata01/bjpaasc/redo_31_01.redo.log','/opt/oradata02/bjpaasc/redo_31_02.redo.log') size 2048M ;
alter database add logfile THREAD 3 group 32  ('/opt/oradata01/bjpaasc/redo_32_01.redo.log','/opt/oradata02/bjpaasc/redo_32_02.redo.log') size 2048M ;
alter database add logfile THREAD 3 group 33  ('/opt/oradata01/bjpaasc/redo_33_01.redo.log','/opt/oradata02/bjpaasc/redo_33_02.redo.log') size 2048M ;
alter database add logfile THREAD 3 group 34  ('/opt/oradata01/bjpaasc/redo_34_01.redo.log','/opt/oradata02/bjpaasc/redo_34_02.redo.log') size 2048M ;
alter database add logfile THREAD 3 group 35  ('/opt/oradata01/bjpaasc/redo_35_01.redo.log','/opt/oradata02/bjpaasc/redo_35_02.redo.log') size 2048M ;
alter database add logfile THREAD 3 group 36  ('/opt/oradata01/bjpaasc/redo_36_01.redo.log','/opt/oradata02/bjpaasc/redo_36_02.redo.log') size 2048M ;
alter database add logfile THREAD 3 group 37  ('/opt/oradata01/bjpaasc/redo_37_01.redo.log','/opt/oradata02/bjpaasc/redo_37_02.redo.log') size 2048M ;
alter database add logfile THREAD 3 group 38  ('/opt/oradata01/bjpaasc/redo_38_01.redo.log','/opt/oradata02/bjpaasc/redo_38_02.redo.log') size 2048M ;




alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;


alter system checkpoint;

ALTER DATABASE DROP LOGFILE GROUP 1;
ALTER DATABASE DROP LOGFILE GROUP 2;
ALTER DATABASE DROP LOGFILE GROUP 3;
ALTER DATABASE DROP LOGFILE GROUP 4;
ALTER DATABASE DROP LOGFILE GROUP 5;
ALTER DATABASE DROP LOGFILE GROUP 6;


select * from v$log order by THREAD#,GROUP#;




-------数据文件调整
set linesize 1000 pagesize 5000
col cmd for a150
select 'alter database datafile ' || '''' || FILE_NAME || '''' ||
       ' resize 30G ;' cmd
  from dba_data_files
 union all
select 'alter database tempfile ' || '''' || FILE_NAME || '''' ||
       ' resize 30G ;' cmd
  from dba_temp_files 
  union all
select 'alter database datafile ' || '''' || FILE_NAME || '''' ||
       ' autoextend off ;' cmd
  from dba_data_files
 union all
select 'alter database tempfile ' || '''' || FILE_NAME || '''' ||
       ' autoextend off ;' cmd
  from dba_temp_files;


alter database datafile '/opt/oradata01/bjpaasc/system01.dbf' resize 30G ;
alter database datafile '/opt/oradata01/bjpaasc/sysaux01.dbf' resize 30G ;
alter database datafile '/opt/oradata01/bjpaasc/undotbs01.dbf' resize 30G ;
alter database datafile '/opt/oradata01/bjpaasc/users01.dbf' resize 30G ;
alter database datafile '/opt/oradata01/bjpaasc/undotbs02.dbf' resize 30G ;
alter database datafile '/opt/oradata01/bjpaasc/undotbs03.dbf' resize 30G ;
alter database datafile '/opt/oradata01/bjpaasc/system01.dbf' autoextend off ;
alter database datafile '/opt/oradata01/bjpaasc/sysaux01.dbf' autoextend off ;
alter database datafile '/opt/oradata01/bjpaasc/undotbs01.dbf' autoextend off ;
alter database datafile '/opt/oradata01/bjpaasc/users01.dbf' autoextend off ;
alter database datafile '/opt/oradata01/bjpaasc/undotbs02.dbf' autoextend off ;
alter database datafile '/opt/oradata01/bjpaasc/undotbs03.dbf' autoextend off ;
alter database tempfile '/opt/oradata01/bjpaasc/temp01.dbf' resize 30G ;
alter database tempfile '/opt/oradata01/bjpaasc/temp01.dbf' autoextend off ;
alter tablespace SYSAUX add datafile '/opt/oradata01/bjpaasc/sysaux02.dbf' size 30G   autoextend off;
alter tablespace UNDOTBS1 add datafile '/opt/oradata01/bjpaasc/undotbs0101.dbf' size 30G   autoextend off;
alter tablespace UNDOTBS2 add datafile '/opt/oradata01/bjpaasc/undotbs0201.dbf' size 30G   autoextend off;
alter tablespace UNDOTBS3 add datafile '/opt/oradata01/bjpaasc/undotbs0301.dbf' size 30G   autoextend off;
alter tablespace UNDOTBS1 add datafile '/opt/oradata01/bjpaasc/undotbs0102.dbf' size 30G   autoextend off;
alter tablespace UNDOTBS2 add datafile '/opt/oradata01/bjpaasc/undotbs0202.dbf' size 30G   autoextend off;
alter tablespace UNDOTBS3 add datafile '/opt/oradata01/bjpaasc/undotbs0302.dbf' size 30G   autoextend off;

------快照保存周期检查
set linesize 1000 pagesize 5000
col cmd for a200
select 'exec DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(retention => 35*24*60,INTERVAL => 30,dbid => ' || DBID ||' );' cmd  from dba_hist_wr_control;


exec dbms_workload_repository.create_snapshot();

-------调整db审计位置
BEGIN
  DBMS_AUDIT_MGMT.set_audit_trail_location(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,
                                            --this moves table AUD$
                                           audit_trail_location_value => 'USERS'); --AUD替换为系统中的ASSM表空间
END;
/


BEGIN
  DBMS_AUDIT_MGMT.set_audit_trail_location(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD,
                                            --this moves table FGA_LOG$
                                           audit_trail_location_value => 'USERS'); --FGA替换为系统中的ASSM表空间
END;
/


------
