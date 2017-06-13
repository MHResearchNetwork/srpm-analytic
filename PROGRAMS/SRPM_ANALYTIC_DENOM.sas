*******************************************************************************;
* PROGRAM DETAILS                                                             *;
*   Filename: SRPM_ANALYTIC_DENOM.SAS                                         *;
*   Purpose:  Prepare temporary visit, person-date, and person denominator    *;
*             data sets for use in creation of final analysis data set.       *;
*******************************************************************************;
* UPDATE HISTORY                                                              *;
*   20170227  Inital GitHub version finalized.                                *;
*   20170613  Corrected error in which DAYS_SINCE_VISIT1 had been constructed *;
*             to calculate days since previous visit. Retained that variable  *;
*             (renamed to DAYS_SINCE_PREV) and used it to calculate actual    *;
*             DAYS_SINCE_VISIT1.                                              *;
*******************************************************************************;

options nomprint;

%macro index_visit;
  %if %sysfunc(exist(temp.index_visit)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "INDEX_VISIT"
      ;
    quit;
    %put WARNING: Data set TEMP.INDEX_VISIT already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(denom.srpm_denom_full_&_siteabbr)) = 0
      %then %do
    ;
      %put ERROR: Data set TEMP.INDEX_VISIT cannot be created!;
      %put ERROR: Required input data set DENOM.SRPM_DENOM_FULL_&_SITEABBR does not exist.;
    %end;
    %else %do;
      options mprint;

      proc summary data=denom.srpm_denom_full_&_siteabbr nway;
        class mrn adate birth_date enc_id department provider;
        var mh_dept mh_spec mh_proc mh_diag;
        output out=denom (drop=_type_ rename=(_freq_=vdw_ute_recs)) max=;
      run;
  
      %let seed = 12345678;

      data temp.index_visit;
        set denom;
        by mrn adate birth_date enc_id department provider;
        visit_date = adate;
        visit_year = year(visit_date);
        retain prev_date random_id;
        length visit_seq days_since_prev days_since_visit1 3;
        array is_assigned [1:99999999] _temporary_ (99999999 * 0);
        if first.mrn then do;
          visit_seq = 0;
          days_since_prev = .;
          days_since_visit1 = .;
          prev_date = .;
          do while (1);
            random_id = ceil(99999999 * ranuni(&seed));
            if is_assigned[random_id] then continue;
            is_assigned[random_id] = 1;
            leave;
          end;
        end;
          else do;
            days_since_prev = visit_date - prev_date;
            days_since_visit1 = days_since_visit1 + days_since_prev;
          end;    
        visit_seq + 1;
        prev_date = adate;
        if sum(mh_dept, mh_spec, mh_proc) = 0 then visit_type = 'PC';
          else visit_type = 'MH';
        age = min(intck('year', birth_date, visit_date, 'c'), 90);
        person_id = cats("&_sitecode", put(random_id, z8.));
        keep mrn visit_date enc_id department provider visit_year visit_seq 
          days_since_prev days_since_visit1 visit_type age person_id
        ;
      run;

      %dsdelete(denom)

      options nomprint;
    %end;
%mend index_visit;

%index_visit

%macro people;
  %if %sysfunc(exist(temp.people)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "PEOPLE"
      ;
    quit;

    %put WARNING: Data set TEMP.PEOPLE already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.index_visit)) = 0 %then %do;
      %put ERROR: Data set TEMP.PEOPLE cannot be created.;
      %put ERROR: Required input data set TEMP.INDEX_VISIT does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql;
        create table temp.people as
        select mrn
          , min(visit_date) as first_visit
          , max(visit_date) as last_visit
        from temp.index_visit
        group by mrn
        order by mrn
        ;
      quit;

      options nomprint;
    %end;
%mend people;

%people

%macro person_dates;
  %if %sysfunc(exist(temp.person_dates)) = 1 %then %do;
    proc sql noprint;
      select modate into :ModifyDT
      from dictionary.tables
      where upcase(libname) = 'TEMP'
        and upcase(memname) = "PERSON_DATES"
      ;
    quit;

    %put WARNING: Data set TEMP.PERSON_DATES already exists.;
    %put WARNING: It was last modified on &ModifyDt.;
    %put WARNING: Please manually delete it if you wish to recreate it.;
  %end;
    %else %if %sysfunc(exist(temp.index_visit)) = 0 %then %do;
      %put ERROR: Data set TEMP.PERSON_DATES cannot be created!;
      %put ERROR: Required input data set TEMP.INDEX_VISIT does not exist.;
    %end;
    %else %do;
      options mprint;

      proc sql;
        create table temp.person_dates as
        select distinct mrn
          , visit_date
        from temp.index_visit
        order by mrn
          , visit_date
        ;
      quit;

      options nomprint;
    %end;
%mend person_dates;

%person_dates

*******************************************************************************;
* END OF PROGRAM                                                              *;
*******************************************************************************;
