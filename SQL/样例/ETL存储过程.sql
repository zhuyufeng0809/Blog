/*
临时表1：LS_SWJC_WFLXAJYFQC_KGZRQ ← 源表：jc_ag_bbcj_swjgpz,wd_yf
临时表2：LS_SWJC_SSJAJYFQC_CB ← SWJC_AJKXMX
临时表3：LS_SWJC_SSJAJYFQC_RK ← SWJC_AJKXMX

目标表：SWJC_SSJAJYFQC
*/
create PROCEDURE P_SJCQ_SWJC_SSJAJYFQC(AVC_BEGIN_TIME IN VARCHAR2,
                                                  AVC_END_TIME   IN VARCHAR2,
                                                  AN_ALL_FLAG    IN NUMBER,
                                                  AVC_BATCH_ID   IN VARCHAR2,
                                                  AVC_SUCC_FLAG  OUT VARCHAR) AS
  ------------------------------------------------------------
  --                   存储过程说明
  --存储过程：P_SJCQ_SWJC_SSJAJYFQC
  --功能描述：完成SWJC_SSJAJYFQC表的抽取
  --创建人：ZXUQ
  --创建日期：2019/2/22
  --版本号：1.0
  --修改日期：2019-05-05
  --修改人：panj
  --修改内容：增加开关账日期判断
  ----------------------------------------------------------

  LN_EXEC_NUM    NUMBER; --执行记录数
  LVC_BATCH_ID   VARCHAR2(20); --批次号
  LVC_JOB_NAME   VARCHAR2(200); --作业名
  LVC_RUN_CODE   VARCHAR2(200); --运行代码
  LVC_RUN_ERRM   VARCHAR2(200); --运行错误
  LVC_JOB_STEP   VARCHAR2(200); --运行步骤
  LVC_RUN_STRING VARCHAR2(14000); --运行字符串
  LVC_BEGIN_DATE DATE;
  --LVC_END_DATE   DATE;

BEGIN

  -------------------------------
  --标示作业名，记录开始作业日志
  ------------------------------
  --如果输入批次号为空，使用序列号SEQ_CTL_BATCH
  IF AVC_BATCH_ID IS NULL THEN
    SELECT SEQ_CTL_BATCH.NEXTVAL INTO LVC_BATCH_ID FROM DUAL;
  ELSE
    LVC_BATCH_ID := AVC_BATCH_ID;
  END IF;
  LVC_JOB_NAME := 'P_SJCQ_SWJC_SSJAJYFQC';
  LVC_JOB_STEP := LVC_JOB_NAME || '：存储过程开始执行';
  PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                             LVC_BATCH_ID,
                             LVC_JOB_STEP,
                             '执行成功',
                             NULL,
                             NULL,
                             NULL,
                             '1');
  --------------------------------
  --初始化配置参数
  --------------------------------
  LVC_JOB_STEP := LVC_JOB_NAME || '：初始化配置参数';
  IF (AN_ALL_FLAG = '1') THEN
    LVC_RUN_STRING := '【全量抽取】';
  ELSE
    LVC_RUN_STRING := '【增量抽取】' || '【' || AVC_BEGIN_TIME || '->' ||
                      AVC_END_TIME || '】';
  END IF;
  PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                             LVC_BATCH_ID,
                             LVC_JOB_STEP,
                             LVC_RUN_STRING,
                             NULL,
                             NULL,
                             NULL,
                             '1');

/*  LVC_BEGIN_DATE := TO_DATE(AVC_BEGIN_TIME, 'YYYY-MM-DD HH24:MI:SS');
  LVC_END_DATE := TO_DATE(AVC_END_TIME, 'YYYY-MM-DD HH24:MI:SS');*/
  --获取开关账日期
  LVC_JOB_STEP   := LVC_JOB_NAME || '：清空临时表-->SJZBQ_BZ.LS_SWJC_WFLXAJYFQC_KGZRQ';
  LVC_RUN_STRING := 'TRUNCATE TABLE SJZBQ_BZ.LS_SWJC_WFLXAJYFQC_KGZRQ';
  EXECUTE IMMEDIATE LVC_RUN_STRING;

  LVC_JOB_STEP := LVC_JOB_NAME || '：插入临时表-->SJZBQ_BZ.LS_SWJC_WFLXAJYFQC_KGZRQ';
  insert into SJZBQ_BZ.LS_SWJC_WFLXAJYFQC_KGZRQ
    (yf_id, yf_dm, kzrq, gzrq, bnkssj, bnjssj)
    select distinct p.yf_id,
                    p.yf_dm,
                    kzrq,
                    gzrq,
                    min(kzrq) over(partition by p.nd_dm) bnkssj,
                    max(gzrq) over(partition by p.nd_dm) bnjssj
      from SJCK_JCAG.jc_ag_bbcj_swjgpz t, sjck_bz.wd_yf p
     where t.bbssq = p.yf_dm
       and t.yxbz = 'Y'
       and t.bb_bm = 'Yb';

  LN_EXEC_NUM := NVL(SQL%ROWCOUNT, 0);
  COMMIT;
  PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                             LVC_BATCH_ID,
                             LVC_JOB_STEP,
                             LVC_RUN_STRING,
                             NULL,
                             NULL,
                             LN_EXEC_NUM,
                             '1');


  --==============================================================================
  --全量处理步骤
  --==============================================================================
  IF AN_ALL_FLAG = '1' THEN
    LVC_JOB_STEP   := LVC_JOB_NAME || '：清空目标表-->SJCK_BZ.SWJC_SSJAJYFQC';
    LVC_RUN_STRING := 'TRUNCATE TABLE SJCK_BZ.SWJC_SSJAJYFQC';
    EXECUTE IMMEDIATE LVC_RUN_STRING;
    LN_EXEC_NUM := NVL(SQL%ROWCOUNT, 0);
    PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                               LVC_BATCH_ID,
                               LVC_JOB_STEP,
                               LVC_RUN_STRING,
                               NULL,
                               NULL,
                               LN_EXEC_NUM,
                               '1');

    for P in (select yf_id, yf_dm, kzrq, gzrq, bnkssj, bnjssj
                from SJZBQ_BZ.LS_SWJC_WFLXAJYFQC_KGZRQ
               where yf_dm <= TO_CHAR(SYSDATE,'YYYYMM') )loop

    --1.查补
    LVC_JOB_STEP   := LVC_JOB_NAME ||
                      '：清空临时表-->SJZBQ_BZ.LS_SWJC_SSJAJYFQC_CB';
    LVC_RUN_STRING := 'TRUNCATE TABLE SJZBQ_BZ.LS_SWJC_SSJAJYFQC_CB';
    EXECUTE IMMEDIATE LVC_RUN_STRING;
    COMMIT;

    LVC_JOB_STEP := LVC_JOB_NAME || '：插入临时表-->SJZBQ_BZ.LS_SWJC_SSJAJYFQC_CB';
    --1.查补
    INSERT INTO SJZBQ_BZ.LS_SWJC_SSJAJYFQC_CB
      (JCAJXXXH,
       CBHRKFSYF_ID,
       SK,
       SK_ZZS,
       SK_XFS,
       SK_YYS,
       SK_QYSDS,
       SK_GRSDS,
       SK_TDZZS,
       SK_QT,
       ZNJ,
       MSWFSD,
       FK,
       QT,
       CKTSFN,
       HJ,
       YJ,
       WSJZNJ)
      SELECT T.JCAJXXXH,
             P.YF_ID CBHRKFSYF_ID,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' THEN
                    T.SE
                   ELSE
                    0
                 END) SK,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10101' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_ZZS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10102' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_XFS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10103' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_YYS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10104' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_QYSDS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10106' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_GRSDS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10113' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_TDZZS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND
                        T.ZSXM_ID NOT IN
                        ('10101', '10102', '10103', '10104', '10106', '10113') THEN
                    T.SE
                   ELSE
                    0
                 END) SK_QT,
             SUM(CASE
                   WHEN T.SZFM_BJ = '2' THEN
                    T.SE
                   ELSE
                    0
                 END) ZNJ,
             SUM(CASE
                   WHEN T.SZFM_BJ = '4' THEN
                    T.SE
                   ELSE
                    0
                 END) MSWFSD,
             SUM(CASE
                   WHEN T.SZFM_BJ = '3' THEN
                    T.SE
                   ELSE
                    0
                 END) FK,
             SUM(CASE
                   WHEN T.SZFM_BJ = '9' THEN
                    T.SE
                   ELSE
                    0
                 END) QT,
             SUM(CASE
                   WHEN T.CKTSFNBZ = 'Y' THEN
                    T.SE
                   ELSE
                    0
                 END) CKTSFN,
             SUM(T.SE) HJ,
             SUM(CASE
                   WHEN T.SKSX_ID = '0205' THEN
                    T.SE
                   ELSE
                    0
                 END) YJ,
             SUM(CASE
                   WHEN T.WSJZNJBZ = 'Y' THEN
                    T.SE
                   ELSE
                    0
                 END) WSJZNJ
        FROM SJCK_BZ.SWJC_AJKXMX T
       WHERE T.YZFSRQ IS NOT NULL
         AND SSJZCAJSKBZ = 'Y'
         AND T.YZFSRQ >= P.KZRQ
         AND T.YZFSRQ < P.GZRQ
       GROUP BY T.JCAJXXXH;

    LN_EXEC_NUM := NVL(SQL%ROWCOUNT, 0);
    COMMIT;
    PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                               LVC_BATCH_ID,
                               LVC_JOB_STEP,
                               '执行成功',
                               NULL,
                               NULL,
                               LN_EXEC_NUM,
                               '1');

    --2.入库
    LVC_JOB_STEP   := LVC_JOB_NAME ||
                      '：清空临时表-->SJZBQ_BZ.LS_SWJC_SSJAJYFQC_RK';
    LVC_RUN_STRING := 'TRUNCATE TABLE SJZBQ_BZ.LS_SWJC_SSJAJYFQC_RK';
    EXECUTE IMMEDIATE LVC_RUN_STRING;
    COMMIT;

    LVC_JOB_STEP := LVC_JOB_NAME || '：插入临时表-->SJZBQ_BZ.LS_SWJC_SSJAJYFQC_RK';
    INSERT INTO SJZBQ_BZ.LS_SWJC_SSJAJYFQC_RK
      (JCAJXXXH,
       CBHRKFSYF_ID,
       JCXGKXZDRKXHRQ,
       SK,
       SK_ZZS,
       SK_XFS,
       SK_YYS,
       SK_QYSDS,
       SK_GRSDS,
       SK_TDZZS,
       SK_QT,
       ZNJ,
       MSWFSD,
       FK,
       QT,
       CKTSFN,
       HJ,
       YJ,
       RKSN,
       WSJZNJ)
      SELECT T.JCAJXXXH,
             P.YF_ID CBHRKFSYF_ID,
             MAX(T.TZHRKRQ) JCXGKXZDRKXHRQ, --跨年度调账的，用TZHRKRQ的话算到上一年去了
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' THEN
                    T.SE
                   ELSE
                    0
                 END) SK,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10101' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_ZZS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10102' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_XFS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10103' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_YYS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10104' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_QYSDS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10106' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_GRSDS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10113' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_TDZZS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND
                        T.ZSXM_ID NOT IN
                        ('10101', '10102', '10103', '10104', '10106', '10113') THEN
                    T.SE
                   ELSE
                    0
                 END) SK_QT,
             SUM(CASE
                   WHEN T.SZFM_BJ = '2' THEN
                    T.SE
                   ELSE
                    0
                 END) ZNJ,
             SUM(CASE
                   WHEN T.SZFM_BJ = '4' THEN
                    T.SE
                   ELSE
                    0
                 END) MSWFSD,
             SUM(CASE
                   WHEN T.SZFM_BJ = '3' THEN
                    T.SE
                   ELSE
                    0
                 END) FK,
             SUM(CASE
                   WHEN T.SZFM_BJ = '9' THEN
                    T.SE
                   ELSE
                    0
                 END) QT,
             SUM(CASE
                   WHEN T.CKTSFNBZ = 'Y' THEN
                    T.SE
                   ELSE
                    0
                 END) CKTSFN,
             SUM(T.SE) HJ,
             SUM(CASE
                   WHEN T.SKSX_ID = '0205' THEN
                    T.SE
                   ELSE
                    0
                 END) YJ,
             SUM(CASE
                   WHEN T.YZFSRQ < TRUNC(T.RKRQ) THEN
                    T.SE
                   ELSE
                    0
                 END) RKSN,
             SUM(CASE
                   WHEN T.WSJZNJBZ = 'Y' THEN
                    T.SE
                   ELSE
                    0
                 END) WSJZNJ
        FROM SJCK_BZ.SWJC_AJKXMX T
       WHERE T.RKRQ IS NOT NULL
         AND SSJZCAJSKBZ = 'Y'
         AND T.RKRQ >= P.KZRQ
         AND T.RKRQ < P.GZRQ
       GROUP BY T.JCAJXXXH, P.YF_ID;

    LN_EXEC_NUM := NVL(SQL%ROWCOUNT, 0);
    COMMIT;
    PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                               LVC_BATCH_ID,
                               LVC_JOB_STEP,
                               '执行成功',
                               NULL,
                               NULL,
                               LN_EXEC_NUM,
                               '1');

    --3、写入正式表
    LVC_JOB_STEP := LVC_JOB_NAME || '：插入目标表-->SJCK_BZ.SWJC_SSJAJYFQC数据';
    INSERT INTO SJCK_BZ.SWJC_SSJAJYFQC
      (JCAYXXXH,
       CBHRKFSYF_ID,
       JCAYBH,
       JCAYMC,
       NSRDZDAH,
       NSRSBH,
       SHXYDM,
       NSRMC,
       SWJG_ID,
       HY_ID,
       AJSZJGSWJG_ID,
       JTYSDXHRQ,
       CBSK,
       CBSK_ZZS,
       CBSK_XFS,
       CBSK_YYS,
       CBSK_QYSDS,
       CBSK_GRSDS,
       CBSK_TDZZS,
       CBSK_QTSZ,
       CBZNJ,
       CBMSWFSD,
       CBFK,
       CBQT,
       CBZE,
       RKSK,
       RKSK_ZZS,
       RKSK_XFS,
       RKSK_YYS,
       RKSK_QYSDS,
       RKSK_GRSDS,
       RKSK_TDZZS,
       RKSK_QTSZ,
       RKZNJ,
       RKMSWFSD,
       RKFK,
       RKQT,
       RKZE,
       YQNDCBRK,
       JCXGKXZDRKXHRQ,
       JDXWSSDXHRQ)
      SELECT JCAYXXXH,
             CBHRKFSYF_ID,
             MAX(JCAYBH) JCAYBH,
             MAX(JCAYMC) JCAYMC,
             MAX(NSRDZDAH) NSRDZDAH,
             MAX(NSRSBH) NSRSBH,
             MAX(SHXYDM) SHXYDM,
             MAX(NSRMC) NSRMC,
             MAX(SWJG_ID) SWJG_ID,
             MAX(HY_ID) HY_ID,
             MAX(AJSZJGSWJG_ID) AJSZJGSWJG_ID,
             MAX(JTYSDXHRQ) JTYSDXHRQ,
             SUM(CBSK) CBSK,
             SUM(CBSK_ZZS) CBSK_ZZS,
             SUM(CBSK_XFS) CBSK_XFS,
             SUM(CBSK_YYS) CBSK_YYS,
             SUM(CBSK_QYSDS) CBSK_QYSDS,
             SUM(CBSK_GRSDS) CBSK_GRSDS,
             SUM(CBSK_TDZZS) CBSK_TDZZS,
             SUM(CBSK_QTSZ) CBSK_QTSZ,
             SUM(CBZNJ) CBZNJ,
             SUM(CBMSWFSD) CBMSWFSD,
             SUM(CBFK) CBFK,
             SUM(CBQT) CBQT,
             SUM(CBZE) CBZE,
             SUM(RKSK) RKSK,
             SUM(RKSK_ZZS) RKSK_ZZS,
             SUM(RKSK_XFS) RKSK_XFS,
             SUM(RKSK_YYS) RKSK_YYS,
             SUM(RKSK_QYSDS) RKSK_QYSDS,
             SUM(RKSK_GRSDS) RKSK_GRSDS,
             SUM(RKSK_TDZZS) RKSK_TDZZS,
             SUM(RKSK_QTSZ) RKSK_QTSZ,
             SUM(RKZNJ) RKZNJ,
             SUM(RKMSWFSD) RKMSWFSD,
             SUM(RKFK) RKFK,
             SUM(RKQT) RKQT,
             SUM(RKZE) RKZE,
             SUM(YQNDCBRK) YQNDCBRK,
             MAX(JCXGKXZDRKXHRQ) JCXGKXZDRKXHRQ,
             MAX(JDXWSSDXHRQ) JDXWSSDXHRQ
        FROM (SELECT SSJ.JCAYXXXH,
                     SK.CBHRKFSYF_ID,
                     SSJ.JCAYBH,
                     NULL JCAYMC,
                     SSJ.NSRDZDAH,
                     SSJ.NSRSBH,
                     SSJ.SHXYDM,
                     SSJ.NSRMC,
                     SSJ.SWJG_ID,
                     SSJ.HY_ID,
                     SSJ.AYSZSWJG_ID AJSZJGSWJG_ID,
                     SSJ.SJCCZCWSSDXHRQ JTYSDXHRQ,
                     NVL(SK.CBSK, 0) CBSK,
                     NVL(SK.CBSK_ZZS, 0) CBSK_ZZS,
                     NVL(SK.CBSK_XFS, 0) CBSK_XFS,
                     NVL(SK.CBSK_YYS, 0) CBSK_YYS,
                     NVL(SK.CBSK_QYSDS, 0) CBSK_QYSDS,
                     NVL(SK.CBSK_GRSDS, 0) CBSK_GRSDS,
                     NVL(SK.CBSK_TDZZS, 0) CBSK_TDZZS,
                     NVL(SK.CBSK_QTSZ, 0) CBSK_QTSZ,
                     NVL(SK.CBZNJ, 0) CBZNJ,
                     NVL(SK.CBMSWFSD, 0) CBMSWFSD,
                     NVL(SK.CBFK, 0) CBFK,
                     NVL(SK.CBQT, 0) CBQT,
                     NVL(SK.CBZE, 0) CBZE,
                     NVL(SK.RKSK, 0) RKSK,
                     NVL(SK.RKSK_ZZS, 0) RKSK_ZZS,
                     NVL(SK.RKSK_XFS, 0) RKSK_XFS,
                     NVL(SK.RKSK_YYS, 0) RKSK_YYS,
                     NVL(SK.RKSK_QYSDS, 0) RKSK_QYSDS,
                     NVL(SK.RKSK_GRSDS, 0) RKSK_GRSDS,
                     NVL(SK.RKSK_TDZZS, 0) RKSK_TDZZS,
                     NVL(SK.RKSK_QTSZ, 0) RKSK_QTSZ,
                     NVL(SK.RKZNJ, 0) RKZNJ,
                     NVL(SK.RKMSWFSD, 0) RKMSWFSD,
                     NVL(SK.RKFK, 0) RKFK,
                     NVL(SK.RKQT, 0) RKQT,
                     NVL(SK.RKZE, 0) RKZE,
                     NVL(SK.RKSN, 0) YQNDCBRK,
                     SK.JCXGKXZDRKXHRQ,
                     NULL JDXWSSDXHRQ
                FROM SJCK_BZ.SWJC_SSJZCAJKZXX SSJ,
                     (SELECT NVL(CB.JCAJXXXH, RK.JCAJXXXH) JCAJXXXH,
                             NVL(CB.CBHRKFSYF_ID, RK.CBHRKFSYF_ID) CBHRKFSYF_ID,
                             RK.JCXGKXZDRKXHRQ,
                             CB.SK CBSK,
                             CB.SK_ZZS CBSK_ZZS,
                             CB.SK_XFS CBSK_XFS,
                             CB.SK_YYS CBSK_YYS,
                             CB.SK_QYSDS CBSK_QYSDS,
                             CB.SK_GRSDS CBSK_GRSDS,
                             CB.SK_TDZZS CBSK_TDZZS,
                             CB.SK_QT CBSK_QTSZ,
                             CB.ZNJ CBZNJ,
                             CB.MSWFSD CBMSWFSD,
                             CB.FK CBFK,
                             CB.QT CBQT,
                             CB.HJ CBZE,
                             RK.SK RKSK,
                             RK.SK_ZZS RKSK_ZZS,
                             RK.SK_XFS RKSK_XFS,
                             RK.SK_YYS RKSK_YYS,
                             RK.SK_QYSDS RKSK_QYSDS,
                             RK.SK_GRSDS RKSK_GRSDS,
                             RK.SK_TDZZS RKSK_TDZZS,
                             RK.SK_QT RKSK_QTSZ,
                             RK.ZNJ RKZNJ,
                             RK.MSWFSD RKMSWFSD,
                             RK.FK RKFK,
                             RK.QT RKQT,
                             RK.HJ RKZE,
                             RK.RKSN
                        FROM SJZBQ_BZ.LS_SWJC_SSJAJYFQC_CB CB
                        FULL JOIN SJZBQ_BZ.LS_SWJC_SSJAJYFQC_RK RK
                          ON CB.JCAJXXXH = RK.JCAJXXXH
                         AND CB.CBHRKFSYF_ID = RK.CBHRKFSYF_ID) SK
               WHERE SSJ.TZSXH = SK.JCAJXXXH
                 AND SSJ.SJCCZCWSSDXHRQ IS NOT NULL)
       GROUP BY JCAYXXXH, CBHRKFSYF_ID;

    LN_EXEC_NUM := NVL(SQL%ROWCOUNT, 0);
    COMMIT;
    PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                               LVC_BATCH_ID,
                               LVC_JOB_STEP,
                               '执行成功',
                               NULL,
                               NULL,
                               LN_EXEC_NUM,
                               '1');
    end loop;

    --==============================================================================
    --增量处理步骤
    --==============================================================================
  ELSE
    LVC_BEGIN_DATE := to_date(AVC_BEGIN_TIME,'yyyy-mm-dd hh24:mi:ss');

    for P in (select yf_id, yf_dm, kzrq, gzrq, bnkssj, bnjssj
                from SJZBQ_BZ.LS_SWJC_WFLXAJYFQC_KGZRQ
              where yf_dm >= to_char(trunc(LVC_BEGIN_DATE,'mm'),'yyyymm')
                and yf_dm <= TO_CHAR(SYSDATE,'YYYYMM'))loop

    --1.查补
    LVC_JOB_STEP   := LVC_JOB_NAME ||
                      '：清空临时表-->SJZBQ_BZ.LS_SWJC_SSJAJYFQC_CB';
    LVC_RUN_STRING := 'TRUNCATE TABLE SJZBQ_BZ.LS_SWJC_SSJAJYFQC_CB';
    EXECUTE IMMEDIATE LVC_RUN_STRING;
    commit;

    LVC_JOB_STEP := LVC_JOB_NAME || '：插入临时表-->SJZBQ_BZ.LS_SWJC_SSJAJYFQC_CB';
    --1.查补
    INSERT INTO SJZBQ_BZ.LS_SWJC_SSJAJYFQC_CB
      (JCAJXXXH,
       CBHRKFSYF_ID,
       SK,
       SK_ZZS,
       SK_XFS,
       SK_YYS,
       SK_QYSDS,
       SK_GRSDS,
       SK_TDZZS,
       SK_QT,
       ZNJ,
       MSWFSD,
       FK,
       QT,
       CKTSFN,
       HJ,
       YJ,
       WSJZNJ)
      SELECT T.JCAJXXXH,
             P.YF_ID CBHRKFSYF_ID,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' THEN
                    T.SE
                   ELSE
                    0
                 END) SK,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10101' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_ZZS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10102' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_XFS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10103' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_YYS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10104' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_QYSDS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10106' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_GRSDS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10113' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_TDZZS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND
                        T.ZSXM_ID NOT IN
                        ('10101', '10102', '10103', '10104', '10106', '10113') THEN
                    T.SE
                   ELSE
                    0
                 END) SK_QT,
             SUM(CASE
                   WHEN T.SZFM_BJ = '2' THEN
                    T.SE
                   ELSE
                    0
                 END) ZNJ,
             SUM(CASE
                   WHEN T.SZFM_BJ = '4' THEN
                    T.SE
                   ELSE
                    0
                 END) MSWFSD,
             SUM(CASE
                   WHEN T.SZFM_BJ = '3' THEN
                    T.SE
                   ELSE
                    0
                 END) FK,
             SUM(CASE
                   WHEN T.SZFM_BJ = '9' THEN
                    T.SE
                   ELSE
                    0
                 END) QT,
             SUM(CASE
                   WHEN T.CKTSFNBZ = 'Y' THEN
                    T.SE
                   ELSE
                    0
                 END) CKTSFN,
             SUM(T.SE) HJ,
             SUM(CASE
                   WHEN T.SKSX_ID = '0205' THEN
                    T.SE
                   ELSE
                    0
                 END) YJ,
             SUM(CASE
                   WHEN T.WSJZNJBZ = 'Y' THEN
                    T.SE
                   ELSE
                    0
                 END) WSJZNJ
        FROM SJCK_BZ.SWJC_AJKXMX T
       WHERE T.YZFSRQ IS NOT NULL
         AND SSJZCAJSKBZ = 'Y'
         AND T.YZFSRQ >= P.KZRQ
         AND T.YZFSRQ < P.GZRQ
       GROUP BY T.JCAJXXXH;

    LN_EXEC_NUM := NVL(SQL%ROWCOUNT, 0);
    COMMIT;
    PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                               LVC_BATCH_ID,
                               LVC_JOB_STEP,
                               '执行成功',
                               NULL,
                               NULL,
                               LN_EXEC_NUM,
                               '1');

    --2.入库
    LVC_JOB_STEP   := LVC_JOB_NAME ||
                      '：清空临时表-->SJZBQ_BZ.LS_SWJC_SSJAJYFQC_RK';
    LVC_RUN_STRING := 'TRUNCATE TABLE SJZBQ_BZ.LS_SWJC_SSJAJYFQC_RK';
    EXECUTE IMMEDIATE LVC_RUN_STRING;
    commit;

    LVC_JOB_STEP := LVC_JOB_NAME || '：插入临时表-->SJZBQ_BZ.LS_SWJC_SSJAJYFQC_RK';
    INSERT INTO SJZBQ_BZ.LS_SWJC_SSJAJYFQC_RK
      (JCAJXXXH,
       CBHRKFSYF_ID,
       JCXGKXZDRKXHRQ,
       SK,
       SK_ZZS,
       SK_XFS,
       SK_YYS,
       SK_QYSDS,
       SK_GRSDS,
       SK_TDZZS,
       SK_QT,
       ZNJ,
       MSWFSD,
       FK,
       QT,
       CKTSFN,
       HJ,
       YJ,
       RKSN,
       WSJZNJ)
      SELECT T.JCAJXXXH,
             P.YF_ID CBHRKFSYF_ID,
             MAX(T.TZHRKRQ) JCXGKXZDRKXHRQ, --跨年度调账的，用TZHRKRQ的话算到上一年去了
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' THEN
                    T.SE
                   ELSE
                    0
                 END) SK,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10101' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_ZZS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10102' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_XFS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10103' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_YYS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10104' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_QYSDS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10106' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_GRSDS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND T.ZSXM_ID = '10113' THEN
                    T.SE
                   ELSE
                    0
                 END) SK_TDZZS,
             SUM(CASE
                   WHEN T.SZFM_BJ = '1' AND
                        T.ZSXM_ID NOT IN
                        ('10101', '10102', '10103', '10104', '10106', '10113') THEN
                    T.SE
                   ELSE
                    0
                 END) SK_QT,
             SUM(CASE
                   WHEN T.SZFM_BJ = '2' THEN
                    T.SE
                   ELSE
                    0
                 END) ZNJ,
             SUM(CASE
                   WHEN T.SZFM_BJ = '4' THEN
                    T.SE
                   ELSE
                    0
                 END) MSWFSD,
             SUM(CASE
                   WHEN T.SZFM_BJ = '3' THEN
                    T.SE
                   ELSE
                    0
                 END) FK,
             SUM(CASE
                   WHEN T.SZFM_BJ = '9' THEN
                    T.SE
                   ELSE
                    0
                 END) QT,
             SUM(CASE
                   WHEN T.CKTSFNBZ = 'Y' THEN
                    T.SE
                   ELSE
                    0
                 END) CKTSFN,
             SUM(T.SE) HJ,
             SUM(CASE
                   WHEN T.SKSX_ID = '0205' THEN
                    T.SE
                   ELSE
                    0
                 END) YJ,
             SUM(CASE
                   WHEN T.YZFSRQ < TRUNC(T.RKRQ) THEN
                    T.SE
                   ELSE
                    0
                 END) RKSN,
             SUM(CASE
                   WHEN T.WSJZNJBZ = 'Y' THEN
                    T.SE
                   ELSE
                    0
                 END) WSJZNJ
        FROM SJCK_BZ.SWJC_AJKXMX T
       WHERE T.RKRQ IS NOT NULL
         AND SSJZCAJSKBZ = 'Y'
         AND T.RKRQ >= P.KZRQ
         AND T.RKRQ < P.GZRQ
       GROUP BY T.JCAJXXXH, P.YF_ID;

    LN_EXEC_NUM := NVL(SQL%ROWCOUNT, 0);
    COMMIT;
    PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                               LVC_BATCH_ID,
                               LVC_JOB_STEP,
                               '执行成功',
                               NULL,
                               NULL,
                               LN_EXEC_NUM,
                               '1');

    --3、写入正式表
    LVC_JOB_STEP   := LVC_JOB_NAME ||
                      '：删除目标表-->SJCK_BZ.SWJC_SSJAJYFQC数据';
    DELETE FROM SJCK_BZ.SWJC_SSJAJYFQC where CBHRKFSYF_ID = p.yf_id;

    LVC_JOB_STEP := LVC_JOB_NAME || '：插入目标表-->SJCK_BZ.SWJC_SSJAJYFQC数据';
    INSERT INTO SJCK_BZ.SWJC_SSJAJYFQC
      (JCAYXXXH,
       CBHRKFSYF_ID,
       JCAYBH,
       JCAYMC,
       NSRDZDAH,
       NSRSBH,
       SHXYDM,
       NSRMC,
       SWJG_ID,
       HY_ID,
       AJSZJGSWJG_ID,
       JTYSDXHRQ,
       CBSK,
       CBSK_ZZS,
       CBSK_XFS,
       CBSK_YYS,
       CBSK_QYSDS,
       CBSK_GRSDS,
       CBSK_TDZZS,
       CBSK_QTSZ,
       CBZNJ,
       CBMSWFSD,
       CBFK,
       CBQT,
       CBZE,
       RKSK,
       RKSK_ZZS,
       RKSK_XFS,
       RKSK_YYS,
       RKSK_QYSDS,
       RKSK_GRSDS,
       RKSK_TDZZS,
       RKSK_QTSZ,
       RKZNJ,
       RKMSWFSD,
       RKFK,
       RKQT,
       RKZE,
       YQNDCBRK,
       JCXGKXZDRKXHRQ,
       JDXWSSDXHRQ)
      SELECT JCAYXXXH,
             CBHRKFSYF_ID,
             MAX(JCAYBH) JCAYBH,
             MAX(JCAYMC) JCAYMC,
             MAX(NSRDZDAH) NSRDZDAH,
             MAX(NSRSBH) NSRSBH,
             MAX(SHXYDM) SHXYDM,
             MAX(NSRMC) NSRMC,
             MAX(SWJG_ID) SWJG_ID,
             MAX(HY_ID) HY_ID,
             MAX(AJSZJGSWJG_ID) AJSZJGSWJG_ID,
             MAX(JTYSDXHRQ) JTYSDXHRQ,
             SUM(CBSK) CBSK,
             SUM(CBSK_ZZS) CBSK_ZZS,
             SUM(CBSK_XFS) CBSK_XFS,
             SUM(CBSK_YYS) CBSK_YYS,
             SUM(CBSK_QYSDS) CBSK_QYSDS,
             SUM(CBSK_GRSDS) CBSK_GRSDS,
             SUM(CBSK_TDZZS) CBSK_TDZZS,
             SUM(CBSK_QTSZ) CBSK_QTSZ,
             SUM(CBZNJ) CBZNJ,
             SUM(CBMSWFSD) CBMSWFSD,
             SUM(CBFK) CBFK,
             SUM(CBQT) CBQT,
             SUM(CBZE) CBZE,
             SUM(RKSK) RKSK,
             SUM(RKSK_ZZS) RKSK_ZZS,
             SUM(RKSK_XFS) RKSK_XFS,
             SUM(RKSK_YYS) RKSK_YYS,
             SUM(RKSK_QYSDS) RKSK_QYSDS,
             SUM(RKSK_GRSDS) RKSK_GRSDS,
             SUM(RKSK_TDZZS) RKSK_TDZZS,
             SUM(RKSK_QTSZ) RKSK_QTSZ,
             SUM(RKZNJ) RKZNJ,
             SUM(RKMSWFSD) RKMSWFSD,
             SUM(RKFK) RKFK,
             SUM(RKQT) RKQT,
             SUM(RKZE) RKZE,
             SUM(YQNDCBRK) YQNDCBRK,
             MAX(JCXGKXZDRKXHRQ) JCXGKXZDRKXHRQ,
             MAX(JDXWSSDXHRQ) JDXWSSDXHRQ
        FROM (SELECT SSJ.JCAYXXXH,
                     SK.CBHRKFSYF_ID,
                     SSJ.JCAYBH,
                     NULL JCAYMC,
                     SSJ.NSRDZDAH,
                     SSJ.NSRSBH,
                     SSJ.SHXYDM,
                     SSJ.NSRMC,
                     SSJ.SWJG_ID,
                     SSJ.HY_ID,
                     SSJ.AYSZSWJG_ID AJSZJGSWJG_ID,
                     SSJ.SJCCZCWSSDXHRQ JTYSDXHRQ,
                     NVL(SK.CBSK, 0) CBSK,
                     NVL(SK.CBSK_ZZS, 0) CBSK_ZZS,
                     NVL(SK.CBSK_XFS, 0) CBSK_XFS,
                     NVL(SK.CBSK_YYS, 0) CBSK_YYS,
                     NVL(SK.CBSK_QYSDS, 0) CBSK_QYSDS,
                     NVL(SK.CBSK_GRSDS, 0) CBSK_GRSDS,
                     NVL(SK.CBSK_TDZZS, 0) CBSK_TDZZS,
                     NVL(SK.CBSK_QTSZ, 0) CBSK_QTSZ,
                     NVL(SK.CBZNJ, 0) CBZNJ,
                     NVL(SK.CBMSWFSD, 0) CBMSWFSD,
                     NVL(SK.CBFK, 0) CBFK,
                     NVL(SK.CBQT, 0) CBQT,
                     NVL(SK.CBZE, 0) CBZE,
                     NVL(SK.RKSK, 0) RKSK,
                     NVL(SK.RKSK_ZZS, 0) RKSK_ZZS,
                     NVL(SK.RKSK_XFS, 0) RKSK_XFS,
                     NVL(SK.RKSK_YYS, 0) RKSK_YYS,
                     NVL(SK.RKSK_QYSDS, 0) RKSK_QYSDS,
                     NVL(SK.RKSK_GRSDS, 0) RKSK_GRSDS,
                     NVL(SK.RKSK_TDZZS, 0) RKSK_TDZZS,
                     NVL(SK.RKSK_QTSZ, 0) RKSK_QTSZ,
                     NVL(SK.RKZNJ, 0) RKZNJ,
                     NVL(SK.RKMSWFSD, 0) RKMSWFSD,
                     NVL(SK.RKFK, 0) RKFK,
                     NVL(SK.RKQT, 0) RKQT,
                     NVL(SK.RKZE, 0) RKZE,
                     NVL(SK.RKSN, 0) YQNDCBRK,
                     SK.JCXGKXZDRKXHRQ,
                     NULL JDXWSSDXHRQ
                FROM SJCK_BZ.SWJC_SSJZCAJKZXX SSJ,
                     (SELECT NVL(CB.JCAJXXXH, RK.JCAJXXXH) JCAJXXXH,
                             NVL(CB.CBHRKFSYF_ID, RK.CBHRKFSYF_ID) CBHRKFSYF_ID,
                             RK.JCXGKXZDRKXHRQ,
                             CB.SK CBSK,
                             CB.SK_ZZS CBSK_ZZS,
                             CB.SK_XFS CBSK_XFS,
                             CB.SK_YYS CBSK_YYS,
                             CB.SK_QYSDS CBSK_QYSDS,
                             CB.SK_GRSDS CBSK_GRSDS,
                             CB.SK_TDZZS CBSK_TDZZS,
                             CB.SK_QT CBSK_QTSZ,
                             CB.ZNJ CBZNJ,
                             CB.MSWFSD CBMSWFSD,
                             CB.FK CBFK,
                             CB.QT CBQT,
                             CB.HJ CBZE,
                             RK.SK RKSK,
                             RK.SK_ZZS RKSK_ZZS,
                             RK.SK_XFS RKSK_XFS,
                             RK.SK_YYS RKSK_YYS,
                             RK.SK_QYSDS RKSK_QYSDS,
                             RK.SK_GRSDS RKSK_GRSDS,
                             RK.SK_TDZZS RKSK_TDZZS,
                             RK.SK_QT RKSK_QTSZ,
                             RK.ZNJ RKZNJ,
                             RK.MSWFSD RKMSWFSD,
                             RK.FK RKFK,
                             RK.QT RKQT,
                             RK.HJ RKZE,
                             RK.RKSN
                        FROM SJZBQ_BZ.LS_SWJC_SSJAJYFQC_CB CB
                        FULL JOIN SJZBQ_BZ.LS_SWJC_SSJAJYFQC_RK RK
                          ON CB.JCAJXXXH = RK.JCAJXXXH
                         AND CB.CBHRKFSYF_ID = RK.CBHRKFSYF_ID) SK
               WHERE SSJ.TZSXH = SK.JCAJXXXH
                 AND SSJ.SJCCZCWSSDXHRQ IS NOT NULL)
       GROUP BY JCAYXXXH, CBHRKFSYF_ID;

    LN_EXEC_NUM := NVL(SQL%ROWCOUNT, 0);
    COMMIT;
    PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                               LVC_BATCH_ID,
                               LVC_JOB_STEP,
                               '执行成功',
                               NULL,
                               NULL,
                               LN_EXEC_NUM,
                               '1');
    end loop;

  END IF;

  --==============================================================================
  --记录ETL成功结束的信息，并返回作业成功标志
  --==============================================================================
  LVC_JOB_STEP := LVC_JOB_NAME || '：存储过程执行结束';
  COMMIT;
  AVC_SUCC_FLAG := '1'; --返回成功标志位
  PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                             LVC_BATCH_ID,
                             LVC_JOB_STEP,
                             '执行成功',
                             NULL,
                             NULL,
                             NULL,
                             '1');

  --==============================================================================
  --记录错误信息及修改，并返回作业失败标志
  --==============================================================================
EXCEPTION
  WHEN OTHERS THEN
    LVC_JOB_STEP  := LVC_JOB_NAME || '：存储过程异常结束';
    LVC_RUN_CODE  := SQLCODE;
    LVC_RUN_ERRM  := SQLERRM;
    AVC_SUCC_FLAG := '0';
    PKG_CTL_LOG.P_CTL_LOG_SETP(LVC_JOB_NAME,
                               LVC_BATCH_ID,
                               LVC_JOB_STEP,
                               LVC_RUN_STRING,
                               LVC_RUN_CODE,
                               LVC_RUN_ERRM,
                               NULL,
                               AVC_SUCC_FLAG);

END;
/

