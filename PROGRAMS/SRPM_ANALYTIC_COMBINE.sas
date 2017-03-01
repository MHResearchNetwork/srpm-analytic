*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_COMBINE.sas                                       *;
*   Purpose:  Combine all temporary data sets into final analytic data set.   *;
*******************************************************************************;
options nomprint;

%macro combine;
  %if %sysfunc(exist(SHARE.SRPM_ANALYTIC_SITE&_SITECODE)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'SHARE'
        and upcase(memname) = "SRPM_ANALYTIC_SITE&_SITECODE"
      ;
    quit;

    %put WARNING: Data set SHARE.SRPM_ANALYTIC_SITE&_SITECODE already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(TEMP.INDEX_VISIT)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.INDEX_VISIT does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.DEMOG)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.DEMOG does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.CENSUS)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.CENSUS does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.ENR_INDEX)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.ENR_INDEX does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.ENR_PRE)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.ENR_PRE does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.CENSOR)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.CENSOR does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.CHARLSON)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.CHARLSON does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.MH_DX)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.MH_DX does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.MH_RX)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.MH_RX does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.MH_UTE)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.MH_UTE does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.SII_PRE)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.SII_PRE does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.ITEM9_INDEX)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.ITEM9_INDEX does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.ITEM18_INDEX)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.ITEM18_INDEX does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.ITEM9_PRE)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.ITEM9_PRE does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.ATT_POST)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.ATT_POST does not exist.;
    %end;
    %else %if %sysfunc(exist(TEMP.DEATHS)) = 0 %then %do;
      %put ERROR: Data set TEMP.SRPM_ANALYTIC_SITE&_SITECODE cannot be created!;
      %put ERROR: Required input data set TEMP.DEATHS does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql;
        create table share.srpm_analytic_site&_sitecode as
        select
            "&_sitecode" as site 
            label="MHRN site code"
          , iv.visit_year           
            label="Index visit year"
          , iv.person_id            
            label="Random person ID (1st 2 digits = site)"
          , iv.visit_seq            
            label="Visit sequence number for each person"
          , iv.days_since_visit1    
            label="Days since first index visit for each person"
          , iv.visit_type
            label="Visit type (PC/MH)"
          , iv.age                  
            label="Age at index visit"
          , dem.gender as sex              
            label="Sex"
          , dem.race1               
            label="Race 1"
          , dem.race2               
            label="Race 2"
          , dem.hispanic            
            label="Hispanic ethnicity"
          , case
              when u.medhousincome < 25000
                and u.medhousincome ne . then 1
              when u.medhousincome >= 25000 then 0
              else .
            end as hhld_inc_lt25k   
            length=3
            label="Median household income <$25K (1/0)"
          , case
              when u.medhousincome < 40000
                and u.medhousincome ne . then 1
              when u.medhousincome >= 40000 then 0
              else .
            end as hhld_inc_lt40k   
            length=3
            label="Median household income <$40K (1/0)"
          , case
              when (u.education6 + u.education7 + u.education8) < .25
                and (u.education6 + u.education7 + u.education8) ne .
                then 1
              when (u.education6 + u.education7 + u.education8) >= .25
                then 0
              else .
            end as coll_deg_lt25p   
            length=3                                    
            label="Neighborhood <25% college-educated (1/0)"
          , ei.enr_index            
            label="Enrolled at index (1/0)"
          , case
              when epre.enr_pre_start ne .
                then ei.visit_date - epre.enr_pre_start
              else .
            end as enr_pre_days     
            label="Days of continuous pre-index enrollment"
          , case
              when o.censor_att_date ne .
                then o.censor_att_date - ei.visit_date
              else .
            end as censor_att_days  
            label="Days to attempt censoring"
          , case
              when o.censor_dth_date ne .
                then o.censor_dth_date - ei.visit_date
              else .
            end as censor_dth_days  
            label="Days to death censoring"
          , ei.ins_medicaid         
            label="Medicaid insurance coverage at index (VDW)"
          , ei.ins_commercial       
            label="Commercial insurance coverage at index (VDW)"
          , ei.ins_privatepay       
            label="Private pay insurance coverage at index (VDW)"
          , ei.ins_statesubsidized  
            label="State-subsidized insurance coverage at index (VDW)"
          , ei.ins_selffunded       
            label="Self-funded insurance coverage at index (VDW)"
          , ei.ins_medicare         
            label="Medicare insurance coverage at index (VDW)"
          , ei.ins_other            
            label="Other insurance coverage at index (VDW)"
          , ei.ins_highdeductible   
            label="High-deductible insurance coverage at index (VDW)"
          , ch.charlson_score       
            label="Charlson score"    
          , ch.charlson_mi
            label="Myocardial infarction (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_chd
            label="Congestive heart disease (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_pvd
            label="Periphersal vascular disorder (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_cvd
            label="Cerebrovascular disease (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_dem
            label="Dementia (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_cpd
            label="Chronic pulmonary disease (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_rhd
            label="Rheumatologic disease (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_pud
            label="Peptic ulcer disease (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_mlivd
            label="Mild liver disease (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_diab
            label="Diabetes (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_diabc
            label="Diabetes with chronic complications (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_plegia
            label="Hemiplegia or paraplegia (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_ren
            label="Renal disease (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_malign
            label="Malignancy, including leukemia/lymphoma (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_slivd
            label="Moderate or severe liver disease (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_mst
            label="Metastatic solid tumor (Charlson) in 1y pre-index (1/0)"
          , ch.charlson_aids
            label="AIDS (Charlson) in 1y pre-index (1/0)"
          , coalesce(mhdx.dep_dx_index, 0) as dep_dx_index
            label="Depression Dx at index (1/0)"
          , coalesce(mhdx.dep_dx_pre1y, 0) as dep_dx_pre1y      
            label="Depression Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.dep_dx_pre5y, 0) as dep_dx_pre5y       
            label="Depression Dx >1y to <5y pre-index (1/0)"
          , coalesce(mhdx.anx_dx_index, 0) as anx_dx_index       
            label="Anxiety Dx at index (1/0)"
          , coalesce(mhdx.anx_dx_pre1y, 0) as anx_dx_pre1y       
            label="Anxiety Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.anx_dx_pre5y, 0) as anx_dx_pre5y       
            label="Anxiety Dx >1y to <5y pre-index (1/0)"
          , coalesce(mhdx.bip_dx_index, 0) as bip_dx_index      
            label="Bipolar Dx at index (1/0)"
          , coalesce(mhdx.bip_dx_pre1y, 0) as bip_dx_pre1y        
            label="Bipolar Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.bip_dx_pre5y, 0) as bip_dx_pre5y       
            label="Bipolar Dx >1y to <5y pre-index (1/0)"
          , coalesce(mhdx.sch_dx_index, 0) as sch_dx_index       
            label="Schizophrenia Dx at index (1/0)"
          , coalesce(mhdx.sch_dx_pre1y, 0) as sch_dx_pre1y       
            label="Schizophrenia Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.sch_dx_pre5y, 0) as sch_dx_pre5y       
            label="Schizophrenia Dx >1y to <5y pre-index (1/0)"
          , coalesce(mhdx.oth_dx_index, 0) as oth_dx_index       
            label="Other psychosis Dx at index (1/0)"
          , coalesce(mhdx.oth_dx_pre1y, 0) as oth_dx_pre1y       
            label="Other psychosis Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.oth_dx_pre5y, 0) as oth_dx_pre5y       
            label="Other psychosis Dx >1y to <5y pre-index (1/0)"
          , coalesce(mhdx.dem_dx_index, 0) as dem_dx_index       
            label="Dementia Dx at index (1/0)"
          , coalesce(mhdx.dem_dx_pre1y, 0) as dem_dx_pre1y       
            label="Dementia Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.dem_dx_pre5y, 0) as dem_dx_pre5y       
            label="Dementia Dx >1y to <5y pre-index (1/0)"
          , coalesce(mhdx.add_dx_index, 0) as add_dx_index       
            label="ADD Dx at index (1/0)"
          , coalesce(mhdx.add_dx_pre1y, 0) as add_dx_pre1y       
            label="ADD Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.add_dx_pre5y, 0) as add_dx_pre5y       
            label="ADD Dx >1y to <5y pre-index (1/0)"
          , coalesce(mhdx.asd_dx_index, 0) as asd_dx_index       
            label="ASD Dx at index (1/0)"
          , coalesce(mhdx.asd_dx_pre1y, 0) as asd_dx_pre1y       
            label="ASD Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.asd_dx_pre5y, 0) as asd_dx_pre5y        
            label="ASD Dx >1y to <5y pre-index (1/0)"    
          , coalesce(mhdx.per_dx_index, 0) as per_dx_index       
            label="Personality disorder Dx at index (1/0)"
          , coalesce(mhdx.per_dx_pre1y, 0) as per_dx_pre1y       
            label="Personality disorder Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.per_dx_pre5y, 0) as per_dx_pre5y       
            label="Personality disorder Dx >1y to <5y pre-index (1/0)"    
          , coalesce(mhdx.alc_dx_index, 0) as alc_dx_index       
            label="Alcohol use disorder Dx at index (1/0)"
          , coalesce(mhdx.alc_dx_pre1y, 0) as alc_dx_pre1y       
            label="Alcohol use disorder Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.alc_dx_pre5y, 0) as alc_dx_pre5y       
            label="Alcohol use disorder Dx >1y to <5y pre-index (1/0)"    
          , coalesce(mhdx.dru_dx_index, 0) as dru_dx_index       
            label="Drug use disorder Dx at index (1/0)"
          , coalesce(mhdx.dru_dx_pre1y, 0) as dru_dx_pre1y       
            label="Drug use disorder Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.dru_dx_pre5y, 0) as dru_dx_pre5y       
            label="Drug use disorder Dx >1y to <5y pre-index (1/0)"    
          , coalesce(mhdx.pts_dx_index, 0) as pts_dx_index       
            label="PTSD Dx at index (1/0)"
          , coalesce(mhdx.pts_dx_pre1y, 0) as pts_dx_pre1y       
            label="PTSD Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.pts_dx_pre5y, 0) as pts_dx_pre5y       
            label="PTSD Dx >1y to <5y pre-index (1/0)"    
          , coalesce(mhdx.eat_dx_index, 0) as eat_dx_index        
            label="Eating disorder Dx at index (1/0)"
          , coalesce(mhdx.eat_dx_pre1y, 0) as eat_dx_pre1y       
            label="Eating disorder Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.eat_dx_pre5y, 0) as eat_dx_pre5y       
            label="Eating disorder Dx >1y to <5y pre-index (1/0)"    
          , coalesce(mhdx.tbi_dx_index, 0) as tbi_dx_index       
            label="TBI Dx at index (1/0)"
          , coalesce(mhdx.tbi_dx_pre1y, 0) as tbi_dx_pre1y       
            label="TBI Dx in 12m pre-index (1/0)"
          , coalesce(mhdx.tbi_dx_pre5y, 0) as tbi_dx_pre5y       
            label="TBI Dx >1y to <5y pre-index (1/0)"    
          , del.del_post_1_90       
            label="Delivery Px 1d to 90d post-index (1/0/-1)"
          , del.del_post_91_180     
            label="Delivery Px 91d to 180d post-index (1/0/-1)"
          , del.del_post_181_280    
            label="Delivery Px 181d to 280d post-index (1/0/-1)"
          , del.del_pre_1_90        
            label="Delivery Px 1d to 90d pre-index (1/0)"
          , del.del_pre_91_180      
            label="Delivery Px 91d to 180d pre-index (1/0)"
          , del.del_pre_181_365     
            label="Delivery Px 181d to 365d pre-index (1/0)"
          , coalesce(mhrx.antidep_rx_pre3m, 0) as antidep_rx_pre3m   
            label="Antidepressant Rx fill in 90d pre-index (1/0)"
          , coalesce(mhrx.antidep_rx_pre1y, 0) as antidep_rx_pre1y   
            label="Antidepressant Rx fill >3m to 1y pre-index (1/0)"
          , coalesce(mhrx.antidep_rx_pre5y, 0) as antidep_rx_pre5y   
            label="Antidepressant Rx fill >1y to <5y pre-index (1/0)"
          , coalesce(mhrx.benzo_rx_pre3m, 0) as benzo_rx_pre3m    
            label="Benzodiazepine Rx fill in 90d pre-index (1/0)"
          , coalesce(mhrx.benzo_rx_pre1y, 0) as benzo_rx_pre1y     
            label="Benzodiazepine Rx fill >3m to 1y pre-index (1/0)"
          , coalesce(mhrx.benzo_rx_pre5y, 0) as benzo_rx_pre5y     
            label="Benzodiazepine Rx fill >1y to <5y pre-index (1/0)"
          , coalesce(mhrx.hypno_rx_pre3m, 0) as hypno_rx_pre3m    
            label="Hypnotic Rx fill in 90d pre-index (1/0)"
          , coalesce(mhrx.hypno_rx_pre1y, 0) as hypno_rx_pre1y    
            label="Hypnotic Rx fill >3m to 1y pre-index (1/0)"
          , coalesce(mhrx.hypno_rx_pre5y, 0) as hypno_rx_pre5y    
            label="Hypnotic Rx fill >1y to <5y pre-index (1/0)"
          , coalesce(mhrx.sga_rx_pre3m, 0) as sga_rx_pre3m      
            label="SGA Rx fill in 90d pre-index (1/0)"
          , coalesce(mhrx.sga_rx_pre1y, 0) as sga_rx_pre1y      
            label="SGA Rx fill >3m to 1y pre-index (1/0)"
          , coalesce(mhrx.sga_rx_pre5y, 0) as sga_rx_pre5y       
            label="SGA Rx fill >1y to <5y pre-index (1/0)"
          , coalesce(mhute.mh_ip_pre3m, 0) as mh_ip_pre3m      
            label="IP encounter with MH Dx in 90d pre-index (1/0)"
          , coalesce(mhute.mh_ip_pre1y, 0) as mh_ip_pre1y       
            label="IP encounter with MH Dx >3m to 1y pre-index (1/0)"
          , coalesce(mhute.mh_ip_pre5y, 0) as mh_ip_pre5y       
            label="IP encounter with MH Dx >1y to <5y pre-index (1/0)"
          , coalesce(mhute.mh_op_pre3m, 0) as mh_op_pre3m       
            label="OP MH specialty encounter in 90d pre-index (1/0)"
          , coalesce(mhute.mh_op_pre1y, 0) as mh_op_pre1y       
            label="OP MH specialty encounter >3m to 1y pre-index (1/0)"
          , coalesce(mhute.mh_op_pre5y, 0) as mh_op_pre5y      
            label="OP MH specialty encounter >1y to <5y pre-index (1/0)"
          , coalesce(mhute.mh_ed_pre3m, 0) as mh_ed_pre3m       
            label="ED encounter with MH Dx in 90d pre-index (1/0)"
          , coalesce(mhute.mh_ed_pre1y, 0) as mh_ed_pre1y       
            label="ED encounter with MH Dx >3m to 1y pre-index (1/0)"
          , coalesce(mhute.mh_ed_pre5y, 0) as mh_ed_pre5y       
            label="ED encounter with MH Dx >1y to <5y pre-index (1/0)"
          , coalesce(sii.any_sui_att_pre3m, 0) as any_sui_att_pre3m   
            label="Any suicide attempt in 90d pre-index (1/0)"
          , coalesce(sii.any_sui_att_pre1y, 0) as any_sui_att_pre1y   
            label="Any suicide attempt >3m to 1y pre-index (1/0)"
          , coalesce(sii.any_sui_att_pre5y, 0) as any_sui_att_pre5y   
            label="Any suicide attempt >1y to <5y pre-index (1/0)"
          , coalesce(sii.lvi_sui_att_pre3m, 0) as lvi_sui_att_pre3m   
            label="Laceration suicide attempt in 90d pre-index (1/0)"
          , coalesce(sii.lvi_sui_att_pre1y, 0) as lvi_sui_att_pre1y  
            label="Laceration suicide attempt >3m to 1y pre-index (1/0)"
          , coalesce(sii.lvi_sui_att_pre5y, 0) as lvi_sui_att_pre5y   
            label="Laceration suicide attempt >1y to <5y pre-index (1/0)"
          , coalesce(sii.ovi_sui_att_pre3m, 0) as ovi_sui_att_pre3m   
            label="Other violent suicide attempt in 90d pre-index (1/0)"
          , coalesce(sii.ovi_sui_att_pre1y, 0) as ovi_sui_att_pre1y   
            label="Other violent suicide attempt >3m to 1y pre-index (1/0)"
          , coalesce(sii.ovi_sui_att_pre5y, 0) as ovi_sui_att_pre5y  
            label="Other violent suicide attempt >1y to <5y pre-index (1/0)"
          , coalesce(sii.any_inj_poi_pre3m, 0) as any_inj_poi_pre3m   
            label="Any injury/poisoning Dx in 90d pre-index (1/0)"
          , coalesce(sii.any_inj_poi_pre1y, 0) as any_inj_poi_pre1y   
            label="Any injury/poisoning Dx >3m to 1y pre-index (1/0)"
          , coalesce(sii.any_inj_poi_pre5y, 0) as any_inj_poi_pre5y   
            label="Any injury/posioning Dx >1y to <5y pre-index (1/0)"
          , . as phq_index_items 
            length=8
            label="Number of PHQ items recorded at index"
          , coalesce(i9i.item9_index_avail, 0) as item9_index_avail
            label="PHQ item 9 recorded at index visit (1/0)"
          , i18.item1_index_score   
            label="PHQ item 1 score on index visit date"
          , i18.item2_index_score   
            label="PHQ item 2 score on index visit date"
          , i18.item3_index_score   
            label="PHQ item 3 score on index visit date"
          , i18.item4_index_score   
            label="PHQ item 4 score on index visit date"
          , i18.item5_index_score   
            label="PHQ item 5 score on index visit date"
          , i18.item6_index_score   
            label="PHQ item 6 score on index visit date"
          , i18.item7_index_score   
            label="PHQ item 7 score on index visit date"
          , i18.item8_index_score   
            label="PHQ item 8 score on index visit date"
          , i9i.item9_index_score   
            label="PHQ item 9 score at index visit"
          , . as phq9_index_score 
            length=8  
            label="PHQ-9 Score"
          , . as phq8_index_score
            length=8
            label="PHQ-8 Score"
          , i9p.item9_pre_days1       
            label="Days since last PHQ item 9 score"
          , i9p.item9_pre_score1      
            label="Last PHQ item 9 score"
          , i9p.item9_pre_days2       
            label="Days since second-to-last PHQ item 9 score"
          , i9p.item9_pre_score2      
            label="Second-to-last PHQ item 9 score"
          , i9p.item9_pre_days3      
            label="Days since third-to-last PHQ item 9 score"
          , i9p.item9_pre_score3      
            label="Third-to-last PHQ item 9 score"
          , coalesce(att.op_nvi_att_post, 0) as op_nvi_att_post
            label="Any OP non-violent suicide attempt (1/0)"
          , att.op_nvi_att_date - iv.visit_date as op_nvi_att_days
            label="Days to OP non-violent suicide attempt"
          , coalesce(att.op_lvi_att_post, 0) as op_lvi_att_post
            label="Any OP laceration suicide attempt (1/0)"
          , att.op_lvi_att_date - iv.visit_date as op_lvi_att_days
            label="Days to OP laceration suicide attempt"
          , coalesce(att.op_ovi_att_post, 0) as op_ovi_att_post
            label="Any OP other violent suicide attempt (1/0)"
          , att.op_ovi_att_date - iv.visit_date as op_ovi_att_days
            label="Days to OP other violent suicide attempt"
          , coalesce(att.op_attempt_post, 0) as op_attempt_post
            label="Any OP suicide attempt (1/0)"
          , att.op_attempt_date - iv.visit_date as op_attempt_days
            label="Days to any OP suicide attempt"
          , coalesce(att.ip_nvi_att_post, 0) as ip_nvi_att_post
            label="Any IP non-violent suicide attempt (1/0)"
          , att.ip_nvi_att_date - iv.visit_date as ip_nvi_att_days
            label="Days to IP non-violent suicide attempt"
          , coalesce(att.ip_lvi_att_post, 0) as ip_lvi_att_post
            label="Any IP laceration suicide attempt (1/0)"
          , att.ip_lvi_att_date - iv.visit_date as ip_lvi_att_days
            label="Days to IP laceration suicide attempt"
          , coalesce(att.ip_ovi_att_post, 0) as ip_ovi_att_post
            label="Any IP other violent suicide attempt (1/0)"
          , att.ip_ovi_att_date - iv.visit_date as ip_ovi_att_days
            label="Days to IP other violent suicide attempt"
          , coalesce(att.ip_attempt_post, 0) as ip_attempt_post
            label="Any IP suicide attempt (1/0)"
          , att.ip_attempt_date - iv.visit_date as ip_attempt_days
            label="Days to any IP suicide attempt"
          , coalesce(att.any_nvi_att_post, 0) as any_nvi_att_post
            label="Any non-violent suicide attempt (1/0)"
          , att.any_nvi_att_date - iv.visit_date as any_nvi_att_days
            label="Days to any non-violent suicide attempt"
          , coalesce(att.any_lvi_att_post, 0) as any_lvi_att_post
            label="Any laceration suicide attempt (1/0)"
          , att.any_lvi_att_date - iv.visit_date as any_lvi_att_days
            label="Days to laceration suicide attempt"
          , coalesce(att.any_ovi_att_post, 0) as any_ovi_att_post
            label="Any other violent suicide attempt (1/0)"
          , att.any_ovi_att_date - iv.visit_date as any_ovi_att_days
            label="Days to other violent suicide attempt"
          , coalesce(att.any_attempt_post, 0) as any_attempt_post
            label="Any suicide attempt (1/0)"
          , att.any_attempt_date - iv.visit_date as any_attempt_days
            label="Days to any suicide attempt"
          , case 
              when dth.death_type = 3 then 1
              else 0
            end as lvi_sui_dth_flag
            label="Laceration suicide death (1/0)"
          , case 
              when dth.death_type = 3 then dth.death_date - iv.visit_date
              else .
            end as lvi_sui_dth_days
            label="Days to laceration suicide death"
          , case
              when dth.death_type = 4 then 1
              else 0
            end as ovi_sui_dth_flag
            label="Other violent suicide death (1/0)"
          , case
              when dth.death_type = 4 then dth.death_date - iv.visit_date
              else .
            end as ovi_sui_dth_days
            label="Days to other violent suicide death"
          , case
              when dth.death_type = 2 then 1
              else 0
            end as nvi_sui_dth_flag
            label="Non-violent suicide death (1/0)"
          , case
              when dth.death_type = 2 then dth.death_date - iv.visit_date
              else .
            end as nvi_sui_dth_days
            label="Days to non-violent suicide death"
          , case
              when dth.death_type >= 2 then 1
              else 0
            end as any_sui_dth_flag
            label="Any suicide death (1/0)"
          , case
              when dth.death_type >= 2 then dth.death_date - iv.visit_date
              else .
            end as any_sui_dth_days
            label="Days to any suicide death"
        from temp.index_visit as iv
          left join temp.demog as dem
            on iv.mrn = dem.mrn
          left join temp.census as u
            on iv.mrn = u.mrn and iv.visit_date = u.visit_date
          left join temp.enr_index as ei
            on iv.mrn = ei.mrn and iv.visit_date = ei.visit_date
          left join temp.enr_pre as epre
            on iv.mrn = epre.mrn and iv.visit_date = epre.visit_date
          left join temp.censor as o
            on iv.mrn = o.mrn and iv.visit_date = o.visit_date
          left join temp.charlson as ch
            on iv.mrn = ch.mrn and iv.visit_date = ch.visit_date
          left join temp.mh_dx as mhdx
            on iv.mrn = mhdx.mrn and iv.visit_date = mhdx.visit_date
          left join temp.delivery as del
            on iv.mrn = del.mrn and iv.visit_date = del.visit_date
          left join temp.mh_rx as mhrx
            on iv.mrn = mhrx.mrn and iv.visit_date = mhrx.visit_date
          left join temp.mh_ute as mhute
            on iv.mrn = mhute.mrn and iv.visit_date = mhute.visit_date
          left join temp.sii_pre as sii
            on iv.mrn = sii.mrn and iv.visit_date = sii.visit_date
          left join temp.item9_index as i9i
            on iv.enc_id = i9i.enc_id
          left join temp.item18_index as i18
            on iv.mrn = i18.mrn and iv.visit_date = i18.visit_date
          left join temp.item9_pre as i9p
            on iv.mrn = i9p.mrn and iv.visit_date = i9p.visit_date
          left join temp.att_post as att
            on iv.mrn = att.mrn and iv.visit_date = att.visit_date
          left join temp.deaths as dth
            on iv.mrn = dth.mrn and iv.visit_date = dth.visit_date
        ;
      quit;

      %let dsid = %sysfunc(open(share.srpm_analytic_site&_sitecode)); 

      %let num = %sysfunc(attrn(&dsid, nvars)); 
  
      data share.srpm_analytic_site&_sitecode; 
        set share.srpm_analytic_site&_sitecode (rename=( 
          %do i = 1 %to &num; 
            %let var&i = %sysfunc(varname(&dsid, &i));
            &&var&i = %sysfunc(lowcase(&&var&i))
          %end;
          ))
        ; 
        %let close = %sysfunc(close(&dsid)); 
        phq_index_items = n(item1_index_score, item2_index_score,
          item3_index_score, item4_index_score, item5_index_score,
          item6_index_score, item7_index_score, item8_index_score,
          item9_index_score)
        ;
        phq9_index_score = sum(item1_index_score, item2_index_score,
          item3_index_score, item4_index_score, item5_index_score,
          item6_index_score, item7_index_score, item8_index_score,
          item9_index_score)
        ;
        phq8_index_score = sum(item1_index_score, item2_index_score,
          item3_index_score, item4_index_score, item5_index_score,
          item6_index_score, item7_index_score, item8_index_score)
        ;
      run;

      options nomprint;
    %end;
%mend combine;

%combine

ods listing close;

ods html file="&root/LOCAL/SRPM_ANALYTIC_SITE&_SITECODE..html" 
  (title="SRPM_ANALYTIC_SITE&_SITECODE PROC CONTENTS") style=sasweb
;

proc contents data=SHARE.SRPM_ANALYTIC_SITE&_SITECODE varnum;
run;

ods html close;

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
