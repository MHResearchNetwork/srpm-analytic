*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_SUMMARY.sas                                       *;
*   Purpose:  Generate descriptive statistics about final analytic data set.  *;
*******************************************************************************;

options nomprint;

%macro summary;
  %if %sysfunc(exist(SHARE.SRPM_ANALYTIC_SITE&_SITECODE)) = 0 %then %do;
    %put ERROR: Data set SHARE.SRPM_ANALYTIC_SITE&_SITECODE does not exist!;
  %end;
    %else %do;
      options mprint;

      proc format;
        value age
          13-17 = '13 to 17'
          18-29 = '18 to 29'
          30-44 = '30 to 44'
          45-64 = '45 to 64'
          65-high = '65+'
        ;
        value charlson
          1 = '1'
          2 = '2'
          3 = '3'
          4 = '4'
          5-high = '5+'
        ;
      run;

      ods listing close;

      ods tagsets.ExcelXP
        file="&root/LOCAL/SRPM_ANALYTIC_SITE&_SITECODE..xml"
        style=minimal
      ;

      ods tagsets.ExcelXP
        options(
          absolute_column_width='35,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6'
          autofit_height='yes'
          embedded_footnotes='yes'
          embedded_titles='yes'
          frozen_headers='5'
          frozen_rowheaders='1'
          merge_titles_footnotes='yes'
          orientation='landscape'
          pages_fitwidth='1'
          pages_fitheight='100'
          sheet_interval='none'
          sheet_name="CATEGORICAL"
        )
      ;

      proc tabulate data=SHARE.SRPM_ANALYTIC_SITE&_SITECODE missing;
        title "SRPM_ANALYTIC_SITE&_SITECODE: Categorical Variable Summary";
        class 
          visit_year
          visit_type
          age
          sex
          race1
          race2
          hispanic
          hhld_inc_lt25k
          hhld_inc_lt40k
          coll_deg_lt25p
          enr_index
          ins_medicaid
          ins_commercial
          ins_privatepay
          ins_statesubsidized
          ins_selffunded
          ins_medicare
          ins_other
          ins_highdeductible
          charlson_score
          charlson_mi
          charlson_chd
          charlson_pvd
          charlson_cvd
          charlson_dem
          charlson_cpd
          charlson_rhd
          charlson_pud
          charlson_mlivd
          charlson_diab
          charlson_diabc
          charlson_plegia
          charlson_ren
          charlson_malign
          charlson_slivd
          charlson_mst
          charlson_aids
          dep_dx_index
          dep_dx_pre1y
          dep_dx_pre5y
          anx_dx_index
          anx_dx_pre1y
          anx_dx_pre5y
          bip_dx_index
          bip_dx_pre1y
          bip_dx_pre5y
          sch_dx_index
          sch_dx_pre1y
          sch_dx_pre5y
          oth_dx_index
          oth_dx_pre1y
          oth_dx_pre5y
          dem_dx_index
          dem_dx_pre1y
          dem_dx_pre5y
          add_dx_index
          add_dx_pre1y
          add_dx_pre5y
          asd_dx_index
          asd_dx_pre1y
          asd_dx_pre5y
          per_dx_index
          per_dx_pre1y
          per_dx_pre5y
          alc_dx_index
          alc_dx_pre1y
          alc_dx_pre5y
          dru_dx_index
          dru_dx_pre1y
          dru_dx_pre5y
          pts_dx_index
          pts_dx_pre1y
          pts_dx_pre5y
          eat_dx_index
          eat_dx_pre1y
          eat_dx_pre5y
          tbi_dx_index
          tbi_dx_pre1y
          tbi_dx_pre5y
          del_post_1_90
          del_post_91_180
          del_post_181_280
          del_pre_1_90
          del_pre_91_180
          del_pre_181_365
          antidep_rx_pre3m
          antidep_rx_pre1y
          antidep_rx_pre5y
          benzo_rx_pre3m
          benzo_rx_pre1y
          benzo_rx_pre5y
          hypno_rx_pre3m
          hypno_rx_pre1y
          hypno_rx_pre5y
          sga_rx_pre3m
          sga_rx_pre1y
          sga_rx_pre5y
          mh_ip_pre3m
          mh_ip_pre1y
          mh_ip_pre5y
          mh_op_pre3m
          mh_op_pre1y
          mh_op_pre5y
          mh_ed_pre3m
          mh_ed_pre1y
          mh_ed_pre5y
          any_sui_att_pre3m
          any_sui_att_pre1y
          any_sui_att_pre5y
          lvi_sui_att_pre3m
          lvi_sui_att_pre1y
          lvi_sui_att_pre5y
          ovi_sui_att_pre3m
          ovi_sui_att_pre1y
          ovi_sui_att_pre5y
          any_inj_poi_pre3m
          any_inj_poi_pre1y
          any_inj_poi_pre5y
          phq_index_items
          item9_index_avail
          item1_index_score
          item2_index_score
          item3_index_score
          item4_index_score
          item5_index_score
          item6_index_score
          item7_index_score
          item8_index_score
          item9_index_score
          phq9_index_score
          phq8_index_score
          item9_pre_score1
          item9_pre_score2
          item9_pre_score3
          op_nvi_att_post
          op_lvi_att_post
          op_ovi_att_post
          op_attempt_post
          ip_nvi_att_post
          ip_lvi_att_post
          ip_ovi_att_post
          ip_attempt_post
          any_nvi_att_post
          any_lvi_att_post
          any_ovi_att_post
          any_attempt_post
          lvi_sui_dth_flag
          ovi_sui_dth_flag
          nvi_sui_dth_flag
          any_sui_dth_flag
        ;
        classlev
          visit_year
          visit_type
          age
          sex
          race1
          race2
          hispanic
          hhld_inc_lt25k
          hhld_inc_lt40k
          coll_deg_lt25p
          enr_index
          ins_medicaid
          ins_commercial
          ins_privatepay
          ins_statesubsidized
          ins_selffunded
          ins_medicare
          ins_other
          ins_highdeductible
          charlson_score
          charlson_mi
          charlson_chd
          charlson_pvd
          charlson_cvd
          charlson_dem
          charlson_cpd
          charlson_rhd
          charlson_pud
          charlson_mlivd
          charlson_diab
          charlson_diabc
          charlson_plegia
          charlson_ren
          charlson_malign
          charlson_slivd
          charlson_mst
          charlson_aids
          dep_dx_index
          dep_dx_pre1y
          dep_dx_pre5y
          anx_dx_index
          anx_dx_pre1y
          anx_dx_pre5y
          bip_dx_index
          bip_dx_pre1y
          bip_dx_pre5y
          sch_dx_index
          sch_dx_pre1y
          sch_dx_pre5y
          oth_dx_index
          oth_dx_pre1y
          oth_dx_pre5y
          dem_dx_index
          dem_dx_pre1y
          dem_dx_pre5y
          add_dx_index
          add_dx_pre1y
          add_dx_pre5y
          asd_dx_index
          asd_dx_pre1y
          asd_dx_pre5y
          per_dx_index
          per_dx_pre1y
          per_dx_pre5y
          alc_dx_index
          alc_dx_pre1y
          alc_dx_pre5y
          dru_dx_index
          dru_dx_pre1y
          dru_dx_pre5y
          pts_dx_index
          pts_dx_pre1y
          pts_dx_pre5y
          eat_dx_index
          eat_dx_pre1y
          eat_dx_pre5y
          tbi_dx_index
          tbi_dx_pre1y
          tbi_dx_pre5y
          del_post_1_90
          del_post_91_180
          del_post_181_280
          del_pre_1_90
          del_pre_91_180
          del_pre_181_365
          antidep_rx_pre3m
          antidep_rx_pre1y
          antidep_rx_pre5y
          benzo_rx_pre3m
          benzo_rx_pre1y
          benzo_rx_pre5y
          hypno_rx_pre3m
          hypno_rx_pre1y
          hypno_rx_pre5y
          sga_rx_pre3m
          sga_rx_pre1y
          sga_rx_pre5y
          mh_ip_pre3m
          mh_ip_pre1y
          mh_ip_pre5y
          mh_op_pre3m
          mh_op_pre1y
          mh_op_pre5y
          mh_ed_pre3m
          mh_ed_pre1y
          mh_ed_pre5y
          any_sui_att_pre3m
          any_sui_att_pre1y
          any_sui_att_pre5y
          lvi_sui_att_pre3m
          lvi_sui_att_pre1y
          lvi_sui_att_pre5y
          ovi_sui_att_pre3m
          ovi_sui_att_pre1y
          ovi_sui_att_pre5y
          any_inj_poi_pre3m
          any_inj_poi_pre1y
          any_inj_poi_pre5y
          phq_index_items
          item9_index_avail
          item1_index_score
          item2_index_score
          item3_index_score
          item4_index_score
          item5_index_score
          item6_index_score
          item7_index_score
          item8_index_score
          item9_index_score
          phq9_index_score
          phq8_index_score
          item9_pre_score1
          item9_pre_score2
          item9_pre_score3
          op_nvi_att_post
          op_lvi_att_post
          op_ovi_att_post
          op_attempt_post
          ip_nvi_att_post
          ip_lvi_att_post
          ip_ovi_att_post
          ip_attempt_post
          any_nvi_att_post
          any_lvi_att_post
          any_ovi_att_post
          any_attempt_post
          lvi_sui_dth_flag
          ovi_sui_dth_flag
          nvi_sui_dth_flag
          any_sui_dth_flag
          / style=data[indent=2]
        ;
        format age age. charlson_score charlson.;
        table 
          all='Total'
          visit_type
          age
          sex
          race1
          race2
          hispanic
          hhld_inc_lt25k
          hhld_inc_lt40k
          coll_deg_lt25p
          enr_index
          ins_medicaid
          ins_commercial
          ins_privatepay
          ins_statesubsidized
          ins_selffunded
          ins_medicare
          ins_other
          ins_highdeductible
          charlson_score
          charlson_mi
          charlson_chd
          charlson_pvd
          charlson_cvd
          charlson_dem
          charlson_cpd
          charlson_rhd
          charlson_pud
          charlson_mlivd
          charlson_diab
          charlson_diabc
          charlson_plegia
          charlson_ren
          charlson_malign
          charlson_slivd
          charlson_mst
          charlson_aids
          dep_dx_index
          dep_dx_pre1y
          dep_dx_pre5y
          anx_dx_index
          anx_dx_pre1y
          anx_dx_pre5y
          bip_dx_index
          bip_dx_pre1y
          bip_dx_pre5y
          sch_dx_index
          sch_dx_pre1y
          sch_dx_pre5y
          oth_dx_index
          oth_dx_pre1y
          oth_dx_pre5y
          dem_dx_index
          dem_dx_pre1y
          dem_dx_pre5y
          add_dx_index
          add_dx_pre1y
          add_dx_pre5y
          asd_dx_index
          asd_dx_pre1y
          asd_dx_pre5y
          per_dx_index
          per_dx_pre1y
          per_dx_pre5y
          alc_dx_index
          alc_dx_pre1y
          alc_dx_pre5y
          dru_dx_index
          dru_dx_pre1y
          dru_dx_pre5y
          pts_dx_index
          pts_dx_pre1y
          pts_dx_pre5y
          eat_dx_index
          eat_dx_pre1y
          eat_dx_pre5y
          tbi_dx_index
          tbi_dx_pre1y
          tbi_dx_pre5y
          del_post_1_90
          del_post_91_180
          del_post_181_280
          del_pre_1_90
          del_pre_91_180
          del_pre_181_365
          antidep_rx_pre3m
          antidep_rx_pre1y
          antidep_rx_pre5y
          benzo_rx_pre3m
          benzo_rx_pre1y
          benzo_rx_pre5y
          hypno_rx_pre3m
          hypno_rx_pre1y
          hypno_rx_pre5y
          sga_rx_pre3m
          sga_rx_pre1y
          sga_rx_pre5y
          mh_ip_pre3m
          mh_ip_pre1y
          mh_ip_pre5y
          mh_op_pre3m
          mh_op_pre1y
          mh_op_pre5y
          mh_ed_pre3m
          mh_ed_pre1y
          mh_ed_pre5y
          any_sui_att_pre3m
          any_sui_att_pre1y
          any_sui_att_pre5y
          lvi_sui_att_pre3m
          lvi_sui_att_pre1y
          lvi_sui_att_pre5y
          ovi_sui_att_pre3m
          ovi_sui_att_pre1y
          ovi_sui_att_pre5y
          any_inj_poi_pre3m
          any_inj_poi_pre1y
          any_inj_poi_pre5y
          phq_index_items
          item9_index_avail
          item1_index_score
          item2_index_score
          item3_index_score
          item4_index_score
          item5_index_score
          item6_index_score
          item7_index_score
          item8_index_score
          item9_index_score
          phq9_index_score
          phq8_index_score
          item9_pre_score1
          item9_pre_score2
          item9_pre_score3
          op_nvi_att_post
          op_lvi_att_post
          op_ovi_att_post
          op_attempt_post
          ip_nvi_att_post
          ip_lvi_att_post
          ip_ovi_att_post
          ip_attempt_post
          any_nvi_att_post
          any_lvi_att_post
          any_ovi_att_post
          any_attempt_post
          lvi_sui_dth_flag
          ovi_sui_dth_flag
          nvi_sui_dth_flag
          any_sui_dth_flag
          , (all='Total' visit_year='Year of index visit')
          * ( n='N'*[s=[tagattr='format:#,##0']]
              colpctn='%'*[s=[tagattr='format:0.0']]  )
          / misstext='0'
        ;
        footnote "Prepared %sysfunc(today(), mmddyys10.)";
      run;

      ods tagsets.ExcelXP
        options(
          absolute_column_width='6'
          autofit_height='no'
          embedded_footnotes='yes'
          embedded_titles='yes'
          frozen_headers='5'
          frozen_rowheaders='1'
          merge_titles_footnotes='yes'
          orientation='landscape'
          pages_fitwidth='100'
          pages_fitheight='1'
          sheet_interval='none'
          sheet_name="CONTINUOUS"
        )
      ;

      proc tabulate data=SHARE.SRPM_ANALYTIC_SITE&_SITECODE missing;
        title "SRPM_ANALYTIC_SITE&_SITECODE: Continuous Variable Summary";
        class visit_year;
        var visit_seq
          days_since_visit1
          enr_pre_days
          censor_att_days
          censor_dth_days
          item9_pre_days1
          item9_pre_days2
          item9_pre_days3
          op_nvi_att_days
          op_lvi_att_days
          op_ovi_att_days
          op_attempt_days
          ip_nvi_att_days
          ip_lvi_att_days
          ip_ovi_att_days
          ip_attempt_days
          any_nvi_att_days
          any_lvi_att_days
          any_ovi_att_days
          any_attempt_days
          lvi_sui_dth_days
          ovi_sui_dth_days
          nvi_sui_dth_days
          any_sui_dth_days
        ;
        table visit_seq
          days_since_visit1
          enr_pre_days
          censor_att_days
          censor_dth_days
          item9_pre_days1
          item9_pre_days2
          item9_pre_days3
          op_nvi_att_days
          op_lvi_att_days
          op_ovi_att_days
          op_attempt_days
          ip_nvi_att_days
          ip_lvi_att_days
          ip_ovi_att_days
          ip_attempt_days
          any_nvi_att_days
          any_lvi_att_days
          any_ovi_att_days
          any_attempt_days
          lvi_sui_dth_days
          ovi_sui_dth_days
          nvi_sui_dth_days
          any_sui_dth_days
          , (all='Total' visit_year='Year of index visit')
          * ( n='Non-missing'
              nmiss='Missing'
              mean='Mean'
              std='SD'
              min='Min'
              p25='25th Pctl'
              p50='Median'
              p75='75th Pctl'
              max='Max'
            )
          * [s=[tagattr='format:#,##0']]
        ;
        footnote "Prepared %sysfunc(today(), mmddyys10.)";
      run;

      ods tagsets.ExcelXP close;

      options nomprint;
    %end;
%mend summary;

%summary

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
