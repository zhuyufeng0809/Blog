---- 作业配置

 /*
   两个例子的job_name：
     SJZBQ_DJ_BGDJMX
     S0_DJ_BGDJMX
   分配的job_id:
     1019991215
     4019991576
   两个目标表：
     SJZBQ_BZ_DJ_BGDJMX_ZYF
     SJCK_BZ_DJ_BGDJMX_ZYF
  */

-- 数据准备区

select * from SJJC_BZ.T_CTL_JOB_INFO where JOB_ID = 1019991215 or JOB_ID =
(select JOB_ID from SJJC_BZ.T_CTL_JOB_INFO where JOB_NAME = 'SJZBQ_DJ_BGDJMX' );

select * from SJJC_BZ.T_ETL_TAB_CONF where TAB_ID = 1019991215 or TAB_ID =
(select JOB_ID from SJJC_BZ.T_CTL_JOB_INFO where JOB_NAME = 'SJZBQ_DJ_BGDJMX' );

select  * from SJJC_BZ.T_ETL_TAB_MAPPING where TAB_ID = 1019991215 or TAB_ID =
(select JOB_ID from SJJC_BZ.T_CTL_JOB_INFO where JOB_NAME = 'SJZBQ_DJ_BGDJMX' );

select * from SJJC_BZ.T_ETL_COL_MAPPING where TAB_ID = 1019991215
 or TAB_ID =
 (select JOB_ID from SJJC_BZ.T_CTL_JOB_INFO where JOB_NAME = 'SJZBQ_DJ_BGDJMX' );

-- s0区

select * from SJJC_BZ.T_CTL_JOB_INFO where JOB_ID = 4019991576 or JOB_ID =
(select JOB_ID from SJJC_BZ.T_CTL_JOB_INFO where JOB_NAME = 'S0_DJ_BGDJMX');

select * from SJJC_BZ.T_ETL_TAB_CONF where TAB_ID = 4019991576 or TAB_ID =
(select JOB_ID from SJJC_BZ.T_CTL_JOB_INFO where JOB_NAME = 'S0_DJ_BGDJMX');

select * from SJJC_BZ.T_ETL_TAB_MAPPING where TAB_ID = 4019991576 or TAB_ID =
(select JOB_ID from SJJC_BZ.T_CTL_JOB_INFO where JOB_NAME = 'S0_DJ_BGDJMX');

select * from SJJC_BZ.T_ETL_COL_MAPPING where TAB_ID = 4019991576 or TAB_ID =
(select JOB_ID from SJJC_BZ.T_CTL_JOB_INFO where JOB_NAME = 'S0_DJ_BGDJMX');


-- 执行作业

declare
  I_JOB_NAME varchar2(30);
  I_BATCH_ID varchar2(10);
  O_SUCC_FLAG varchar(10);
  O_SHELL_FLAG varchar(10);
begin

    I_JOB_NAME := 'SJCK_BZ_DJ_BGDJMX_ZYF';
    I_BATCH_ID := '1';

    SJJC_BZ.PKG_ETL_SHELL.P_ETL_SHELL_CALL(I_JOB_NAME,I_BATCH_ID,O_SUCC_FLAG,O_SHELL_FLAG);

    dbms_output.put_line(nvl(O_SUCC_FLAG,'null'));
	  dbms_output.put_line(O_SHELL_FLAG);

end;

select * from t_ctl_log_stat t where t.job_name='SJCK_BZ_DJ_BGDJMX_ZYF' order by t.etl_begin_date desc;
select * from t_ctl_log_step t  where t.job_name = 'SJCK_BZ_DJ_BGDJMX_ZYF'  order by 1 desc;

---- 作业流配置

select * from T_CTL_FLOW_INFO;
select * from T_CTL_FLOW_CONTROL;
select * from T_CTL_JOB_LIST;
select * from T_CTL_FLOW_DEP;

select SEQ_CTL_BATCH.currval from dual;


select * from t_etl_tab_conf where target_tab = 'WD_NSRXX_BQ';