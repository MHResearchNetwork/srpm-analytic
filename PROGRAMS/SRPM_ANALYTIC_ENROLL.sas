*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_ENROLL.SAS                                        *;
*   Purpose:  Prepare enrollment-related variables for each person-date.      *;
*******************************************************************************;
options nomprint;

%macro enr_subset;
  %if %sysfunc(exist(temp.enr_subset)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "ENR_SUBSET"
      ;
    quit;

    %put WARNING: Data set TEMP.ENR_SUBSET already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.people)) = 0 %then %do;
      %put ERROR: Data set TEMP.ENR_SUBSET cannot be created!;
      %put ERROR: Required input data set TEMP.PEOPLE does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql;
        create table temp.enr_subset as
        select e.*
        from temp.people as p
          inner join &_vdw_enroll as e
            on p.mrn = e.mrn
        ;
      quit;

      options nomprint;
    %end;
%mend enr_subset;

%enr_subset

%macro enr_index;
  %if %sysfunc(exist(temp.enr_index)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "ENR_INDEX"
      ;
    quit;

    %put WARNING: Data set TEMP.ENR_INDEX already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.ENR_INDEX cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.enr_subset)) = 0 %then %do;
      %put ERROR: Data set TEMP.ENR_INDEX cannot be created!;
      %put ERROR: Required input data set TEMP.ENR_SUBSET does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql;
        create table temp.enr_index as
        select p.mrn
          , p.visit_date
          , case when e.mrn is null then 0 else 1 end as enr_index length=3
          , e.ins_medicaid
          , e.ins_commercial
          , e.ins_privatepay
          , e.ins_statesubsidized
          , e.ins_selffunded
          , e.ins_highdeductible
          , e.ins_medicare
          , e.ins_other
        from temp.person_dates as p
          left join temp.enr_subset as e
            on p.mrn = e.mrn
            and e.enr_start <= p.visit_date <= e.enr_end
        order mrn
          , visit_date
        ;
      quit;

      options nomprint;
    %end;
%mend enr_index;

%enr_index

%macro enr_pre;
  %if %sysfunc(exist(temp.enr_pre)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "ENR_PRE"
      ;
    quit;

    %put WARNING: Data set TEMP.ENR_PRE already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.ENR_PRE cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.enr_subset)) = 0 %then %do;
      %put ERROR: Data set TEMP.ENR_PRE cannot be created!;
      %put ERROR: Required input data set TEMP.ENR_SUBSET does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql;
        create table pre_enr1 as
        select p.mrn
          , p.visit_date
          , e.enr_start
          , e.enr_end
        from temp.person_dates as p
          inner join temp.enr_subset as e
            on p.mrn = e.mrn
        where intnx('day', intnx('month', p.visit_date, -60, 's'), -62, 's')
              <= e.enr_end
          and intnx('day', p.visit_date, 62, 's') >= e.enr_start
        order by mrn
          , visit_date
          , enr_start
          , enr_end
        ;
      quit;

      data pre_enr2;
        retain period_start period_end;
        length period_start period_end 4;
        format period_start period_end mmddyys10.;
        set pre_enr1;
        by mrn visit_date;
        * Initialize start of a new enrollment period. *;
        if first.visit_date then do;
          period_start = enr_start;
          period_end = enr_end;
        end;
        * Check contiguosity: If record start date falls within or abuts the  *;
        * current period (plus tolerance), extend the current period out to   *;
        * the end date for this record. Otherwise this is new period, so      *;
        * output the last record & re-initialize.                             *;
        if period_start <= enr_start <= (period_end + (62 + 1)) then do;
          period_end = max(enr_end, period_end);
        end;
          else do;
            output;
            period_start = enr_start;
            period_end = enr_end;   
          end;
        * If this is the last record for the BY list, then a new period is    *;
        * about to start--so output the last record for the BY group.         *;
        if last.visit_date then do;
          output;
        end;
      run;

      * Delete records where end of enrollment period was more than 62 days   *;
      * prior to visit date. (This takes care of older, non-contiguous        *;
      * periods as well as instances when the person was not enrolled at      *;
      * index and end of prior enrollment period was outside tolerance gap.)  *;
      * Also delete records where start of enrollment is after the visit.     *;
      data pre_enr3;
        set pre_enr2 (drop=enr_start enr_end);
        enr_start = period_start;
        enr_end = period_end;
        drop period_start period_end;
        if visit_date - enr_end > 62 or visit_date < enr_start then delete;
      run;

      * Start of continuous enrollment is now the first enr_start per visit.  *;
      data pre_enr4;
        set pre_enr3;
        by mrn visit_date enr_start;
        if first.visit_date;
      run;

      proc sql;
        create table temp.enr_pre as
        select pd.mrn
          , pd.visit_date    
          , max(intnx('month', pd.visit_date, -60, 's'), pe.enr_start)
            as enr_pre_start
        from temp.person_dates as pd
          inner join pre_enr4 as pe
            on pd.mrn = pe.mrn
            and pd.visit_date = pe.visit_date
        order by mrn
          , visit_date
        ;
      quit;

      proc datasets lib=work;
        delete pre_enr:;
      quit;

      options nomprint;
    %end;
%mend enr_pre;

%enr_pre

%macro enr_post;
  %if %sysfunc(exist(temp.enr_post)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "ENR_POST"
      ;
    quit;

    %put WARNING: Data set TEMP.ENR_POST already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.person_dates)) = 0 %then %do;
      %put ERROR: Data set TEMP.ENR_POST cannot be created!;
      %put ERROR: Required input data set TEMP.PERSON_DATES does not exist.;
    %end;
    %else %if %sysfunc(exist(temp.enr_subset)) = 0 %then %do;
      %put ERROR: Data set TEMP.ENR_POST cannot be created!;
      %put ERROR: Required input data set TEMP.ENR_SUBSET does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql;
        create table post_enr1 as
        select p.mrn
          , p.visit_date format=date9.
          , e.enr_start
          , e.enr_end
        from temp.person_dates as p
          inner join temp.enr_subset as e
            on p.mrn = e.mrn
        where intnx('day', p.visit_date, -62, 's') <= e.enr_end
          and intnx('day', '30SEP2015'd, 62, 's') >= e.enr_start
        order by mrn
          , visit_date
          , enr_start
          , enr_end
        ;
      quit;

      data post_enr2;
        retain period_start period_end;
        length period_start period_end 4;
        format period_start period_end mmddyys10.;
        set post_enr1;
        by mrn visit_date;
        * Initialize start of a new enrollment period. *;
        if first.visit_date then do;
          period_start = enr_start;
          period_end = enr_end;
        end;
        * Check contiguosity: If record start date falls within or abuts the  *;
        * current period (plus tolerance), extend the current period out to   *;
        * the end date for this record. Otherwise this is new period, so      *;
        * output the last record & re-initialize.                             *;
        if period_start <= enr_start <= (period_end + (62 + 1)) then do;
          period_end = max(enr_end, period_end);
        end;
          else do;
            output;
            period_start = enr_start;
            period_end = enr_end;   
          end;
        * If this is the last record for the BY list, then a new period is    *;
        * about to start--so output the last record for the BY group.         *;
        if last.visit_date then do;
          output;
        end;
      run;

      * Delete records where start of enrollment period was more than 62 days *;
      * after the visit date. (This takes care of more recent non-contiguous  *;
      * periods as well as instances when the person was not enrolled at      *;
      * index and start of continuous enrollment was outside tolerance gap.)  *;
      * Also delete records where end of enrollment is before visit date.     *;
      data post_enr3;
        set post_enr2 (drop=enr_start enr_end);
        enr_start = period_start;
        enr_end = period_end;
        drop period_start period_end;
        if enr_start - visit_date > 62 or visit_date > enr_end then delete;
      run;

      * Start of continuous enrollment is now the last enr_start per visit.  *;
      data post_enr4;
        set post_enr3;
        by mrn visit_date enr_start;
        if last.visit_date;
      run;

      proc sql;
        create table temp.enr_post as
        select pd.mrn
          , pd.visit_date    
          , min('30SEP2015'd, pe.enr_end) as enr_post_end
        from temp.person_dates as pd
          inner join post_enr4 as pe
            on pd.mrn = pe.mrn
            and pd.visit_date = pe.visit_date
        order by mrn
          , visit_date
        ;
      quit;

      proc datasets lib=work;
        delete post_enr:;
      quit;

      options nomprint;
    %end;
%mend enr_post;

%enr_post

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
