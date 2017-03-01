*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_ITEM9_INDEX.SAS                                   *;
*   Purpose:  Identify best PHQ item #9 scores for index visit.               *;
*******************************************************************************;
options nomprint;

%macro item9_index;
  %if %sysfunc(exist(temp.item9_index)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "ITEM9_INDEX"
      ;
    quit;

    %put WARNING: Data set TEMP.ITEM9_INDEX already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(cesrpro.phq9_cesr_pro)) = 0 %then %do;
      %put ERROR: Data set TEMP.ITEM9_INDEX cannot be created!;
      %put ERROR: Required input data set CESRPRO.PHQ9_CESR_PRO does not exist.;
    %end;
    %else %if %sysfunc(exist(denom.srpm_denom_full_&_siteabbr)) = 0
      %then %do
    ;
      %put ERROR: Data set TEMP.ITEM9_INDEX cannot be created!;
      %put ERROR: Required input data set DENOM.SRPM_DENOM_FULL_&_SITEABBR does not exist.;
    %end;
    %else %do;
      options mprint;

      *------------------------------------------------------------------------;
      * Obtain valid PHQ item #9 responses between start date and 06/30/2015.  ; 
      *------------------------------------------------------------------------;
      data phq_item9;
          set cesrpro.phq9_cesr_pro;
          where response_date between "&startdate"d and "30JUN2015"d
            and question_id in (&item9_ids)
            and strip(response_text) in ('0', '1', '2', '3')
          ;
        MRN_DATE = catx('_', mrn, put(response_date, yymmddn8.));
        keep QUESTION_ID MRN RESPONSE_DATE RESPONSE_TIME RESPONSE_TEXT ENC_ID
          PROVIDER PAT_ENC_CSN_ID MRN_DATE
        ;
      run;

      *------------------------------------------------------------------------;
      * Create crosswalk of VDW encounters to Clarity PECIs (if available).    ;
      *------------------------------------------------------------------------;
      proc sql;
        create table enc_peci_raw as
        select distinct enc_id
          , enc_peci as pat_enc_csn_id  
          , catx('_', mrn, put(adate, yymmddn8.)) as mrn_date
          , adate
          , provider
        from denom.srpm_denom_full_&_siteabbr
        where enc_peci ^= .
        union
        select distinct enc_id
          , px_peci as pat_enc_csn_id  
          , catx('_', mrn, put(adate, yymmddn8.)) as mrn_date
          , adate
          , provider
        from denom.srpm_denom_full_&_siteabbr
        where px_peci ^= .
        union
        select distinct enc_id
          , dx_peci as pat_enc_csn_id  
          , catx('_', mrn, put(adate, yymmddn8.)) as mrn_date
          , adate
          , provider
        from denom.srpm_denom_full_&_siteabbr
        where dx_peci ^= .
        union
        select distinct enc_id
          , . as pat_enc_csn_id  
          , catx('_', mrn, put(adate, yymmddn8.)) as mrn_date
          , adate
          , provider
        from denom.srpm_denom_full_&_siteabbr
        where enc_peci = dx_peci = px_peci = .
        order by enc_id
          , pat_enc_csn_id
          , mrn_date
        ;

        create table enc_peci_dedup as
        select distinct enc_id
          , pat_enc_csn_id
          , mrn_date
          , adate
          , provider
        from enc_peci_raw
        order by enc_id
          , pat_enc_csn_id
        ;

        create table enc_per_day as
        select mrn_date
          , count(distinct enc_id) as daily_enc_count
        from enc_peci_dedup
        group by mrn_date
        ;

        create table enc_peci_master as
        select a.*
          , b.daily_enc_count
        from enc_peci_dedup as a
          inner join enc_per_day as b
            on a.mrn_date = b.mrn_date
        ;
      quit;

      %dsdelete(enc_peci_raw|enc_per_day|enc_peci_dedup)

      *------------------------------------------------------------------------;
      * Match 1. For standalone VDW encounters (i.e., single qualifying visit  ;
      * per date) that match to item #9 on VDW ENC_ID, keep the item #9 score  ;
      * with latest date/time stamp per VDW encounter.                         ;
      *------------------------------------------------------------------------;
      proc sql;
        create table match1_all as
        select distinct e.enc_id
          , e.mrn_date
          , e.provider
          , e.daily_enc_count
          , p.response_text
          , p.response_date
          , p.response_time
          , case
              when e.enc_id = p.enc_id 
                and missing(e.enc_id) = missing(p.enc_id) = 0
                then 1
              else 0
            end as match1 length=3
        from enc_peci_master as e
          left join phq_item9 as p
            on e.enc_id = p.enc_id
            and missing(e.enc_id) = missing(p.enc_id) = 0
        where e.daily_enc_count = 1
        order by enc_id
          , response_date
          , response_time
        ;
      quit;

      data match1_dedup;
        set match1_all;
        by enc_id response_date response_time;
        if last.enc_id;
      run;

      *------------------------------------------------------------------------;
      * Match 2. For remaining standalone VDW encounters (i.e., single         ;
      * qualifying visit per date) that match to item #9 on Epic/Clarity PECI, ;
      * keep available item #9 score with latest datetime stamp per encounter. ;
      *------------------------------------------------------------------------;
      proc sql;
        create table match2_all as
        select distinct m.enc_id
          , m.mrn_date
          , m.provider
          , m.daily_enc_count
          , p.response_text
          , p.response_date
          , p.response_time
          , case
              when e.pat_enc_csn_id = p.pat_enc_csn_id
                and missing(e.pat_enc_csn_id) = missing(p.pat_enc_csn_id) = 0
                then 1
              else 0
            end as match2 length=3
        from match1_dedup as m
          inner join enc_peci_master as e
            on m.enc_id = e.enc_id
          left join phq_item9 as p
            on e.pat_enc_csn_id = p.pat_enc_csn_id
            and missing(e.pat_enc_csn_id) = missing(p.pat_enc_csn_id) = 0
        where m.match1 = 0
        order by enc_id
          , response_date
          , response_time
        ;
      quit;

      data match2_dedup;
        set match2_all;
        by enc_id response_date response_time;
        if last.enc_id;
      run;

      *------------------------------------------------------------------------;
      * Match 3. For remaining standalone VDW encounters (i.e., single         ;
      * qualifying visit per date) that match to item #9 on MRN+Date+Provider, ;
      * keep available item #9 score with latest datetime stamp per encounter. ;
      *------------------------------------------------------------------------;
      proc sql;
        create table match3_all as
        select distinct m.enc_id
          , m.mrn_date
          , m.provider
          , m.daily_enc_count
          , p.response_text
          , p.response_date
          , p.response_time
          , case
              when e.mrn_date = p.mrn_date
                and e.provider = p.provider
                and missing(e.provider) = missing(p.provider) = 0
                then 1
              else 0
            end as match3 length=3
        from match2_dedup as m
          inner join enc_peci_master as e
            on m.enc_id = e.enc_id
          left join phq_item9 as p
            on e.mrn_date = p.mrn_date
            and e.provider = p.provider
            and missing(e.provider) = missing(p.provider) = 0
        where m.match2 = 0
        order by enc_id
          , response_date
          , response_time
        ;
      quit;

      data match3_dedup;
        set match3_all;
        by enc_id response_date response_time;
        if last.enc_id;
      run;

      *------------------------------------------------------------------------;
      * Match 4. For remaining standalone VDW encounters (i.e., single         ;
      * qualifying visit per date) that match to item #9 on MRN+Date, keep     ;
      * available item #9 score with latest datetime stamp per encounter.      ;
      *------------------------------------------------------------------------;
      proc sql;
        create table match4_all as
        select distinct m.enc_id
          , m.mrn_date
          , m.provider
          , m.daily_enc_count
          , p.response_text
          , p.response_date
          , p.response_time
          , case
              when e.mrn_date = p.mrn_date then 1
              else 0
            end as match4 length=3
        from match3_dedup as m
          inner join enc_peci_master as e
            on m.enc_id = e.enc_id
          left join phq_item9 as p
            on e.mrn_date = p.mrn_date
        where m.match3 = 0
        order by enc_id
          , response_date
          , response_time
        ;
      quit;

      data match4_dedup;
        set match4_all;
        by enc_id response_date response_time;
        if last.enc_id;
      run;

      *------------------------------------------------------------------------;
      * Match 5. For VDW encounters that occur on the same day as other        ;
      * qualifyig VDW encounters, match to PHQ item #9 on VDW ENC_ID where     ;
      * possible. In case of duplicates, keep available item #9 score with     ;
      * latest datetime stamp per VDW encounter.                               ;
      *------------------------------------------------------------------------;
      proc sql;
        create table match5_all as
        select distinct e.enc_id
          , e.mrn_date
          , e.provider
          , e.daily_enc_count
          , p.response_text
          , p.response_date
          , p.response_time
          , case
              when e.enc_id = p.enc_id 
                and missing(e.enc_id) = missing(p.enc_id) = 0 
                then 1
              else 0
            end as match5 length=3
        from enc_peci_master as e
          left join phq_item9 as p
            on e.enc_id = p.enc_id
            and missing(e.enc_id) = missing(p.enc_id) = 0
        where e.daily_enc_count > 1
        order by enc_id
          , response_date
          , response_time
        ;
      quit;

      data match5_dedup;
        set match5_all;
        by enc_id response_date response_time;
        if last.enc_id;
      run;

      *------------------------------------------------------------------------;
      * Match 6. For remaining VDW encounters that occur on the same day as    ;
      * other qualifying VDW encounters, match to PHQ item #9 on Epic/Clarity  ;
      * PECI where available. In case of duplicates, keep the most recently    ;
      * entered item #9 score per VDW encounter.                               ;
      *------------------------------------------------------------------------;
      proc sql;
        create table match6_all as
        select distinct m.enc_id
          , m.mrn_date
          , e.provider
          , m.daily_enc_count
          , p.response_text
          , p.response_date
          , p.response_time
          , case
              when e.pat_enc_csn_id = p.pat_enc_csn_id
                and missing(e.pat_enc_csn_id) = missing(p.pat_enc_csn_id) = 0
                then 1
              else 0
            end as match6 length=3
        from match5_dedup as m
          inner join enc_peci_master as e
            on m.enc_id = e.enc_id
          left join phq_item9 as p
            on e.pat_enc_csn_id = p.pat_enc_csn_id
            and missing(e.pat_enc_csn_id) = missing(p.pat_enc_csn_id) = 0
        where m.match5 = 0
        order by enc_id
          , response_date
          , response_time
        ;
      quit;

      data match6_dedup;
        set match6_all;
        by enc_id response_date response_time;
        if last.enc_id;
      run;

      *------------------------------------------------------------------------;
      * Match 7. For remaining VDW encounters that occur on the same day as    ; 
      * other qualifying VDW encounters, match to PHQ item #9 on MRN+Date+Pro- ;
      * vider where available. In case of duplicates, keep the most recently   ;
      * entered item #9 score per VDW encounter.                               ;
      *------------------------------------------------------------------------;
      proc sql;
        create table match7_all as
        select distinct m.enc_id
          , m.mrn_date
          , e.provider
          , m.daily_enc_count
          , p.response_text
          , p.response_date
          , p.response_time
          , case
              when e.mrn_date = p.mrn_date
                and e.provider = p.provider
                and missing(e.provider) = missing(p.provider) = 0
                then 1
              else 0
            end as match7 length=3
        from match6_dedup as m
          inner join enc_peci_master as e
            on m.enc_id = e.enc_id
          left join phq_item9 as p
            on e.mrn_date = p.mrn_date
            and e.provider = p.provider
            and missing(e.provider) = missing(p.provider) = 0
        where m.match6 = 0
        order by enc_id
          , response_date
          , response_time
        ;
      quit;

      data match7_dedup;
        set match7_all;
        by enc_id response_date response_time;
        if last.enc_id;
      run;

      *------------------------------------------------------------------------;
      * Match 8. For remaining VDW encounters that occur on the same day as    ;
      * other qualifying VDW encounters, see how many unique item #9 scores    ;
      * are available when matching on just MRN + Date. If only one item #9    ;
      * score is available, match it to all qualifying visits from the date.   ;
      * If multiple item #9 scores are available, do not match any of them, as ;
      * we cannot determine which visit each score belongs to.                 ;
      *------------------------------------------------------------------------;
      proc sql;
        create table match8_all as
        select distinct m.enc_id
          , m.mrn_date
          , m.provider
          , m.daily_enc_count
          , p.response_text
          , p.response_date
          , p.response_time
          , case 
              when e.mrn_date = p.mrn_date then 1 
              else 0 
            end as match8 length=3
        from match7_dedup as m
          inner join enc_peci_master as e
            on m.enc_id = e.enc_id
          left join phq_item9 as p
            on e.mrn_date = p.mrn_date
        where m.match7 = 0
        order by enc_id
          , response_date
          , response_time
        ;

        create table match8_item9 as
        select mrn_date
          , match8
          , count(distinct response_text) as unique_item9
        from match8_all
        group by mrn_date
          , match8
        ;

        create table match8_flag_dup as
        select a.*
          , i.unique_item9
        from match8_all as a
          inner join match8_item9 as i
            on a.mrn_date = i.mrn_date
        order by enc_id
          , response_date
          , response_time
        ;
      quit;

      data match8_dedup;
        set match8_flag_dup;
        by enc_id response_date response_time;
        match8 = unique_item9;
        if last.enc_id;
      run;

      data temp.item9_index;
        set match1_dedup (in=a where=(match1 = 1))
          match2_dedup (in=b where=(match2 = 1))
          match3_dedup (in=c where=(match3 = 1))
          match4_dedup (in=d)
          match5_dedup (in=e where=(match5 = 1))
          match6_dedup (in=f where=(match6 = 1))
          match7_dedup (in=g where=(match7 = 1))
          match8_dedup (in=h)
        ;
        length item9_index_match $ 20;
        if a then item9_index_match = '1 VDW Enc ID';
          else if b then item9_index_match = '2 Epic Enc ID';
          else if c then item9_index_match = '3 MRN+Date+Provider';
          else if d then do;
            if match4 = 1 then item9_index_match = '4 MRN+Date (Good)';
              else item9_index_match = 'X No Match';
          end;
          else if e then item9_index_match = '5 VDW Enc ID';
          else if f then item9_index_match = '6 Epic Enc ID';
          else if g then item9_index_match = '7 MRN+Date+Provider';
          else if h then do;
            if match8 = 1 then item9_index_match = '8 MRN+Date (Good)';
              else if match8 > 1 then item9_index_match = '9 MRN+Date (Bad)';
              else item9_index_match = 'X No Match';
          end;
        * Clear matches that are too "fuzzy." *;
        if item9_index_match =: '9' then do;
          response_date = .;
          response_time = .;
          response_text = '';
        end;
        item9_index_score = input(substr(response_text, 1, 1), 1.);
        length item9_index_avail 3;
        if item9_index_score ne . then item9_index_avail = 1;
          else item9_index_avail = 0;
        keep enc_id item9_index_avail item9_index_score item9_index_match;
      run;

      proc datasets lib=work;
        delete phq_item9 match: enc_peci_master;
      quit;

      options nomprint;
    %end;
%mend item9_index;

%item9_index

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
