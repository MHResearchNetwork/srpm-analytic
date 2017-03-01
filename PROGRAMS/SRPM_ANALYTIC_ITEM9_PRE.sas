*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_ITEM9_PRE.SAS                                     *;
*   Purpose:  Obtain up to 3 PHQ #9 scores/dates prior to index visit.        *;
*******************************************************************************;
options nomprint;

%macro item9_pre;
  %if %sysfunc(exist(temp.item9_pre)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "ITEM9_PRE"
      ;
    quit;

    %put WARNING: Data set TEMP.ITEM9_PRE already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(cesrpro.phq9_cesr_pro)) = 0 %then %do;
      %put ERROR: Data set TEMP.ITEM9_PRE cannot be created!;
      %put ERROR: Required input data set CESRPRO.PHQ9_CESR_PRO does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.ITEM9_PRE cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %do;
      options mprint;

      data all_prev_item9;
        set cesrpro.phq9_cesr_pro;
        where response_date between "01JAN2004"d and "30JUN2015"d
          and question_id in (&item9_ids)
          and strip(response_text) in ('0', '1', '2', '3')
        ;
        item9_score = input(substr(response_text, 1, 1), 1.);
        keep mrn response_date response_time item9_score;
      run;

      proc sort data=all_prev_item9 out=sort_prev_item9;
        by mrn response_date descending response_time descending item9_score;
      run;

      data dedup_prev_item9;
        set sort_prev_item9;
        by mrn response_date descending response_time descending item9_score;
        if first.response_date;
        rename response_date = item9_date;
      run;

      proc sql;
        create table add_prev_item9 as
        select p.mrn
          , p.visit_date
          , d.item9_date
          , d.item9_score
        from temp.person_dates as p
          inner join dedup_prev_item9 as d
            on p.mrn = d.mrn
        where d.item9_date < p.visit_date
          and d.item9_date ne .
        order by mrn
          , visit_date
          , item9_date desc
        ;
      quit;

      data cull_prev_item9;
        set add_prev_item9;
        by mrn visit_date descending item9_date;
        item9_pre_days = visit_date - item9_date;
        rename item9_score=item9_pre_score;
        if first.visit_date then item9_count = 0;
        item9_count + 1;
        * Keep up to 3 prior item #9 scores/dates. *;
        if item9_count > 3 then delete;
      run;
 
      proc transpose data=cull_prev_item9 out=tran_prev_item9a (drop=_name_)
        prefix=item9_pre_score
      ;
        by mrn visit_date;
        var item9_pre_score;
        id item9_count;
      run;

      proc transpose data=cull_prev_item9 out=tran_prev_item9b (drop=_name_)
        prefix=item9_pre_days
      ;
        by mrn visit_date;
        var item9_pre_days;
        id item9_count;
      run;

      proc sql;
        create table temp.item9_pre as
        select p.mrn
          , p.visit_date
          , a.item9_pre_score1
          , b.item9_pre_days1
          , a.item9_pre_score2
          , b.item9_pre_days2
          , a.item9_pre_score3
          , b.item9_pre_days3
        from temp.person_dates as p
          inner join tran_prev_item9a as a
            on p.mrn = a.mrn and p.visit_date = a.visit_date
          inner join tran_prev_item9b as b
            on p.mrn = b.mrn and p.visit_date = b.visit_date
        ;
      quit;

      %dsdelete(all_prev_item9|sort_prev_item9|dedup_prev_item9|add_prev_item9)
      %dsdelete(cull_prev_item9|tran_prev_item9a|tran_prev_item9b)

      options nomprint;
    %end;
%mend item9_pre;

%item9_pre

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
