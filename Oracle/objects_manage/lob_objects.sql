-------------------创建大对象分区表
CREATE TABLE patchmain(
 patch_id   NUMBER
,region     VARCHAR2(16)
,patch_desc CLOB)
LOB(patch_desc) STORE AS (TABLESPACE patch1)
PARTITION BY LIST (REGION) (
PARTITION p1 VALUES ('EAST')
LOB(patch_desc) STORE AS SECUREFILE
(TABLESPACE patch1 COMPRESS HIGH)
TABLESPACE inv_data1
,
PARTITION p2 VALUES ('WEST')
LOB(patch_desc) STORE AS SECUREFILE
(TABLESPACE patch2 DEDUPLICATE NOCOMPRESS)
TABLESPACE inv_data2
,
PARTITION p3 VALUES (DEFAULT)
LOB(patch_desc) STORE AS SECUREFILE
(TABLESPACE patch3 COMPRESS LOW)
TABLESPACE inv_data3
);






----------显示大对象占用的空间信息
DECLARE
  l_segment_owner       VARCHAR2(40);
  l_table_name          VARCHAR2(40);
  l_segment_name        VARCHAR2(40);
  l_segment_size_blocks NUMBER;
  l_segment_size_bytes  NUMBER;
  l_used_blocks         NUMBER;
  l_used_bytes          NUMBER;
  l_expired_blocks      NUMBER;
  l_expired_bytes       NUMBER;
  l_unexpired_blocks    NUMBER;
  l_unexpired_bytes     NUMBER;
  --
  CURSOR c1 IS
    SELECT owner, table_name, segment_name
      FROM dba_lobs
     WHERE table_name = 'PATCHMAIN';
BEGIN
  FOR r1 IN c1
  LOOP
    l_segment_owner := r1.owner;
    l_table_name    := r1.table_name;
    l_segment_name  := r1.segment_name;
    --
    dbms_output.put_line('-----------------------------');
    dbms_output.put_line('Table Name         : ' || l_table_name);
    dbms_output.put_line('Segment Name       : ' || l_segment_name);
    --
    dbms_space.space_usage(segment_owner => l_segment_owner,
                           segment_name => l_segment_name,
                           segment_type => 'LOB', partition_name => NULL,
                           segment_size_blocks => l_segment_size_blocks,
                           segment_size_bytes => l_segment_size_bytes,
                           used_blocks => l_used_blocks,
                           used_bytes => l_used_bytes,
                           expired_blocks => l_expired_blocks,
                           expired_bytes => l_expired_bytes,
                           unexpired_blocks => l_unexpired_blocks,
                           unexpired_bytes => l_unexpired_bytes);
    --
    dbms_output.put_line('segment_size_blocks: ' || l_segment_size_blocks);
    dbms_output.put_line('segment_size_bytes : ' || l_segment_size_bytes);
    dbms_output.put_line('used_blocks        : ' || l_used_blocks);
    dbms_output.put_line('used_bytes         : ' || l_used_bytes);
    dbms_output.put_line('expired_blocks     : ' || l_expired_blocks);
    dbms_output.put_line('expired_bytes      : ' || l_expired_bytes);
    dbms_output.put_line('unexpired_blocks   : ' || l_unexpired_blocks);
    dbms_output.put_line('unexpired_bytes    : ' || l_unexpired_bytes);
  END LOOP;
END;
/




---------------------加载CLOB数据
DECLARE
  src_clb      BFILE; -- point to source CLOB on file system
  dst_clb      CLOB; -- destination CLOB in table
  src_doc_name VARCHAR2(300) := 'patch.txt';
  src_offset   INTEGER := 1; -- where to start in the source CLOB
  dst_offset   INTEGER := 1; -- where to start in the target CLOB
  lang_ctx     INTEGER := dbms_lob.default_lang_ctx;
  warning_msg  NUMBER; -- returns warning value if bad chars
BEGIN
  src_clb := bfilename('LOAD_LOB', src_doc_name); -- assign pointer to file
  --
  INSERT INTO patchmain
    (patch_id, patch_desc) -- create LOB placeholder
  VALUES
    (patch_seq.nextval, empty_clob())
  RETURNING patch_desc INTO dst_clb;
  --
  dbms_lob.open(src_clb, dbms_lob.lob_readonly); -- open file
  --
  -- load the file into the LOB
  dbms_lob.loadclobfromfile(dest_lob => dst_clb, src_bfile => src_clb,
                            amount => dbms_lob.lobmaxsize,
                            dest_offset => dst_offset,
                            src_offset => src_offset,
                            bfile_csid => dbms_lob.default_csid,
                            lang_context => lang_ctx, warning => warning_msg);
  dbms_lob.close(src_clb); -- close file
  --
  dbms_output.put_line('Wrote CLOB: ' || src_doc_name);
END;
/

---------------------加载BLOB数据
DECLARE
  src_blb      BFILE; -- point to source BLOB on file system
  dst_blb      BLOB; -- destination BLOB in table
  src_doc_name VARCHAR2(300) := 'patch.zip';
  src_offset   INTEGER := 1; -- where to start in the source BLOB
  dst_offset   INTEGER := 1; -- where to start in the target BLOB
BEGIN
  src_blb := bfilename('LOAD_LOB', src_doc_name); -- assign pointer to file
  --
  INSERT INTO patchmain
    (patch_id, patch_file)
  VALUES
    (patch_seq.nextval, empty_blob())
  RETURNING patch_file INTO dst_blb; -- create LOB placeholder column first
  dbms_lob.open(src_blb, dbms_lob.lob_readonly);
  --
  dbms_lob.loadblobfromfile(dest_lob => dst_blb, src_bfile => src_blb,
                            amount => dbms_lob.lobmaxsize,
                            dest_offset => dst_offset,
                            src_offset => src_offset);
  dbms_lob.close(src_blb);
  dbms_output.put_line('Wrote BLOB: ' || src_doc_name);
END;
/
