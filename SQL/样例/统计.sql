-- 视图，作业，作业流
declare
  viewss varchar2(10) default '无';
  jobss varchar2(10) default '无';
  flowss varchar2(10) default '无';

  viewnum int;
  jobnum int;
  flownum int;
begin

  for i in (select NAMESSS from "sjjc_bz_readonly.ls_zhuyuf") loop

    select count(*) into viewnum from all_objects t
    where t.OWNER='SJCK_BZ' and t.OBJECT_NAME= i.NAMESSS and t.OBJECT_TYPE = 'VIEW';

    if viewnum >= 1 then
      viewss := '有';
    end if;

    select count(*) into jobnum from sjjc_bz.t_etl_tab_conf g
    where g.target_owner='${USER_SJCK}' and g.target_tab=i.NAMESSS;

    if jobnum >= 1 then
      jobss := '有';
    end if;

    select count(*) into flownum from sjjc_bz.t_ctl_job_list v
    where v.flow_id='ETL_SJCK_BZ' and v.job_name=i.NAMESSS;

    if flownum >= 1 then
      flowss := '有';
    end if;

    update "sjjc_bz_readonly.ls_zhuyuf" set VIEWSSS = viewss,JOBSSS = jobss
    ,FLOWSSSS = flowss
    where NAMESSS = i.NAMESSS;

  end loop;

end;
-- 表
begin

  for i in (select distinct OBJECT_NAME from all_objects t
    where t.OWNER='SJCK_BZ' and t.OBJECT_NAME in (select NAMESSS from "sjjc_bz_readonly.ls_zhuyuf")
    and OBJECT_TYPE like 'TABLE%') loop
    update "sjjc_bz_readonly.ls_zhuyuf" set TABLESSS = '有' where NAMESSS = i.OBJECT_NAME;
  end loop;

end;

-- 初始化
begin
  for i in (select NAMESSS from "sjjc_bz_readonly.ls_zhuyuf"
    where NAMESSS in (select job_table from sjjc_bz.t_ctl_job_list t
  where t.flow_id='ETL_INIT_WD')) loop
    update "sjjc_bz_readonly.ls_zhuyuf" set INIT = '有' where NAMESSS = i.NAMESSS;

  end loop;
end;

-- 验证

select count(*) from "sjjc_bz_readonly.ls_zhuyuf" a  where exists(select
* from all_objects t
where t.OWNER='SJCK_BZ' and t.OBJECT_NAME=a.NAMESSS and t.OBJECT_TYPE like 'TABLE%');
select count(*) from "sjjc_bz_readonly.ls_zhuyuf" where TABLESSS = '有';

select count(*) from "sjjc_bz_readonly.ls_zhuyuf" a where exists(select
* from all_objects t
where t.OWNER='SJCK_BZ' and t.OBJECT_NAME=a.NAMESSS and t.OBJECT_TYPE like '%VIEW%');
select count(*) from "sjjc_bz_readonly.ls_zhuyuf" where VIEWSSS = '有';


select count(*) from "sjjc_bz_readonly.ls_zhuyuf" a where exists(select * from sjjc_bz.t_etl_tab_conf g
where g.target_owner='${USER_SJCK}' and g.target_tab=a.NAMESSS);
select count(*) from "sjjc_bz_readonly.ls_zhuyuf" where JOBSSS = '有';

select count(*) from "sjjc_bz_readonly.ls_zhuyuf" a where exists(select * from sjjc_bz.t_ctl_job_list v
where v.flow_id='ETL_SJCK_BZ' and v.job_name=a.NAMESSS);
select count(*) from "sjjc_bz_readonly.ls_zhuyuf" where FLOWSSSS = '有';